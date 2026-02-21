#!/usr/bin/env bash
# --- begin runfiles.bash initialization ---
# Copy-pasted from Bazel's Bash runfiles library (tools/bash/runfiles/runfiles.bash).
set -euo pipefail
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
 if [[ -f "$0.runfiles_manifest" ]]; then
   export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
 elif [[ -f "$0.runfiles/MANIFEST" ]]; then
   export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
 elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
   export RUNFILES_DIR="$0.runfiles"
 fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
    "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---

test_script="$1"
shift

with_tmpdir() {
  if [[ -z "${tmpdir}" ]]; then
    return 0
  fi
  "$@"
}

set_git_test_exec_path() {
  export GIT_TEST_EXEC_PATH="$1"
}

setup_tmpdir_env() {
  export TEST_OUTPUT_DIRECTORY="${tmpdir}"
}

setup_tmp_exec_path() {
  local tmp_exec_path base exe mergetools_src

  tmp_exec_path="$(mktemp -d "${tmpdir}/git-exec-path.XXXXXX")"
  # Avoid literal "git-*" when no runfiles are present.
  shopt -s nullglob
  for exe in "${GIT_TEST_INSTALLED}"/git-*; do
    base="$(basename "${exe}")"
    if [[ ! -x "${exe}" ]] || should_strip_exec_bit "${exe}"; then
      cp "${exe}" "${tmp_exec_path}/${base}"
      chmod 0644 "${tmp_exec_path}/${base}"
    else
      ln -s "${exe}" "${tmp_exec_path}/${base}"
    fi
  done
  shopt -u nullglob
  # Link the mergetools directory if it exists
  mergetools_src="${GIT_BUILD_DIR}/mergetools"
  if [[ -d "${mergetools_src}" ]]; then
    ln -s "${mergetools_src}" "${tmp_exec_path}/mergetools"
  fi
  set_git_test_exec_path "${tmp_exec_path}"
}

is_text_file() {
  LC_ALL=C grep -Iq . "$1"
}

has_shebang() {
  [[ "$(head -c 2 "$1" 2>/dev/null)" == "#!" ]]
}

should_strip_exec_bit() {
  if ! is_text_file "$1"; then
    return 1
  fi
  if has_shebang "$1"; then
    return 1
  fi
  return 0
}

setup_tmp_templates() {
  local template_dst template_src

  template_src="${GIT_BUILD_DIR}/templates"
  if [[ ! -d "${template_src}" ]]; then
    return 0
  fi
  template_dst="$(mktemp -d "${tmpdir}/git-templates.XXXXXX")"
  cp -aL "${template_src}/." "${template_dst}/"
  export GIT_TEST_TEMPLATE_DIR="${template_dst}"
}

setup_fake_systemd_analyze() {
  local fake_bin

  fake_bin="$(mktemp -d "${tmpdir}/fake-bin.XXXXXX")"
  cat > "${fake_bin}/systemd-analyze" << 'EOF'
#!/bin/sh
# Fake systemd-analyze that always fails to skip the SYSTEMD_ANALYZE prereq
exit 1
EOF
  chmod +x "${fake_bin}/systemd-analyze"
  export PATH="${fake_bin}:${PATH}"
}

maybe_materialize_test_directory() {
  local test_name test_number data_dir tmp_root entry base

  test_name="$(basename "${test_script}")"
  test_name="${test_name%.sh}"
  test_number="${test_name%%-*}"
  if [[ ! "${test_number}" =~ ^t[0-9]{4}$ ]]; then
    return 0
  fi

  data_dir="${TEST_DIRECTORY}/${test_number}"
  if [[ ! -d "${data_dir}" ]]; then
    return 0
  fi

  if ! find "${data_dir}" -type l -print -quit | grep -q .; then
    return 0
  fi

  tmp_root="$(mktemp -d "${tmpdir:-/tmp}/testdir.XXXXXX")"
  for entry in "${TEST_DIRECTORY}"/*; do
    base="$(basename "${entry}")"
    if [[ "${base}" == "${test_number}" ]]; then
      cp -aL "${entry}" "${tmp_root}/${base}"
    else
      ln -s "${entry}" "${tmp_root}/${base}"
    fi
  done
  TEST_DIRECTORY="${tmp_root}"
}

workspace="${TEST_WORKSPACE:-}"
if [[ -z "${workspace}" ]]; then
  echo "TEST_WORKSPACE not set" >&2
  exit 1
fi

tmpdir="${TEST_TMPDIR:-}"
with_tmpdir setup_tmpdir_env

git_bin="$(rlocation "${workspace}/git")"
build_opts="$(rlocation "${workspace}/GIT-BUILD-OPTIONS")"
if [[ -z "${git_bin}" || -z "${build_opts}" ]]; then
  echo "missing runfiles: git or GIT-BUILD-OPTIONS" >&2
  exit 1
fi

export GIT_TEST_INSTALLED
GIT_TEST_INSTALLED="$(dirname "${git_bin}")"
export GIT_BUILD_DIR
GIT_BUILD_DIR="$(dirname "${build_opts}")"
if [[ -z "${GIT_TEST_EXEC_PATH:-}" ]]; then
  set_git_test_exec_path "${GIT_BUILD_DIR}"
fi

with_tmpdir setup_tmp_exec_path
with_tmpdir setup_tmp_templates
export TEST_DIRECTORY
TEST_DIRECTORY="$(cd "$(dirname "${test_script}")" && pwd -P)"
maybe_materialize_test_directory

# Skip systemd-analyze verify tests because the generated service files
# reference temporary exec paths that don't exist when verify runs
with_tmpdir setup_fake_systemd_analyze

cd "${TEST_DIRECTORY}"
exec bash "$(basename "${test_script}")" "$@"
