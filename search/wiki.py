"""Passages from the offline Wikipedia (Kiwix in nomad-box) that answer a question.

Kiwix has a title search (suggest) and a full-text search, no embeddings: the whole
Wikipedia is too big to embed on a small machine, but its own indexes find articles in
well under a second. Articles are cut into passages and the ones sharing the most words
with the question are kept.
"""

import html
import json
import re
import time
import urllib.parse
import urllib.request

ARTICLES = 4
PASSAGE_CHARS = 500
CONTEXT_CHARS = 4000
_book = {"name": None, "checked": 0.0}


def _get(url, timeout=20):
    with urllib.request.urlopen(url, timeout=timeout) as response:
        return response.read().decode("utf-8", "replace")


def book(kiwix):
    """The Wikipedia with the most articles in the library (looked up every 10 minutes)."""
    if time.time() - _book["checked"] > 600:
        catalog = _get(f"{kiwix}/catalog/v2/entries?count=500")
        best = (0, None)
        for entry in re.findall(r"<entry>(.*?)</entry>", catalog, re.S):
            path = re.search(r'href="/content/([^"/]+)"', entry)
            count = re.search(r"<articleCount>(\d+)</articleCount>", entry)
            if path and path.group(1).startswith("wikipedia") and count:
                best = max(best, (int(count.group(1)), path.group(1)))
        _book.update(name=best[1], checked=time.time())
    return _book["name"]


def titles(kiwix, name, query):
    """Article paths for a query: title matches first, then full-text matches."""
    # Title search wants the start of a title: "I Liceum Ogólnokształcące w Tarnowie dyrektor" finds
    # nothing, so drop words from the end until titles match
    words = query.split()
    found = []
    while words and not found:
        term = urllib.parse.urlencode({"content": name, "term": " ".join(words), "count": 5})
        found = [hit["path"] for hit in json.loads(_get(f"{kiwix}/suggest?{term}")) if hit.get("kind") == "path"]
        words = words[:-1] if len(words) > 2 else []
    pattern = urllib.parse.urlencode({"content": name, "pattern": query, "pageLength": 5})
    found += [
        urllib.parse.unquote(path)
        for path in re.findall(rf'href="/content/{re.escape(name)}/([^"#]+)"', _get(f"{kiwix}/search?{pattern}"))
    ]
    return found


def _text(page):
    page = re.sub(r"<(script|style)\b.*?</\1>", " ", page, flags=re.S)
    page = re.sub(r"</(p|tr|li|h\d|div)>", "\n", page)
    return html.unescape(re.sub(r"<[^>]+>", " ", page))


def stems(text):
    """Word beginnings, a crude stemmer that works for Polish and English alike."""
    return {word[:5] for word in re.findall(r"\w{3,}", text.lower())}


def article(kiwix, name, path):
    """(title, lines) of an article; the path is the title with underscores."""
    url = f"{kiwix}/content/{name}/{urllib.parse.quote(path)}"
    page = _get(url)
    title = re.search(r"<title>(.*?)</title>", page, re.S)
    lines = []
    for line in _text(page).split("\n"):
        line = re.sub(r"\s+", " ", line).strip()
        if line and line not in lines:  # the title is on the page three times
            lines.append(line)
    return (html.unescape(title.group(1)).strip() if title else path.replace("_", " ")), lines


def _passages(lines):
    """Lines grouped into passages of about PASSAGE_CHARS."""
    passage = ""
    for line in lines:
        if passage and len(passage) + len(line) > PASSAGE_CHARS:
            yield passage
            passage = ""
        passage = f"{passage} {line}".strip()
    if passage:
        yield passage


def passages(kiwix, question, queries=(), limit=6):
    """The passages closest to the question: [{"title", "text", "score"}], best first.

    queries (e.g. article titles from the chat model) only help to find articles; which
    articles and passages count is decided by the words of the question itself, so a wrong
    guess in a query (an invented name) cannot outweigh it.
    """
    name = book(kiwix)
    if not name:
        return []
    asked = stems(question)
    terms = stems(" ".join(queries))
    paths = []
    for query in [*queries, question]:
        for path in titles(kiwix, name, query):
            if path not in paths:
                paths.append(path)
    # Titles sharing the most words with the question and the queries first (stable: found order)
    paths.sort(key=lambda path: -len(stems(path.replace("_", " ")) & (asked | terms)))
    found = []
    for rank, path in enumerate(paths[:ARTICLES]):
        title, lines = article(kiwix, name, path)
        for index, text in enumerate(_passages(lines)):
            words = stems(text)
            if not words & asked:
                continue
            # The top of an article (lead and infobox) answers most "who/what/where" questions
            score = 2 * len(words & asked) + len(words & terms) + (2 if index == 0 else 0) - rank
            found.append({"title": title, "text": text, "score": score})
    found.sort(key=lambda passage: passage["score"], reverse=True)
    return found[:limit]


def context(found):
    """Passages as text for the chat model, at most CONTEXT_CHARS."""
    text = ""
    for passage in found:
        part = f"[{passage['title']}] {passage['text']}\n"
        if len(text) + len(part) > CONTEXT_CHARS:
            break
        text += part
    return text
