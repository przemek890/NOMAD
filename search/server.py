"""Knowledge Search, and tools for NOMAD's AI chat. Python standard library only.

GET  /api/search  passages for a question, without the chat model:
                  - knowledge base: the question becomes a nomic-embed-text vector on this machine
                    (the embed service, llama.cpp, the model NOMAD indexes with) and Qdrant returns
                    the closest passages NOMAD indexed
                  - Wikipedia: title and full-text search of the offline Wikipedia (wiki.py)
POST /api/chat    NOMAD's router sends chat here (box/bin/nomad-llm). A conversation gets the tools
                  of tools.py and one short system message saying what NOMAD has; the model decides
                  itself what to look up, the tool calls are answered here, and its answer streams
                  back to NOMAD as Ollama sends it. Anything else goes to the LLM server unchanged.
"""

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import tools
import wiki

EMBED_URL = os.environ.get("EMBED_URL", "http://embed:8080")
QDRANT_URL = os.environ.get("QDRANT_URL", "http://nomad-box:6333")
# localhost is the machine running Docker, as in box/lib/common.sh
LLM_URL = re.sub(r"://(localhost|127\.0\.0\.1)\b", "://host.docker.internal",
                 os.environ.get("LLM_URL", "http://localhost:11434")).rstrip("/")
CHAT_TOOLS = os.environ.get("CHAT_TOOLS", "1") == "1"
PORT = int(os.environ.get("PORT", "8070"))
COLLECTION = "nomad_knowledge_base"
# nomic-embed-text task prefix; NOMAD indexes with "search_document: " and queries like this
QUERY_PREFIX = "search_query: "
MAX_RESULTS = 20
# Search rounds per answer; then the model is asked to answer from what it found
TOOL_ROUNDS = 4
PAGE = (Path(__file__).parent / "index.html").read_bytes()


def warn(message):
    print(message, file=sys.stderr, flush=True)


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


def stream_chat(request):
    """Lines of a streamed Ollama /api/chat answer."""
    upstream = urllib.request.urlopen(
        urllib.request.Request(f"{LLM_URL}/api/chat", json.dumps(request).encode(), {"Content-Type": "application/json"}),
        timeout=900,
    )
    with upstream:
        for line in upstream:
            if line.strip():
                yield line


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        url = urllib.parse.urlsplit(self.path)
        if url.path == "/":
            self.reply(200, PAGE, "text/html; charset=utf-8")
        elif url.path == "/api/search":
            self.api_search(urllib.parse.parse_qs(url.query))
        else:
            self.reply(404, b"Not found", "text/plain")

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            request = json.loads(body)
        except ValueError:
            request = {}
        # Conversations are streamed; NOMAD's own short calls (titles, suggestions) are not
        if self.path == "/api/chat" and CHAT_TOOLS and request.get("stream") and request.get("messages"):
            self.chat_with_tools(request)
        else:
            self.forward(body)

    def chat_with_tools(self, request):
        messages = [{"role": "system", "content": tools.SYSTEM}, *request["messages"]]
        self.start_stream()
        try:
            for round_ in range(TOOL_ROUNDS + 1):
                final = round_ == TOOL_ROUNDS
                if final:
                    body = {**request, "messages": [*messages, {"role": "system", "content": tools.ANSWER_NOW}]}
                else:
                    body = {**request, "messages": messages, "tools": tools.DEFINITIONS}
                calls, done, wrote = self.relay(body)
                if wrote and calls:  # "Let me look that up." before searching: the answer starts below it
                    self.write_chunk(json.dumps({"model": request.get("model"), "done": False,
                                                 "message": {"role": "assistant", "content": "\n\n"}}).encode() + b"\n")
                if calls and not final:
                    messages.append({"role": "assistant", "content": "", "tool_calls": calls})
                    for call in calls:
                        function = call.get("function", {})
                        result = tools.call(function.get("name"), function.get("arguments", {}), search)
                        messages.append({"role": "tool", "tool_name": function.get("name"), "content": result})
                    continue
                if calls:  # still searching after the last round
                    self.write_chunk(json.dumps({"model": request.get("model"), "done": False,
                                                 "message": {"role": "assistant", "content": tools.NOT_FOUND}}).encode() + b"\n")
                self.write_chunk(done or b'{"done": true}\n')
                break
        except (BrokenPipeError, ConnectionResetError):
            return  # the user closed the chat
        except (urllib.error.URLError, OSError, ValueError) as error:
            warn(f"Chat failed: {error}")
            self.write_chunk(json.dumps({"error": f"LLM server: {error}"}).encode() + b"\n")
        self.end_stream()

    def relay(self, body):
        """Streams one answer of the model to NOMAD; returns its tool calls, its last (done) line and
        whether it wrote any text."""
        calls, done, wrote = [], None, False
        for line in stream_chat(body):
            chunk = json.loads(line)
            if chunk.get("message", {}).get("tool_calls"):
                calls += chunk["message"]["tool_calls"]
            elif chunk.get("done"):
                done = line
            else:
                wrote = wrote or bool(chunk.get("message", {}).get("content"))
                self.write_chunk(line)
        return calls, done, wrote

    def forward(self, body):
        """Sends the request to the LLM server unchanged and streams its answer back."""
        request = urllib.request.Request(f"{LLM_URL}{self.path}", body, {"Content-Type": "application/json"})
        try:
            upstream = urllib.request.urlopen(request, timeout=900)
        except urllib.error.HTTPError as error:
            self.reply(error.code, error.read(), error.headers.get("Content-Type", "text/plain"))
            return
        except (urllib.error.URLError, OSError) as error:
            self.reply(502, f"LLM server not reachable: {error}".encode(), "text/plain")
            return
        with upstream:
            self.start_stream(upstream.status, upstream.headers.get("Content-Type", "application/json"))
            try:
                while chunk := upstream.read1(65536):
                    self.write_chunk(chunk)
                self.end_stream()
            except (BrokenPipeError, ConnectionResetError):
                pass  # the client went away

    def start_stream(self, status=200, content_type="application/x-ndjson"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Transfer-Encoding", "chunked")
        self.end_headers()

    def write_chunk(self, data):
        self.wfile.write(b"%x\r\n%s\r\n" % (len(data), data))
        self.wfile.flush()

    def end_stream(self):
        self.wfile.write(b"0\r\n\r\n")
        self.wfile.flush()

    def api_search(self, query):
        question = query.get("q", [""])[0].strip()
        if not question:
            self.reply_json(400, {"error": "Enter a question"})
            return
        try:
            limit = min(max(int(query.get("limit", ["8"])[0]), 1), MAX_RESULTS)
        except ValueError:
            self.reply_json(400, {"error": "limit must be a number"})
            return
        body = {}
        try:
            body["results"] = search(question, limit)
        except (urllib.error.URLError, OSError, KeyError) as error:
            body["error"] = f"Knowledge base search is not ready yet: {error}"
        try:
            body["wikipedia"] = wiki.passages(tools.KIWIX_URL, question, limit=min(limit, 5))
        except (urllib.error.URLError, OSError, ValueError) as error:
            body["wikipedia"] = []
            warn(f"Wikipedia search: {error}")
        self.reply_json(200 if "results" in body else 502, body)

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
