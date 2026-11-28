#!/bin/sh
# Registration smoke test. No commands open /dev/kvm or look up tools on PATH.
set -eu
export LC_ALL=C
qemu=./$1

version=$("$qemu" --version)
case "$version" in
    'QEMU emulator version 11.1.2
'*) ;;
    *) printf 'Unexpected version: %s\n' "$version" >&2; exit 1 ;;
esac
accelerators=$("$qemu" -accel help)
case "$accelerators" in
    'Accelerators supported in QEMU binary:
kvm') ;;
    *) printf 'Unexpected accelerators: %s\n' "$accelerators" >&2; exit 1 ;;
esac

check_help() {
    output=$("$qemu" "$1" help)
    case "$output" in
        *"$2"*) ;;
        *) printf 'Missing entry from %s help: %s\n' "$1" "$2" >&2; exit 1 ;;
    esac
}

check_machines() {
    machines=$("$qemu" -machine help)
    q35=absent
    i440fx=absent
    while read -r name rest; do
        case "$name" in
            q35) q35=present ;;
            pc|pc-i440fx-*) i440fx=present ;;
        esac
    done <<EOF
$machines
EOF
    if [ "$q35" != present ] || [ "$i440fx" != "$1" ]; then
        printf 'Expected q35 present and i440FX %s; got:\n%s\n' "$1" "$machines" >&2
        exit 1
    fi
}

case "$2" in
    q35-only) check_machines absent ;;
    qemu-default) check_machines present ;;
    custom) ;;
    *) printf 'Unexpected device set: %s\n' "$2" >&2; exit 1 ;;
esac
check_help -device 'name "isa-serial"'
check_help -trace handle_hmp_command
