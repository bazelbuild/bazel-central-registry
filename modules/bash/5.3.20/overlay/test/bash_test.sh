#!/usr/bin/env sh
# Runs a few commands with the bash built from source.

set -eu

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# Usage: check <expected output> <bash arguments>...
check() {
  expected="$1"
  shift
  actual="$("$BASH_UNDER_TEST" "$@")" || fail "exit code $? for: $*"
  [ "$actual" = "$expected" ] || fail "expected '$expected', got '$actual' for: $*"
}

check "5.3.20(1)-release" -c 'echo "$BASH_VERSION"'
check "1 2" -c 'declare -A m=([a]=1 [b]=2); echo "${m[a]} ${m[b]}"'
check "3" -c 'a=(x y z); echo "${#a[@]}"'
check "HELLO" -c 'v=hello; echo "${v^^}"'
check "6" -c 'echo $(( (1 + 2) * 2 ))'
check "1 2 3" -c 'echo {1..3}'
check "from subshell" -c 'echo "$(echo from subshell)"'
check "x y" -c 'read -r a b <<< "x y"; echo "$a $b"'
check "foo" -c 'while read -r line; do echo "$line"; done < <(echo foo)'
check "a.txt b.txt" -c 'cd "$(mktemp -d)" && touch b.txt a.txt c.log && echo *.txt'
check "match" -c 'shopt -s extglob; [[ abc == @(a|x)* ]] && echo match'
check "2024" -c '[[ 2024-01-02 =~ ^([0-9]+)- ]] && echo "${BASH_REMATCH[1]}"'
# Signal names are determined at runtime.
check "TERM" -c 'kill -l 15'
check "trap -- '' SIGINT trap -- '' SIGTERM" -c 'trap "" TERM INT; echo $(trap -p)'
check "printf 42" -c 'printf "%s %d\n" printf 42'
check "/" -c 'cd / && pwd'

status=0
"$BASH_UNDER_TEST" -c 'exit 42' || status=$?
[ "$status" -eq 42 ] || fail "expected exit status 42, got $status"

echo "PASS"
