#!/usr/bin/env python3
import argparse
import http.client
import json
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.request import urlopen


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


class Evidence:
    def __init__(self, path: Path):
        self.path = path
        self.lock = threading.Lock()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("", encoding="utf-8")

    def write(self, event: str, **payload):
        row = {"event": event, "ts": time.time(), **payload}
        with self.lock:
            with self.path.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def make_mock_handler(evidence: Evidence):
    class MockChatHandler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, fmt, *args):
            return

        def do_GET(self):
            if self.path.endswith("/models"):
                body = json.dumps(
                    {
                        "object": "list",
                        "data": [
                            {
                                "id": "mock-coder",
                                "object": "model",
                                "created": 0,
                                "owned_by": "mock",
                            }
                        ],
                    }
                ).encode("utf-8")
                self.send_response(200)
                self.send_header("content-type", "application/json")
                self.send_header("content-length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
            self.send_error(404)

        def do_POST(self):
            length = int(self.headers.get("content-length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
            tools = payload.get("tools") or []
            messages = payload.get("messages") or []
            has_tool_result = any(
                isinstance(message, dict)
                and message.get("role") in {"tool", "function"}
                for message in messages
            )
            tool_name = None
            if tools:
                tool_name = tools[0].get("function", {}).get("name")
            evidence.write(
                "mock_upstream_request",
                path=self.path,
                model=payload.get("model"),
                stream=payload.get("stream"),
                thinking=payload.get("thinking"),
                reasoning_effort=payload.get("reasoning_effort"),
                tool_names=[
                    tool.get("function", {}).get("name")
                    for tool in tools
                    if isinstance(tool, dict)
                ],
                has_tool_result=has_tool_result,
            )

            if payload.get("stream"):
                self.send_response(200)
                self.send_header("content-type", "text/event-stream")
                self.send_header("cache-control", "no-cache")
                self.send_header("connection", "close")
                self.end_headers()

                chunks = [
                    {"choices": [{"index": 0, "delta": {"role": "assistant"}, "finish_reason": None}]},
                    {"choices": [{"index": 0, "delta": {"reasoning_content": "先确认工具和目录。"}, "finish_reason": None}]},
                    {"choices": [{"index": 0, "delta": {"content": "我会列出当前目录。"}, "finish_reason": None}]},
                ]
                if has_tool_result:
                    chunks.extend(
                        [
                            {
                                "choices": [
                                    {
                                        "index": 0,
                                        "delta": {
                                            "content": "工具结果已收到，当前目录已经列出。"
                                        },
                                        "finish_reason": None,
                                    }
                                ]
                            },
                            {
                                "choices": [
                                    {
                                        "index": 0,
                                        "delta": {},
                                        "finish_reason": "stop",
                                    }
                                ],
                                "usage": {
                                    "prompt_tokens": 35,
                                    "completion_tokens": 10,
                                    "total_tokens": 45,
                                },
                            },
                        ]
                    )
                elif tool_name:
                    tool_arguments = (
                        "{\"cmd\":\"ls\",\"yield_time_ms\":10000,\"max_output_tokens\":6000}"
                        if tool_name == "exec_command"
                        else "{\"input\":\"ls\"}"
                    )
                    chunks.extend(
                        [
                            {
                                "choices": [
                                    {
                                        "index": 0,
                                        "delta": {
                                            "tool_calls": [
                                                {
                                                    "index": 0,
                                                    "id": "call_mock_ls",
                                                    "type": "function",
                                                    "function": {
                                                        "name": tool_name,
                                                        "arguments": tool_arguments,
                                                    },
                                                }
                                            ]
                                        },
                                        "finish_reason": None,
                                    }
                                ]
                            },
                            {
                                "choices": [
                                    {
                                        "index": 0,
                                        "delta": {},
                                        "finish_reason": "tool_calls",
                                    }
                                ],
                                "usage": {
                                    "prompt_tokens": 19,
                                    "completion_tokens": 7,
                                    "total_tokens": 26,
                                },
                            },
                        ]
                    )
                else:
                    chunks.append(
                        {
                            "choices": [
                                {
                                    "index": 0,
                                    "delta": {},
                                    "finish_reason": "stop",
                                }
                            ],
                            "usage": {
                                "prompt_tokens": 19,
                                "completion_tokens": 7,
                                "total_tokens": 26,
                            },
                        }
                    )

                for index, chunk in enumerate(chunks):
                    chunk.setdefault("id", "chatcmpl-mock")
                    chunk.setdefault("object", "chat.completion.chunk")
                    chunk.setdefault("created", int(time.time()))
                    chunk.setdefault("model", "mock-coder")
                    line = f"data: {json.dumps(chunk, ensure_ascii=False)}\n\n"
                    self.wfile.write(line.encode("utf-8"))
                    self.wfile.flush()
                    evidence.write("mock_upstream_sse_chunk", index=index, payload=chunk)
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
                return

            body = json.dumps(
                {
                    "id": "chatcmpl-mock",
                    "object": "chat.completion",
                    "created": int(time.time()),
                    "model": "mock-coder",
                    "choices": [
                        {
                            "index": 0,
                            "message": {
                                "role": "assistant",
                                "reasoning_content": "非流式思考。",
                                "content": "非流式响应。",
                            },
                            "finish_reason": "stop",
                        }
                    ],
                    "usage": {
                        "prompt_tokens": 12,
                        "completion_tokens": 4,
                        "total_tokens": 16,
                    },
                },
                ensure_ascii=False,
            ).encode("utf-8")
            self.send_response(200)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    return MockChatHandler


def read_listening_line(process: subprocess.Popen, evidence: Evidence) -> int:
    assert process.stdout is not None
    deadline = time.time() + 8
    while time.time() < deadline:
        line = process.stdout.readline()
        if not line:
            continue
        decoded = line.decode("utf-8", errors="replace").strip()
        evidence.write("sidecar_stdout", line=decoded)
        try:
            payload = json.loads(decoded)
        except json.JSONDecodeError:
            continue
        if payload.get("event") == "listening":
            return int(payload["port"])
    raise RuntimeError("raytone-proxy did not report a listening port")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--codex-binary")
    parser.add_argument("--codex-cwd", default=os.getcwd())
    args = parser.parse_args()

    evidence = Evidence(Path(args.out))
    mock_port = free_port()
    server = ThreadingHTTPServer(("127.0.0.1", mock_port), make_mock_handler(evidence))
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()
    evidence.write("mock_upstream_started", port=mock_port)

    binary_path = Path(args.binary).resolve()

    with tempfile.TemporaryDirectory(prefix="raytone-proxy-smoke-") as tmp:
        config_path = Path(tmp) / "config.toml"
        config_path.write_text(
            f"""
current_provider = "mock"

[[providers]]
id = "mock"
name = "Mock Chat Provider"
base_url = "http://127.0.0.1:{mock_port}/v1"
api_key = "mock-key"
model = "mock-coder"
models = ["mock-coder"]

[providers.reasoning]
supportsThinking = true
supportsEffort = false
thinkingParam = "thinking"
effortParam = "none"
outputFormat = "reasoning_content"
""",
            encoding="utf-8",
        )

        process = subprocess.Popen(
            [
                str(binary_path),
                "--host",
                "127.0.0.1",
                "--port",
                "0",
                "--config",
                str(config_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=binary_path.parent,
        )
        try:
            port = read_listening_line(process, evidence)
            health = json.loads(urlopen(f"http://127.0.0.1:{port}/health", timeout=5).read())
            evidence.write("sidecar_health", payload=health)

            payload = {
                "model": "placeholder-client-model",
                "stream": True,
                "reasoning": {"effort": "medium"},
                "input": "列出当前目录文件。",
                "tools": [
                    {
                        "type": "custom",
                        "name": "local_shell",
                        "description": "Run a local shell command with an input string.",
                    }
                ],
            }
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            conn = http.client.HTTPConnection("127.0.0.1", port, timeout=10)
            conn.request(
                "POST",
                "/v1/responses",
                body=body,
                headers={
                    "content-type": "application/json",
                    "authorization": "Bearer local-placeholder",
                },
            )
            response = conn.getresponse()
            evidence.write(
                "sidecar_response_headers",
                status=response.status,
                content_type=response.getheader("content-type"),
            )
            raw = response.read().decode("utf-8", errors="replace")
            for line in raw.splitlines():
                if line.strip():
                    evidence.write("sidecar_sse_line", line=line)
            conn.close()

            if args.codex_binary:
                codex_home = Path(tmp) / "codex-home"
                codex_home.mkdir(parents=True, exist_ok=True)
                (codex_home / "config.toml").write_text(
                    f"""
model = "mock-coder"
model_provider = "raytone-mock"

[model_providers.raytone-mock]
name = "Raytone Mock"
base_url = "http://127.0.0.1:{port}/v1"
wire_api = "responses"
requires_openai_auth = false
supports_websockets = false
""",
                    encoding="utf-8",
                )
                env = os.environ.copy()
                env["CODEX_HOME"] = str(codex_home)
                command = [
                    str(Path(args.codex_binary).resolve()),
                    "exec",
                    "--json",
                    "--skip-git-repo-check",
                    "--cd",
                    args.codex_cwd,
                    "--sandbox",
                    "danger-full-access",
                    "--color",
                    "never",
                    "请运行 ls 列出当前目录文件，然后用中文简短总结。",
                ]
                evidence.write("codex_exec_start", command=command, codex_home=str(codex_home))
                completed = subprocess.run(
                    command,
                    env=env,
                    cwd=args.codex_cwd,
                    text=True,
                    capture_output=True,
                    timeout=45,
                )
                evidence.write("codex_exec_exit", returncode=completed.returncode)
                for line in completed.stdout.splitlines():
                    if line.strip():
                        evidence.write("codex_exec_stdout_line", line=line)
                for line in completed.stderr.splitlines():
                    if line.strip():
                        evidence.write("codex_exec_stderr_line", line=line)
                if completed.returncode != 0:
                    return completed.returncode
        finally:
            process.terminate()
            try:
                _, stderr = process.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                _, stderr = process.communicate(timeout=3)
            if stderr:
                evidence.write("sidecar_stderr", text=stderr.decode("utf-8", errors="replace"))
            server.shutdown()
            server.server_close()

    print(args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
