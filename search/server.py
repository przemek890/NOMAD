"""Knowledge base search that works without the chat model.

The question becomes a nomic-embed-text vector on this machine (the embed service,
llama.cpp) and Qdrant returns the fragments NOMAD indexed that are closest to it.
NOMAD indexes with the same model, so the vectors match. Python standard library only.
"""

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

EMBED_URL = os.environ.get("EMBED_URL", "http://embed:8080")
QDRANT_URL = os.environ.get("QDRANT_URL", "http://nomad-box:6333")
PORT = int(os.environ.get("PORT", "8070"))
COLLECTION = "nomad_knowledge_base"
# nomic-embed-text task prefix; NOMAD indexes with "search_document: " and queries like this
QUERY_PREFIX = "search_query: "
MAX_RESULTS = 20
PAGE = (Path(__file__).parent / "index.html").read_bytes()


def post_json(url, body, timeout):
    request = urllib.request.Request(
        url, json.dumps(body).encode(), {"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def embed(text):
    reply = post_json(f"{EMBED_URL}/v1/embeddings", {"input": [QUERY_PREFIX + text]}, 60)
    return reply["data"][0]["embedding"]


def search(question, limit):
    # Extra hits, because a file indexed twice stores the same passage twice
    reply = post_json(
        f"{QDRANT_URL}/collections/{COLLECTION}/points/search",
        {
            "vector": embed(question),
            "limit": limit * 3,
            "with_payload": True,
            # The same filter as NOMAD: fragments of switched-off files stay hidden
            "filter": {"must_not": [{"key": "active", "match": {"value": False}}]},
        },
        30,
    )
    results, seen = [], set()
    for hit in reply["result"]:
        text = hit["payload"].get("text", "")
        if text in seen:
            continue
        seen.add(text)
        results.append(
            {
                "score": round(hit["score"], 3),
                "title": hit["payload"].get("full_title") or hit["payload"].get("article_title") or "",
                "archive": hit["payload"].get("archive_title") or "",
                "source": os.path.basename(hit["payload"].get("source") or ""),
                "text": text,
            }
        )
    return results[:limit]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urllib.parse.urlsplit(self.path)
        if url.path == "/":
            self.reply(200, PAGE, "text/html; charset=utf-8")
        elif url.path == "/api/search":
            self.api_search(urllib.parse.parse_qs(url.query))
        else:
            self.reply(404, b"Not found", "text/plain")

    def api_search(self, query):
        question = query.get("q", [""])[0].strip()
        if not question:
            self.reply_json(400, {"error": "Enter a question"})
            return
        try:
            limit = min(max(int(query.get("limit", ["8"])[0]), 1), MAX_RESULTS)
            self.reply_json(200, {"results": search(question, limit)})
        except ValueError:
            self.reply_json(400, {"error": "limit must be a number"})
        except (urllib.error.URLError, OSError, KeyError) as error:
            self.reply_json(502, {"error": f"Search is not ready yet: {error}"})

    def reply_json(self, status, body):
        self.reply(status, json.dumps(body, ensure_ascii=False).encode(), "application/json")

    def reply(self, status, body, content_type):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("", PORT), Handler).serve_forever()
