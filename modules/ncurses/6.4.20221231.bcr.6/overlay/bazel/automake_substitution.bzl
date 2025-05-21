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

"""Provides helper that replaces @VARIABLE_NAME@ occurrences with values, as
specified by a provided map."""

def _automake_substitution_impl(ctx):

    substitutions = ctx.attr.substitutions
    substitution_pipe = " ".join([
        "| sed 's/@%s@/%s/g'" % (variable_name, value)
        for variable_name, value in substitutions.items()
    ])

    output = ctx.outputs.out
    ctx.actions.run_shell(
        mnemonic = "NCursesAutomakeSubstitution",
        inputs = [ctx.file.src],
        outputs = [output],
        command = "cat %s %s > %s" % (ctx.file.src.path, substitution_pipe, output.path),
        use_default_shell_env = True,
    )

    return [DefaultInfo(
        files = depset([output])
    )]

automake_substitution = rule(
    doc = """\
Replaces @VARIABLE_NAME@ occurrences with values.

Note: The current implementation does not allow slashes in variable
values.
""",
    implementation = _automake_substitution_impl,
    attrs = {
        "src": attr.label(
            doc = "The source file to modify",
            allow_single_file = True,
            mandatory = True,
        ),
        "out": attr.output(
            doc = "The output file.",
            mandatory = True,
        ),
        "substitutions": attr.string_dict(
            doc = "Substitutions to apply.",
            default = {},
        )
    }
)
