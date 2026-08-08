#!/usr/bin/env bash
# Hermetic Kit launcher.
#
# Everything Kit needs is already laid out by Bazel; this resolves the runfiles
# paths and hands them over.
#
# argv (supplied via the `args` attribute, see //bazel:defs.bzl):
#   $1 = rlocationpath of the kit executable
#   $2 = rlocationpath of the .kit app config
#   $3 = "-" or the rlocationpath of a python script to run via kit --exec
#   $4 = "-" or colon-separated runfiles paths of --ext-folder entries. Each is
#        either a directory, or a file inside the directory to use (the prebuilt
#        extensions are staged as runfiles, so their folder is not an artifact).
#   $5 = "-" or colon-separated rlocationpaths of .kit fragments to layer on
#        with --merge-config (applied in order)
#   $6 = "-" or a string that must appear in Kit's output for the run to count
#        as successful (used by the launch tests)
#   $7 = "-" or a string that must NOT appear in it
# Everything after that is forwarded to kit, so `bazel run //:isaacsim -- --foo`
# works.

# --- begin runfiles.bash initialization v3 ---
set -uo pipefail
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  { echo >&2 "ERROR: cannot locate bazel runfiles library"; exit 1; }
# --- end runfiles.bash initialization v3 ---
set -e

kit_bin="$(rlocation "$1")"; shift
app_cfg="$(rlocation "$1")"; shift
exec_script_path="$1"; shift
ext_folders="$1"; shift
merge_configs="$1"; shift
expect_output="$1"; shift
reject_output="$1"; shift

# Kit's embedded CPython would otherwise compile its own stdlib into the kernel's
# Bazel repository; see //bazel/private:kit_repo.bzl, which takes write
# permission away for the same reason.
export PYTHONDONTWRITEBYTECODE=1

if [[ -z "${kit_bin}" || ! -x "${kit_bin}" ]]; then
  echo >&2 "ERROR: kit executable not found in runfiles"; exit 1
fi
if [[ -z "${app_cfg}" || ! -f "${app_cfg}" ]]; then
  echo >&2 "ERROR: .kit app config not found in runfiles"; exit 1
fi

kit_args=("${app_cfg}")

if [[ "${ext_folders}" != "-" ]]; then
  IFS=':' read -r -a _folders <<< "${ext_folders}"
  for rel in "${_folders[@]}"; do
    [[ -n "${rel}" ]] || continue
    path="$(rlocation "${rel}")"
    if [[ -z "${path}" || ! -e "${path}" ]]; then
      echo >&2 "ERROR: ext-folder not found in runfiles: ${rel}"; exit 1
    fi
    [[ -d "${path}" ]] || path="$(dirname "${path}")"
    kit_args+=("--ext-folder" "${path}")
  done
fi

if [[ "${merge_configs}" != "-" ]]; then
  IFS=':' read -r -a _merges <<< "${merge_configs}"
  for rel in "${_merges[@]}"; do
    [[ -n "${rel}" ]] || continue
    merge_config="$(rlocation "${rel}")"
    if [[ -z "${merge_config}" || ! -f "${merge_config}" ]]; then
      echo >&2 "ERROR: merge config not found in runfiles: ${rel}"; exit 1
    fi
    kit_args+=("--merge-config=${merge_config}")
  done
fi

if [[ "${exec_script_path}" != "-" ]]; then
  script="$(rlocation "${exec_script_path}")"
  if [[ -z "${script}" || ! -f "${script}" ]]; then
    echo >&2 "ERROR: exec script not found in runfiles: ${exec_script_path}"; exit 1
  fi
  kit_args+=("--exec" "${script}")
fi

# Kit derives its data, cache and log directories from HOME. Under `bazel test`
# that has to be the test's own scratch directory: not just so concurrent tests
# do not share mutable state, but so that a registry download -- if one ever
# happened -- could not land in the developer's ~/.local/share/ov, where the
# next run would find it locally and look hermetic.
if [[ -n "${TEST_TMPDIR:-}" ]]; then
  HOME="${TEST_TMPDIR}/home"
  export HOME
  mkdir -p "${HOME}"
  kit_args+=(
    "--/log/outputStreamLevel=Warning"
    # Kit's hang detector asks, through zenity, whether to terminate and send a
    # report. A test has nobody to ask and no desktop session to ask on; let the
    # test timeout be what decides.
    "--/app/hangDetector/enabled=false"
    "--/crashreporter/enabled=false"
  )
fi

if [[ "${expect_output}" == "-" ]]; then
  exec "${kit_bin}" "${kit_args[@]}" "$@"
fi

# Assertion mode: keep Kit's output visible, then require the sentinel. Kit can
# exit non-zero on shutdown after a successful run (it tears down GPU state
# late), so the sentinel -- not the exit code -- is what the test checks.
out="${TEST_TMPDIR:-${TMPDIR:-/tmp}}/kit-output.txt"
status=0
"${kit_bin}" "${kit_args[@]}" "$@" 2>&1 | tee "${out}" || status=$?
if ! grep -qF -- "${expect_output}" "${out}"; then
  echo >&2 "FAIL: expected output not found: ${expect_output}"
  echo >&2 "      kit exited with status ${status}"
  exit 1
fi

# Kit reaching "app ready" says nothing about the extensions that failed on the
# way: a module it could not import is logged and stepped over. A healthy run
# logs no errors at all, so any is a failure.
if [[ "${reject_output}" != "-" ]]; then
  if grep -qF -- "${reject_output}" "${out}"; then
    echo >&2 "FAIL: output contains ${reject_output}:"
    grep -F -- "${reject_output}" "${out}" | head -20 >&2
    exit 1
  fi
fi
echo "OK: found ${expect_output}"
