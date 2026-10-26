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
    all_defs_lines = []
    for k, v in additional.items():
        all_defs_lines.append("#define %s %s" % (k, v))
    for def_ in defs:
        all_defs_lines.append("#define %s 1" % def_)
    for key, value in mappings.items():
        all_defs_lines.append("#define %s %s" % (key, value))
    all_defs = "\n".join(all_defs_lines)
    if src == None:
        ctx.actions.write(
            output = out,
            content = "#pragma once\n" + all_defs + "\n",
        )
    else:
        # Only substitute @DEFS@ — do NOT add per-key substitutions.
        # Per-key substitutions (#define KEY 0 -> #define KEY VALUE) cause
        # double-substitution: expand_template applies them sequentially, so
        # the @DEFS@ result (already containing "#define KEY VAL") is
        # re-matched by "#define KEY 0" when VAL starts with "0" (e.g. 0x3a),
        # producing "#define KEY 0x3aVAL" -> "invalid suffix" compiler error.
        ctx.actions.expand_template(
            template = src,
            output = out,
            substitutions = {"@DEFS@": all_defs},
        )
    return [DefaultInfo(
        files = depset([out]),
    )]
pseudo_configure = rule(
    doc = "Perform a fake 'configure' step on a file.",
    implementation = _pseudo_configure_impl,
    attrs = {
        "additional": attr.string_dict(
            doc = "Optional mapping of definitions to prepend to the file.",
            default = {},
        ),
        "defs": attr.string_list(
            doc = "List of definitions to #define as `1`.",
            default = [],
        ),
        "mappings": attr.string_dict(
            doc = "Mapping of definitions with non-trivial values.",
            default = {},
        ),
        "out": attr.output(
            doc = "Path to place the output file contents.",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "`.in` file to transform.",
            allow_single_file = True,
        ),
    },
)
