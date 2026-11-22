#!/bin/sh
# usage: configure_commands.sh CONFIGURE_AC TAG [NAME=VALUE...]
# Runs the body of configure.ac's AC_CONFIG_COMMANDS([TAG], ...) with ${objroot} empty and the given
# variables, then prints the file TAG it writes.

set -e

ac="$1"
tag="$2"
shift 2
for assignment; do
  export "${assignment}"
done

body="$(awk -v tag="${tag}" '
  $0 == "AC_CONFIG_COMMANDS([" tag "], [" { on = 1; next }
  on && /^\], \[/ { exit }
  on && $1 != "dnl" { gsub(/\$\[\]/, "$"); print }
' "${ac}")"
if [ -z "${body}" ]; then
  echo "${ac}: no AC_CONFIG_COMMANDS([${tag}])" >&2
  exit 1
fi

objroot=
eval "${body}"
cat "${tag}"
