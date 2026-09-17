#!/usr/bin/env bash
set -euo pipefail

readonly commit="f337e600741638896fb6056ce87c6479f74b89a3"
readonly expected_sha256="aba7ae76ecfc18e895f6f40c39d2b0bdd330aa535bb8bf9703d08b13772be6d0"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly scratch_dir="$(mktemp -d "${TMPDIR:-/tmp}/apple-mig-parser.XXXXXX")"
readonly archive="${scratch_dir}/bootstrap_cmds.tar.gz"
readonly source_dir="${scratch_dir}/bootstrap_cmds-${commit}"
readonly output_dir="${script_dir}/migcom"

cleanup() {
    rm -rf "${scratch_dir}"
}
trap cleanup EXIT

if [[ "$(/usr/bin/bison --version | head -1)" != "bison (GNU Bison) 2.3" ]]; then
    echo "Apple's bison 2.3 is required to reproduce the checked-in MIG parser" >&2
    exit 1
fi
if [[ "$(/usr/bin/flex --version)" != "flex 2.6.4 Apple(flex-35)" ]]; then
    echo "Apple flex 2.6.4 (flex-35) is required to reproduce the checked-in MIG lexer" >&2
    exit 1
fi

curl -L --fail --silent --show-error \
    "https://github.com/markmentovai/bootstrap_cmds/archive/${commit}.tar.gz" \
    -o "${archive}"
actual_sha256="$(shasum -a 256 "${archive}" | awk '{print $1}')"
if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
    echo "archive checksum mismatch: ${actual_sha256}" >&2
    exit 1
fi

tar -xzf "${archive}" -C "${scratch_dir}"
(
    cd "${source_dir}/migcom.tproj"
    /usr/bin/bison -d -o parser.c parser.y
    /usr/bin/flex -o lexxer.c lexxer.l
)

mkdir -p "${output_dir}"
for parser_file in lexxer.c parser.c parser.h; do
    cp "${source_dir}/migcom.tproj/${parser_file}" "${output_dir}/${parser_file}"
done
