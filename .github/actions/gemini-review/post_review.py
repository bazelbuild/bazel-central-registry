#!/usr/bin/env python3
# Copyright 2026 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Deterministically validates and posts Gemini's BCR PR review output."""

import json
import pathlib
import re
import subprocess
import sys

REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")
MAX_INLINE_COMMENTS = 6


def gh_api_get(endpoint, paginate=False, slurp=False):
    cmd = ["gh", "api"]
    if paginate:
        cmd.append("--paginate")
    if slurp:
        cmd.append("--slurp")
    cmd.append(endpoint)
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(res.stdout)


def gh_api_post(endpoint, payload):
    cmd = ["gh", "api", "--method", "POST", endpoint, "--input", "-"]
    return subprocess.run(
        cmd,
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=False,
    )


def load_gemini_response_text():
    stdout_log = pathlib.Path("gemini-artifacts/stdout.log")
    if not stdout_log.is_file():
        raise FileNotFoundError("gemini-artifacts/stdout.log not found")
    raw = stdout_log.read_text(encoding="utf-8", errors="replace").strip()
    if not raw:
        return ""
    try:
        data = json.loads(raw, strict=False)
        if isinstance(data, dict) and isinstance(data.get("response"), str):
            return data["response"]
    except json.JSONDecodeError:
        # When gemini_debug is enabled, non-JSON log lines may precede the CLI's
        # JSON envelope in stdout.log. Scan backwards for the outer JSON object
        # containing a string "response" field.
        decoder = json.JSONDecoder(strict=False)
        for idx in range(len(raw) - 1, -1, -1):
            if raw[idx] == "{":
                try:
                    parsed, _ = decoder.raw_decode(raw[idx:])
                    if isinstance(parsed, dict) and isinstance(parsed.get("response"), str):
                        return parsed["response"]
                except json.JSONDecodeError:
                    continue
    return raw


def dump_gemini_diagnostics(response_text):
    """Logs Gemini stdout/stderr diagnostics to stderr when output parsing fails."""
    stderr_log = pathlib.Path("gemini-artifacts/stderr.log")
    if stderr_log.is_file():
        stderr_text = stderr_log.read_text(encoding="utf-8", errors="replace").strip()
        if stderr_text:
            sys.stderr.write(f"=== gemini-artifacts/stderr.log ===\n{stderr_text[-4000:]}\n")
    sys.stderr.write(f"=== Gemini response_text (len={len(response_text)}) ===\n{response_text[-4000:]}\n")


def repair_unescaped_json_quotes(s):
    """Escapes unescaped double quotes inside JSON string values."""
    out = []
    in_string = False
    is_key = False
    i = 0
    n = len(s)
    while i < n:
        ch = s[i]
        if in_string:
            if ch == "\\":
                if i + 1 < n:
                    out.append(ch)
                    out.append(s[i + 1])
                    i += 2
                    continue
                out.append(ch)
                i += 1
                continue
            if ch == '"':
                rest = s[i + 1 :]
                if is_key:
                    if re.match(r"^\s*:", rest):
                        in_string = False
                        out.append(ch)
                        i += 1
                        continue
                else:
                    if re.match(
                        r'^\s*(?:,\s*"(?:should_post|skip_reason|body|comments|path|line|side|start_line|start_side)"\s*:|\}\s*(?:,\s*\{|\]|\}|`|$))',
                        rest,
                    ):
                        in_string = False
                        out.append(ch)
                        i += 1
                        continue
                out.append('\\"')
                i += 1
                continue
            out.append(ch)
            i += 1
        else:
            if ch == '"':
                prev_non_ws = ""
                for k in range(len(out) - 1, -1, -1):
                    if not out[k].isspace():
                        prev_non_ws = out[k]
                        break
                in_string = True
                is_key = prev_non_ws in ("{", ",")
            out.append(ch)
            i += 1
    return "".join(out)


def extract_review_json(text):
    """Extracts the structured review JSON object from Gemini's response text."""
    text = text.strip()
    if not text:
        dump_gemini_diagnostics(text)
        raise ValueError("Gemini response text is empty")

    # Scan from the end for the last valid JSON object containing "should_post".
    # Using JSONDecoder(strict=False).raw_decode properly handles nested ```suggestion
    # blocks, braces, and any unescaped control characters inside JSON string values.
    decoder = json.JSONDecoder(strict=False)
    for idx in range(len(text) - 1, -1, -1):
        if text[idx] == "{":
            candidate = text[idx:]
            for attempt in (candidate, repair_unescaped_json_quotes(candidate)):
                try:
                    parsed, _ = decoder.raw_decode(attempt)
                    if isinstance(parsed, dict) and "should_post" in parsed:
                        return parsed
                except json.JSONDecodeError:
                    continue

    dump_gemini_diagnostics(text)
    raise ValueError("Could not find valid review JSON object with 'should_post' in Gemini output")


def format_fallback_comment(comment):
    path = str(comment.get("path") or "<unknown>").strip()
    line = comment.get("line")
    start_line = comment.get("start_line")
    loc = f"`{path}`"
    if start_line and line and start_line != line:
        loc += f" (lines {start_line}–{line})"
    elif line:
        loc += f" (line {line})"
    body = str(comment.get("body") or "").strip()
    return f"#### {loc}\n\n{body}"


