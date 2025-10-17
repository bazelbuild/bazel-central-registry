# `umoci`

Generate overlay with:

```console
$ bazelisk run -- @gazelle//cmd/gazelle update --external vendored
$ buildozer -f - <<'EOF'
set name umoci_lib|//:umoci
replace deps //:umoci //:umoci_lib|//cmd/umoci
replace embed :umoci :umoci_lib|//:lib_test
new alias umoci|//:__pkg__
set actual //cmd/umoci|//:umoci
set visibility //visibility:public|//:umoci
EOF
```
