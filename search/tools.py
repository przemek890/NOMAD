"""Tools the chat model can call, and the one short system message that tells it what NOMAD has.

The model decides itself whether and what to look up (Ollama tool calling); nothing is added
to the conversation behind its back. Each tool returns plain text, at most RESULT_CHARS.
"""

import json
import os
import urllib.error
import urllib.parse
import urllib.request

import wiki

KIWIX_URL = os.environ.get("KIWIX_URL", "http://nomad-box:8090")
NOTES_URL = os.environ.get("NOTES_URL", "http://nomad-box:8200")
RESULT_CHARS = 4000

SYSTEM = (
    "You are the assistant of NOMAD, an offline knowledge box. It has: an offline Wikipedia, "
    "a knowledge base of guides (medicine, first aid, survival, DIY), the user's notes (one lists all "
    "downloaded content) and offline maps (the Maps app; you cannot read them). Use the tools to look "
    "things up when you are not sure, especially names, dates and numbers, and name the article or "
    "guide you used. If the tools do not have the answer, say so instead of guessing."
)

# After the last search round
ANSWER_NOW = (
    "Answer the user now from the tool results above, without calling tools. If they do not contain "
    "the answer, say that you could not find it."
)
NOT_FOUND = "I could not find the answer in NOMAD's sources."


def _function(name, description, **parameters):
    return {
        "type": "function",
        "function": {
            "name": name,
            "description": description,
            "parameters": {
                "type": "object",
                "properties": {key: {"type": "string", "description": text} for key, text in parameters.items()},
                "required": list(parameters),
            },
        },
    }


DEFINITIONS = [
    _function("search_wikipedia", "Search the offline Wikipedia; returns the best matching passages and article titles.",
              query="article title or keywords in Polish, in the nominative case as in a title "
                    "(Liceum Ogólnokształcące, not Liceum Ogólnokształcącego)"),
    _function("read_article", "Read a Wikipedia article (lead and infobox first).",
              title="article title; the closest article is read when there is none with exactly this title"),
    _function("search_knowledge_base", "Search the guides in the knowledge base (medicine, first aid, survival, DIY).",
              query="what to look for, in English"),
    _function("search_notes", "Search the user's notes; the note 'Downloaded content' lists all downloaded content.",
              query="words to look for"),
]


def _get_json(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def search_wikipedia(query):
    found = wiki.passages(KIWIX_URL, query, [query], limit=5)
    return wiki.context(found) or "Nothing found. Try an article title in the nominative case or other keywords."


def read_article(title):
    name = wiki.book(KIWIX_URL)
    note = ""
    try:
        title, lines = wiki.article(KIWIX_URL, name, title.strip().replace(" ", "_"))
    except urllib.error.HTTPError:
        # Titles sharing the most words with the one asked for (stable: Kiwix's order)
        closest = sorted(wiki.titles(KIWIX_URL, name, title),
                         key=lambda path: -len(wiki.stems(path.replace("_", " ")) & wiki.stems(title)))
        if not closest:
            return f"No article titled {title}. Try search_wikipedia."
        note = f"No article titled exactly {title}; the closest:\n"
        title, lines = wiki.article(KIWIX_URL, name, closest[0])
    return f"{note}[{title}]\n" + "\n".join(lines)


def search_knowledge_base(query, search):
    hits = search(query, 5)
    return "\n".join(f"[{hit['title'] or hit['source']}] {hit['text']}" for hit in hits) or "Nothing found."


def search_notes(query):
    term = urllib.parse.urlencode({"term": query})
    notes = _get_json(f"{NOTES_URL}/api/search?{term}")[:3]
    texts = []
    for note in notes:
        title = note.get("title", "")
        content = _get_json(f"{NOTES_URL}/api/notes/{urllib.parse.quote(title)}").get("content", "")
        texts.append(f"[{title}]\n{content}")
    return "\n\n".join(texts) or "No notes found."


def call(name, arguments, search):
    """Runs a tool for the model; errors go back to the model as text so it can try again."""
    print(f"tool {name} {json.dumps(arguments, ensure_ascii=False)}", flush=True)
    try:
        argument = next(iter(arguments.values()), "") if isinstance(arguments, dict) else str(arguments)
        if name == "search_wikipedia":
            result = search_wikipedia(argument)
        elif name == "read_article":
            result = read_article(argument)
        elif name == "search_knowledge_base":
            result = search_knowledge_base(argument, search)
        elif name == "search_notes":
            result = search_notes(argument)
        else:
            result = f"Unknown tool {name}."
    except Exception as error:  # noqa: BLE001 - any failure is reported to the model, not raised
        result = f"The tool failed: {error}"
    return result[:RESULT_CHARS]