def append_fallback_comments(body, fallback_comments):
    if not fallback_comments:
        return body
    sections = "\n\n".join(format_fallback_comment(c) for c in fallback_comments)
    if body:
        return f"{body.rstrip()}\n\n---\n\n### Inline Review Comments\n\n{sections}"
    return f"### Inline Review Comments\n\n{sections}"


def main():
    context_path = pathlib.Path(".gemini/context.json")
    if not context_path.is_file():
        raise FileNotFoundError(".gemini/context.json not found")

    context = json.loads(context_path.read_text(encoding="utf-8"))
    repo = str(context.get("repository") or "").strip()
    pr_number = int(context["pull_request_number"])
    head_sha = str(context.get("head_sha") or "").strip()

    if not REPO_RE.fullmatch(repo):
        raise ValueError(f"Invalid repository in context.json: {repo!r}")
    if pr_number <= 0:
        raise ValueError(f"Invalid pull_request_number in context.json: {pr_number!r}")
    if not SHA_RE.fullmatch(head_sha):
        raise ValueError(f"Invalid head_sha in context.json: {head_sha!r}")

    response_text = load_gemini_response_text()
    review_data = extract_review_json(response_text)

    should_post = review_data.get("should_post") is True
    skip_reason = str(review_data.get("skip_reason") or "").strip()
    body = str(review_data.get("body") or "").strip()
    raw_comments = review_data.get("comments") or []

    if not should_post:
        print(f"Gemini decided not to post a review (skip_reason={skip_reason or 'none'}).")
        return 0

    pages = gh_api_get(
        f"repos/{repo}/pulls/{pr_number}/files?per_page=100",
        paginate=True,
        slurp=True,
    )
    pr_filenames = {
        item.get("filename")
        for page in pages
        for item in page
        if isinstance(item, dict) and isinstance(item.get("filename"), str)
    }

    valid_inline_comments = []
    fallback_comments = []

    if isinstance(raw_comments, list):
        for item in raw_comments:
            if not isinstance(item, dict):
                continue
            path = str(item.get("path") or "").strip()
            c_body = str(item.get("body") or "").strip()
            line = item.get("line")
            start_line = item.get("start_line")
            side = str(item.get("side") or "RIGHT").strip().upper()
            if side not in ("LEFT", "RIGHT"):
                side = "RIGHT"

            if not path or not c_body:
                continue

            valid_line = isinstance(line, int) and not isinstance(line, bool) and line > 0
            valid_start = isinstance(start_line, int) and not isinstance(start_line, bool) and 0 < start_line < line

            if path in pr_filenames and valid_line and len(valid_inline_comments) < MAX_INLINE_COMMENTS:
                comment_obj = {
                    "path": path,
                    "line": line,
                    "side": side,
                    "body": c_body,
                }
                if valid_start:
                    comment_obj["start_line"] = start_line
                    start_side = str(item.get("start_side") or side).strip().upper()
                    comment_obj["start_side"] = start_side if start_side in ("LEFT", "RIGHT") else side
                valid_inline_comments.append(comment_obj)
            else:
                fallback_comments.append(
                    {
                        "path": path,
                        "line": line if valid_line else None,
                        "start_line": start_line if valid_start else None,
                        "body": c_body,
                    }
                )

    final_body = append_fallback_comments(body, fallback_comments)
    if not final_body and not valid_inline_comments:
        print("should_post=true but both review body and comments are empty; skipping.")
        return 0

    # SECURITY: Always hardcode event="COMMENT" so Gemini can never approve or request changes.
    payload = {
        "commit_id": head_sha,
        "event": "COMMENT",
        "body": final_body,
        "comments": valid_inline_comments,
    }

    endpoint = f"repos/{repo}/pulls/{pr_number}/reviews"
    res = gh_api_post(endpoint, payload)
    if res.returncode == 0:
        review_resp = json.loads(res.stdout)
        print(
            f"Posted Gemini review on PR #{pr_number} "
            f"(inline_comments={len(valid_inline_comments)}, url={review_resp.get('html_url')})"
        )
        return 0

    # If GitHub rejected inline comment line numbers (HTTP 422), fold them into the top-level body and retry.
    err_output = f"{res.stderr}\n{res.stdout}".strip()
    if valid_inline_comments and ("422" in err_output or "Unprocessable" in err_output):
        print(
            f"Warning: GitHub rejected inline comment position(s) ({err_output}); "
            "retrying with inline comments folded into the top-level review body."
        )
        retry_body = append_fallback_comments(final_body, valid_inline_comments)
        retry_payload = {
            "commit_id": head_sha,
            "event": "COMMENT",
            "body": retry_body,
            "comments": [],
        }
        retry_res = gh_api_post(endpoint, retry_payload)
        if retry_res.returncode == 0:
            review_resp = json.loads(retry_res.stdout)
            print(f"Posted fallback Gemini review on PR #{pr_number} (url={review_resp.get('html_url')})")
            return 0
        sys.stderr.write(f"{retry_res.stderr}\n{retry_res.stdout}")
        return retry_res.returncode

    sys.stderr.write(f"{res.stderr}\n{res.stdout}")
    return res.returncode


if __name__ == "__main__":
    sys.exit(main())
