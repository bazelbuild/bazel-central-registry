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
"""Prepares .gemini/context.json for BCR Gemini PR reviews."""

import base64
import copy
import json
import os
import pathlib
import re
import subprocess
import sys
import yaml


# Bazel module name / version character sets, per
# https://bazel.build/external/module#module_name and #version (matching
# bcr_presubmit.py). Anything outside these sets is not a valid Bzlmod
# identifier, so rejecting it at the source prevents path traversal, URL
# query/path injection in `gh api` calls, and unexpected characters.
MODULE_NAME_PATTERN = r"[a-z](?:[a-z0-9._-]*[a-z0-9])?"
MODULE_VERSION_PATTERN = r"[A-Za-z0-9]+(?:[._+-][A-Za-z0-9]+)*"
MODULE_NAME_RE = re.compile(rf"^{MODULE_NAME_PATTERN}$")
MODULE_VERSION_RE = re.compile(rf"^{MODULE_VERSION_PATTERN}$")
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
PR_NUMBER_RE = re.compile(r"^[1-9]\d*$")
SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")


def sanitize_untrusted_str(value, max_len=120):
    """Sanitizes untrusted strings before embedding in context.json.

    Strips backticks (preventing markdown code-fence breakout when context.json
    is injected into bcr-review.toml), neutralizes '@' (preventing unintended
    GitHub user/team mentions in @bazel-io's review summary), and collapses
    control characters.
    """
    text = str(value if value is not None else "")
    text = text.replace("`", "'").replace("@", "@\u200b")
    text = re.sub(r"[\r\n\t]+", " ", text).strip()
    if len(text) > max_len:
        return text[:max_len] + "..."
    return text


def gh_api(endpoint, paginate=False, slurp=False):
    cmd = ["gh", "api"]
    if paginate:
        cmd.append("--paginate")
    if slurp:
        cmd.append("--slurp")
    cmd.append(endpoint)
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(res.stdout)


def decode_github_file_content(resp):
    """Decodes base64 file content from GitHub Contents API, rejecting symlinks/dirs."""
    if not isinstance(resp, dict) or resp.get("type") != "file":
        kind = resp.get("type") if isinstance(resp, dict) else type(resp).__name__
        raise ValueError(f"Expected regular file from GitHub API, got {kind!r}")
    if resp.get("encoding") != "base64" or not isinstance(resp.get("content"), str):
        raise ValueError(f"Unsupported or empty content encoding from GitHub API: {resp.get('encoding')!r}")
    return base64.b64decode(resp["content"]).decode("utf-8")


def resolve_module_dir(modules_root, mod_name):
    """Returns modules/<mod_name> if valid, non-symlink, and inside modules/, else None."""
    if not isinstance(mod_name, str) or not MODULE_NAME_RE.fullmatch(mod_name):
        return None
    candidate = modules_root / mod_name
    if candidate.is_symlink():
        return None
    resolved = candidate.resolve()
    if resolved.parent != modules_root.resolve():
        return None
    return candidate


def resolve_module_version_dir(modules_root, mod_name, ver_name):
    """Returns modules/<mod_name>/<ver_name> if valid, non-symlink, and inside modules/<mod_name>, else None."""
    mod_dir = resolve_module_dir(modules_root, mod_name)
    if mod_dir is None:
        return None
    if not isinstance(ver_name, str) or not MODULE_VERSION_RE.fullmatch(ver_name):
        return None
    candidate = mod_dir / ver_name
    if candidate.is_symlink():
        return None
    resolved = candidate.resolve()
    if resolved.parent != mod_dir.resolve():
        return None
    return candidate


def resolve_path_within(base_dir, rel_path):
    """Returns base_dir / rel_path if it resolves inside base_dir without symlinks, else None."""
    rel_parts = pathlib.PurePosixPath(rel_path).parts
    if not rel_parts or ".." in rel_parts or "." in rel_parts or rel_path.startswith("/"):
        return None
    cur = base_dir
    for part in rel_parts:
        cur = cur / part
        if cur.is_symlink():
            return None
    if not cur.resolve().is_relative_to(base_dir.resolve()):
        return None
    return cur


