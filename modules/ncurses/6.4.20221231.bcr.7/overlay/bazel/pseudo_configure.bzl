# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Fake configuration step for hacky substitutions in ".in" files."""

def _pseudo_configure_impl(ctx):
    additional = ctx.attr.additional
    mappings = ctx.attr.mappings
    defs = ctx.attr.defs
    out = ctx.outputs.out
    src = ctx.file.src if ctx.attr.src else None
    out = ctx.outputs.out

    cmd = ""

    if src == None:
        cmd += "echo '#pragma once' >> %s &&" % (out.path)

    for k, v in additional.items():
        cmd += "echo '#define %s %s' >> %s &&" % (k, v, out.path)

    if src != None:
        cmd += "cat " + src.path
    else:
        cmd += "echo"
    all_defs = ""
    for def_ in defs:
        cmd += r"| sed 's/#\s*undef \b\(" + def_ + r"\)\b/#define \1 1/'"
        all_defs += "#define " + def_ + " 1\\n"
    for key, value in mappings.items():
        cmd += r"| sed 's/#\s*undef \b" + key + r"\b/#define " + str(key) + " " + str(value) + "/'"
        cmd += r"| sed 's/#\s*define \b\(" + key + r"\)\b 0/#define \1 " + str(value) + "/'"
        all_defs += "#define " + key + " " + value + "\\n"
    cmd += r"| sed 's/\@DEFS\@/" + all_defs + "/'"
    cmd += " >> " + out.path

    ctx.actions.run_shell(
        mnemonic = "NCursesPseudoConfigure",
        inputs = [src] if src != None else [],
        outputs = [out],
        command = cmd,
    )

    return [DefaultInfo(
        files = depset([out])
    )]

pseudo_configure = rule(
    doc = "Perform a fake 'configure' step on a file.",
    implementation = _pseudo_configure_impl,
    attrs = {
        "src": attr.label(
            doc = "`.in` file to transform.",
            allow_single_file = True,
        ),
        "out": attr.output(
            doc = "Path to place the output file contents.",
            mandatory = True,
        ),
        "defs": attr.string_list(
            doc = "List of definitions to #define as `1`.",
            default = [],
        ),
        "mappings": attr.string_dict(
            doc = "Mapping of definitions with non-trivial values.",
            default = {},
        ),
        "additional": attr.string_dict(
            doc = "Optional mapping of definitions to prepend to the file.",
            default = {},
        ),
    },
)