def presubmit_changed_beyond_platforms_or_bazel(prev_doc, curr_doc):
    """Matches tools/bcr_validation.py verify_presubmit_yml_change logic."""
    if curr_doc == prev_doc:
        return False
    prev_scrubbed = copy.deepcopy(prev_doc)
    curr_scrubbed = copy.deepcopy(curr_doc)
    for doc in (prev_scrubbed, curr_scrubbed):
        if not isinstance(doc, dict):
            return True
        for node in (doc, doc.setdefault("bcr_test_module", {})):
            if isinstance(node, dict):
                mat = node.setdefault("matrix", {})
                if isinstance(mat, dict):
                    mat["bazel"] = None
                    mat["platform"] = None
    return curr_scrubbed != prev_scrubbed


def main():
    repo = os.environ["REPOSITORY"].strip()
    event_name = os.environ["EVENT_NAME"].strip()
    event_action = os.environ.get("EVENT_ACTION", "").strip()
    pr_number = str(os.environ["PR_NUMBER"]).strip()
    comment_body = os.environ.get("COMMENT_BODY", "").strip()
    input_context = os.environ.get("INPUT_CONTEXT", "").strip()
    github_output = os.environ.get("GITHUB_OUTPUT", "/dev/null")

    if not REPO_RE.fullmatch(repo):
        raise ValueError(f"Invalid repository identifier: {repo!r}")
    if not PR_NUMBER_RE.fullmatch(pr_number):
        raise ValueError(f"Invalid pull request number: {pr_number!r}")

    modules_root = pathlib.Path("modules")

    pr_info = gh_api(f"repos/{repo}/pulls/{pr_number}")
    pr_state = pr_info.get("state")
    is_draft = bool(pr_info.get("draft"))

    is_manual = event_name in ("workflow_dispatch", "issue_comment") or (
        event_name == "pull_request_target" and event_action == "labeled"
    )
    trigger_type = "manual" if is_manual else "automatic"

    if pr_state != "open" or (is_draft and not is_manual):
        print(f"Skipping PR #{pr_number} (state={pr_state}, draft={is_draft}, trigger={trigger_type})")
        with open(github_output, "a", encoding="utf-8") as out:
            out.write("should_run=false\n")
        return 0

    additional_context = input_context
    if not additional_context and comment_body:
        additional_context = re.sub(
            r"^(@bazel-io\s+gemini-review|@gemini-cli\s+/review)\s*",
            "",
            comment_body,
        ).strip()
    additional_context = sanitize_untrusted_str(additional_context, max_len=500)

    pr_author = sanitize_untrusted_str((pr_info.get("user") or {}).get("login", ""), max_len=80)
    head_sha = str((pr_info.get("head") or {}).get("sha", "")).strip()
    if not SHA_RE.fullmatch(head_sha):
        raise ValueError(f"Invalid head SHA from GitHub PR API: {head_sha!r}")

    changed_files_count = int(pr_info.get("changed_files") or 0)
    if changed_files_count > 500:
        pr_files = gh_api(f"repos/{repo}/pulls/{pr_number}/files?per_page=100")
    else:
        pages = gh_api(
            f"repos/{repo}/pulls/{pr_number}/files?per_page=100",
            paginate=True,
            slurp=True,
        )
        pr_files = [item for page in pages for item in page]

    module_version_re = re.compile(rf"^modules/({MODULE_NAME_PATTERN})/({MODULE_VERSION_PATTERN})/(.+)$")
    metadata_re = re.compile(rf"^modules/({MODULE_NAME_PATTERN})/metadata\.json$")
    module_readme_re = re.compile(rf"^modules/({MODULE_NAME_PATTERN})/README\.md$")

    modified_module_versions_set = set()
    modified_modules_set = set()
    metadata_changed_modules = set()
    added_metadata_modules = set()
    non_module_files = []
    mutated_existing_version_files = []

    def classify_path(filepath, status):
        safe_path = sanitize_untrusted_str(filepath, max_len=200)
        m_ver = module_version_re.match(filepath)
        m_meta = metadata_re.match(filepath)
        m_readme = module_readme_re.match(filepath)
        if m_ver:
            mod_name, ver_name, rel_path = m_ver.groups()
            ver_dir = resolve_module_version_dir(modules_root, mod_name, ver_name)
            main_file = resolve_path_within(ver_dir, rel_path) if ver_dir is not None else None
            if ver_dir is None or main_file is None:
                non_module_files.append(safe_path)
                return
            modified_module_versions_set.add((mod_name, ver_name))
            modified_modules_set.add(mod_name)
            # An existing version on main is mutated if its version directory already exists on main,
            # except that BCR allows in-place updates (not deletions) to presubmit.yml and README.md.
            if ver_dir.exists() or main_file.exists():
                if status == "removed" or rel_path not in ("presubmit.yml", "README.md"):
                    mutated_existing_version_files.append(safe_path)
        elif m_meta:
            mod_name = m_meta.group(1)
            mod_dir = resolve_module_dir(modules_root, mod_name)
            if mod_dir is None or resolve_path_within(mod_dir, "metadata.json") is None:
                non_module_files.append(safe_path)
                return
            modified_modules_set.add(mod_name)
            metadata_changed_modules.add(mod_name)
            if status == "added":
                added_metadata_modules.add(mod_name)
        elif m_readme:
            mod_name = m_readme.group(1)
            mod_dir = resolve_module_dir(modules_root, mod_name)
            if mod_dir is None or resolve_path_within(mod_dir, "README.md") is None:
                non_module_files.append(safe_path)
                return
            modified_modules_set.add(mod_name)
        else:
            non_module_files.append(safe_path)

    for f in pr_files:
        filename = f.get("filename", "")
        status = f.get("status", "")
        classify_path(filename, status)
        prev_filename = f.get("previous_filename", "")
        if prev_filename and prev_filename != filename:
            classify_path(prev_filename, "removed")

    reasons = []
    total_files = max(changed_files_count, len(pr_files))
    if total_files > 500:
        reasons.append(f"PR modifies more than 500 files ({total_files} files).")

    if non_module_files:
        sample = ", ".join(non_module_files[:5])
        more = f" (+{len(non_module_files) - 5} more)" if len(non_module_files) > 5 else ""
        reasons.append(f"Non-module files modified: {sample}{more}.")

    if not modified_modules_set and not non_module_files:
        reasons.append("No module versions modified in this PR.")

    if mutated_existing_version_files:
        sample = ", ".join(mutated_existing_version_files[:5])
        reasons.append(
            f"Existing published module version files modified/deleted (violates add-only policy): {sample}."
        )

    head_meta_by_module = {}
    modified_module_versions_info = []
    for mod_name in sorted(modified_modules_set):
        mod_dir = resolve_module_dir(modules_root, mod_name)
        main_meta_path = resolve_path_within(mod_dir, "metadata.json") if mod_dir is not None else None
        is_new_module = mod_name in added_metadata_modules or main_meta_path is None or not main_meta_path.exists()
        main_meta = None
        if not is_new_module:
            try:
                main_meta = json.loads(main_meta_path.read_text(encoding="utf-8"))
            except Exception as e:
                reasons.append(f"Failed to parse {main_meta_path} on main: {sanitize_untrusted_str(e)}")

        if is_new_module:
            reasons.append(f"Adds a new module '{mod_name}'.")
        else:
            maintainers = (main_meta or {}).get("maintainers") or []
            gh_maintainers = [m for m in maintainers if isinstance(m, dict) and m.get("github")]
            maintainer_logins = {str(m.get("github", "")).lower() for m in gh_maintainers}
            if not gh_maintainers:
                reasons.append(f"Module '{mod_name}' has no GitHub maintainers listed in metadata.json on main.")
            elif pr_author.lower() not in maintainer_logins:
                notify_maintainers = [m for m in gh_maintainers if not m.get("do_not_notify")]
                if not notify_maintainers:
                    reasons.append(
                        f"PR author is not a listed maintainer for '{mod_name}', and all maintainers have do_not_notify set."
                    )

        head_meta = None
        if mod_name in metadata_changed_modules:
            try:
                meta_resp = gh_api(f"repos/{repo}/contents/modules/{mod_name}/metadata.json?ref={head_sha}")
                head_meta_raw = decode_github_file_content(meta_resp)
                parsed_meta = json.loads(head_meta_raw)
                if not isinstance(parsed_meta, dict):
                    raise ValueError("metadata.json root must be a JSON object")
                head_meta = parsed_meta
                head_meta_by_module[mod_name] = head_meta
            except Exception as e:
                head_meta = None
                reasons.append(
                    f"Failed to fetch or parse 'modules/{mod_name}/metadata.json' from PR head: {sanitize_untrusted_str(e)}."
                )

            if not is_new_module and main_meta is not None and head_meta is not None:
                main_versions = main_meta.get("versions") if isinstance(main_meta.get("versions"), list) else []
                head_versions = head_meta.get("versions") if isinstance(head_meta.get("versions"), list) else []
                removed_versions = [sanitize_untrusted_str(v, 60) for v in main_versions if v not in head_versions]
                if removed_versions:
                    reasons.append(
                        f"Existing version(s) removed from 'modules/{mod_name}/metadata.json': {removed_versions[:5]} (violates add-only policy)."
                    )
                orphan_added_versions = [
                    sanitize_untrusted_str(v, 60)
                    for v in head_versions
                    if v not in main_versions and (mod_name, v) not in modified_module_versions_set
                ]
                if orphan_added_versions:
                    reasons.append(
                        f"Version(s) added to 'modules/{mod_name}/metadata.json' without corresponding module version files: {orphan_added_versions[:5]}."
                    )

                main_copy = dict(main_meta)
                head_copy = dict(head_meta)
                main_copy.pop("versions", None)
                head_copy.pop("versions", None)
                if main_copy != head_copy:
                    changed_keys = [
                        sanitize_untrusted_str(k, 60)
                        for k in sorted(set(main_copy.keys()) | set(head_copy.keys()))
                        if main_copy.get(k) != head_copy.get(k)
                    ]
                    reasons.append(
                        f"Sensitive metadata.json changes in 'modules/{mod_name}/metadata.json' outside 'versions': {changed_keys[:10]}."
                    )

    for mod_name, ver_name in sorted(modified_module_versions_set):
        mod_dir = resolve_module_dir(modules_root, mod_name)
        main_meta_path = resolve_path_within(mod_dir, "metadata.json") if mod_dir is not None else None
        is_new_module = mod_name in added_metadata_modules or main_meta_path is None or not main_meta_path.exists()
        main_ver_dir = resolve_module_version_dir(modules_root, mod_name, ver_name)
        mutates_existing = any(f.startswith(f"modules/{mod_name}/{ver_name}/") for f in mutated_existing_version_files)

        prev_version = None
        prev_version_path = None
        presubmit_changed = False
        if not is_new_module:
            try:
                main_versions = []
                if main_meta_path is not None:
                    main_meta_doc = json.loads(main_meta_path.read_text(encoding="utf-8"))
                    if isinstance(main_meta_doc.get("versions"), list):
                        main_versions = main_meta_doc["versions"]

                candidate_dir = None
                if main_ver_dir is not None and main_ver_dir.exists():
                    # In-place update to an existing version (e.g., updating presubmit.yml or README.md).
                    prev_version = ver_name
                    candidate_dir = main_ver_dir
                else:
                    candidate_prev_versions = []
                    head_meta = head_meta_by_module.get(mod_name)
                    head_versions = head_meta.get("versions") if isinstance(head_meta, dict) else None
                    if isinstance(head_versions, list) and ver_name in head_versions:
                        idx = head_versions.index(ver_name)
                        candidate_prev_versions.extend(reversed(head_versions[:idx]))
                    for v in reversed(main_versions):
                        if v != ver_name and v not in candidate_prev_versions:
                            candidate_prev_versions.append(v)

                    for candidate_prev in candidate_prev_versions:
                        if not isinstance(candidate_prev, str) or not MODULE_VERSION_RE.fullmatch(candidate_prev):
                            reasons.append(
                                f"Invalid version entry in 'modules/{mod_name}/metadata.json': {sanitize_untrusted_str(candidate_prev, 60)!r}."
                            )
                            continue
                        resolved_dir = resolve_module_version_dir(modules_root, mod_name, candidate_prev)
                        if resolved_dir is not None and resolved_dir.exists():
                            prev_version = candidate_prev
                            candidate_dir = resolved_dir
                            break

                # Also check the latest version on main (matching tools/bcr_validation.py
                # get_latest_module_version) in case a backport PR adds an older version branch.
                latest_main_version = None
                latest_main_dir = None
                if main_versions:
                    last_v = main_versions[-1]
                    if isinstance(last_v, str) and MODULE_VERSION_RE.fullmatch(last_v):
                        resolved_last = resolve_module_version_dir(modules_root, mod_name, last_v)
                        if resolved_last is not None and resolved_last.exists():
                            latest_main_version = last_v
                            latest_main_dir = resolved_last

                if candidate_dir is not None:
                    prev_version_path = str(candidate_dir)

                baseline_dirs = []
                if candidate_dir is not None and prev_version is not None:
                    baseline_dirs.append((prev_version, candidate_dir))
                if (
                    latest_main_dir is not None
                    and latest_main_version is not None
                    and latest_main_version != prev_version
                ):
                    baseline_dirs.append((latest_main_version, latest_main_dir))

                if baseline_dirs:
                    curr_doc = None
                    try:
                        presubmit_resp = gh_api(
                            f"repos/{repo}/contents/modules/{mod_name}/{ver_name}/presubmit.yml?ref={head_sha}"
                        )
                        curr_raw = decode_github_file_content(presubmit_resp)
                        curr_doc = yaml.safe_load(curr_raw) or {}
                    except Exception as e:
                        presubmit_changed = True
                        reasons.append(
                            f"Failed to fetch or parse 'modules/{mod_name}/{ver_name}/presubmit.yml' from PR head: {sanitize_untrusted_str(e)}."
                        )

                    if curr_doc is not None:
                        for base_ver, base_dir in baseline_dirs:
                            base_presubmit_path = resolve_path_within(base_dir, "presubmit.yml")
                            if base_presubmit_path is not None and base_presubmit_path.exists():
                                base_doc = yaml.safe_load(base_presubmit_path.read_text(encoding="utf-8")) or {}
                                if presubmit_changed_beyond_platforms_or_bazel(base_doc, curr_doc):
                                    presubmit_changed = True
                                    reasons.append(
                                        f"presubmit.yml in '{mod_name}@{ver_name}' differs from version '{base_ver}' on main beyond matrix.platform/matrix.bazel (requires review before applying 'presubmit-auto-run')."
                                    )
                                    break
            except Exception as e:
                reasons.append(
                    f"Error comparing '{mod_name}@{ver_name}' against previous version: {sanitize_untrusted_str(e)}."
                )

        modified_module_versions_info.append(
            {
                "module": mod_name,
                "version": ver_name,
                "is_new_module": is_new_module,
                "mutates_existing_version": mutates_existing,
                "previous_version": prev_version,
                "previous_version_path": prev_version_path,
                "presubmit_changed_beyond_platforms_or_bazel": presubmit_changed,
            }
        )

    needs_bcr_maintainer_review = len(reasons) > 0

    owner, repo_name = repo.split("/", 1)
    context_data = {
        "repository": repo,
        "owner": owner,
        "repo": repo_name,
        "pull_request_number": int(pr_number),
        "pr_author": pr_author,
        "head_sha": head_sha,
        "trigger_type": trigger_type,
        "additional_context": additional_context,
        "needs_bcr_maintainer_review": needs_bcr_maintainer_review,
        "bcr_maintainer_review_reasons": reasons,
        "modified_module_versions": modified_module_versions_info,
        "non_module_files": non_module_files,
        "mutated_existing_version_files": mutated_existing_version_files,
    }

    os.makedirs(".gemini", exist_ok=True)
    with open(".gemini/context.json", "w", encoding="utf-8") as f:
        json.dump(context_data, f, indent=2)

    print("Generated .gemini/context.json:")
    print(json.dumps(context_data, indent=2))

    with open(github_output, "a", encoding="utf-8") as out:
        out.write("should_run=true\n")
        out.write(f"pr_number={pr_number}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
