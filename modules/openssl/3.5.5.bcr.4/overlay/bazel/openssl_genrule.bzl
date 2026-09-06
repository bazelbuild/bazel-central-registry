"""OpenSSL Perl template processing at build time.

Generates platform-independent files from OpenSSL's .h.in templates,
DER table generators, progs.pl, and mkbuildinf.pl. Template processing
is batched into a single Perl invocation via batch_dofile to avoid
per-template process-creation overhead on Windows. Uses redirect_stdout
for single-output actions (mkbuildinf, progs).
"""

# Fixed epoch for SOURCE_DATE_EPOCH to ensure reproducible timestamps.
_HERMETIC_ENV = {"SOURCE_DATE_EPOCH": "443779200"}

_DOFILE_HDR_TEMPLATES = {
    "include/crypto/bn_conf.h.in": "include/crypto/bn_conf.h",
    "include/crypto/dso_conf.h.in": "include/crypto/dso_conf.h",
    "include/internal/param_names.h.in": "include/internal/param_names.h",
    "include/openssl/asn1.h.in": "include/openssl/asn1.h",
    "include/openssl/asn1t.h.in": "include/openssl/asn1t.h",
    "include/openssl/bio.h.in": "include/openssl/bio.h",
    "include/openssl/cmp.h.in": "include/openssl/cmp.h",
    "include/openssl/cms.h.in": "include/openssl/cms.h",
    "include/openssl/comp.h.in": "include/openssl/comp.h",
    "include/openssl/conf.h.in": "include/openssl/conf.h",
    "include/openssl/configuration.h.in": "include/openssl/configuration.h",
    "include/openssl/core_names.h.in": "include/openssl/core_names.h",
    "include/openssl/crmf.h.in": "include/openssl/crmf.h",
    "include/openssl/crypto.h.in": "include/openssl/crypto.h",
    "include/openssl/ct.h.in": "include/openssl/ct.h",
    "include/openssl/err.h.in": "include/openssl/err.h",
    "include/openssl/ess.h.in": "include/openssl/ess.h",
    "include/openssl/fipskey.h.in": "include/openssl/fipskey.h",
    "include/openssl/lhash.h.in": "include/openssl/lhash.h",
    "include/openssl/ocsp.h.in": "include/openssl/ocsp.h",
    "include/openssl/opensslv.h.in": "include/openssl/opensslv.h",
    "include/openssl/pkcs12.h.in": "include/openssl/pkcs12.h",
    "include/openssl/pkcs7.h.in": "include/openssl/pkcs7.h",
    "include/openssl/safestack.h.in": "include/openssl/safestack.h",
    "include/openssl/srp.h.in": "include/openssl/srp.h",
    "include/openssl/ssl.h.in": "include/openssl/ssl.h",
    "include/openssl/ui.h.in": "include/openssl/ui.h",
    "include/openssl/x509.h.in": "include/openssl/x509.h",
    "include/openssl/x509_acert.h.in": "include/openssl/x509_acert.h",
    "include/openssl/x509_vfy.h.in": "include/openssl/x509_vfy.h",
    "include/openssl/x509v3.h.in": "include/openssl/x509v3.h",
}

_DOFILE_DER_HDR_TEMPLATES = {
    "providers/common/include/prov/der_digests.h.in": "providers/common/include/prov/der_digests.h",
    "providers/common/include/prov/der_dsa.h.in": "providers/common/include/prov/der_dsa.h",
    "providers/common/include/prov/der_ec.h.in": "providers/common/include/prov/der_ec.h",
    "providers/common/include/prov/der_ecx.h.in": "providers/common/include/prov/der_ecx.h",
    "providers/common/include/prov/der_ml_dsa.h.in": "providers/common/include/prov/der_ml_dsa.h",
    "providers/common/include/prov/der_rsa.h.in": "providers/common/include/prov/der_rsa.h",
    "providers/common/include/prov/der_slh_dsa.h.in": "providers/common/include/prov/der_slh_dsa.h",
    "providers/common/include/prov/der_sm2.h.in": "providers/common/include/prov/der_sm2.h",
    "providers/common/include/prov/der_wrap.h.in": "providers/common/include/prov/der_wrap.h",
}

_DOFILE_SRC_TEMPLATES = {
    "crypto/params_idx.c.in": "crypto/params_idx.c",
}

_DOFILE_DER_SRC_TEMPLATES = {
    "providers/common/der/der_digests_gen.c.in": "providers/common/der/der_digests_gen.c",
    "providers/common/der/der_dsa_gen.c.in": "providers/common/der/der_dsa_gen.c",
    "providers/common/der/der_ec_gen.c.in": "providers/common/der/der_ec_gen.c",
    "providers/common/der/der_ecx_gen.c.in": "providers/common/der/der_ecx_gen.c",
    "providers/common/der/der_ml_dsa_gen.c.in": "providers/common/der/der_ml_dsa_gen.c",
    "providers/common/der/der_rsa_gen.c.in": "providers/common/der/der_rsa_gen.c",
    "providers/common/der/der_slh_dsa_gen.c.in": "providers/common/der/der_slh_dsa_gen.c",
    "providers/common/der/der_sm2_gen.c.in": "providers/common/der/der_sm2_gen.c",
    "providers/common/der/der_wrap_gen.c.in": "providers/common/der/der_wrap_gen.c",
}

def _run_dofile(ctx, out_files_list):
    """Run batch_dofile once for all templates."""
    inputs = []
    outputs = []
    args = ctx.actions.args()

    for target, output in ctx.attr.templates_map.items():
        template_file = target.files.to_list()[0]
        out_file = ctx.actions.declare_file(output)
        inputs.append(template_file)
        outputs.append(out_file)
        out_files_list.append(out_file)
        args.add("--in=" + template_file.path)
        args.add("--out=" + out_file.path)

    ctx.actions.run(
        executable = ctx.executable._batch_dofile,
        arguments = [args],
        inputs = inputs,
        outputs = outputs,
        mnemonic = "OpenSSLDofile",
        progress_message = "Generating %d template files" % len(outputs),
    )

def _run_progs(ctx, flag, out_path):
    """Run the progs_gen perl_binary via redirect_stdout."""
    out = ctx.actions.declare_file(out_path)
    args = ctx.actions.args()
    args.add(ctx.executable._progs_gen)
    args.add(out)
    args.add("--")
    args.add(flag)
    args.add("apps/openssl")
    ctx.actions.run(
        executable = ctx.executable._redirect_stdout,
        arguments = [args],
        outputs = [out],
        tools = [
            ctx.attr._progs_gen[DefaultInfo].files_to_run,
        ],
        env = _HERMETIC_ENV,
        mnemonic = "OpenSSLProgs",
        progress_message = "Generating %s" % out.short_path,
    )
    return out

def _openssl_gen_impl(ctx):
    crypto_outs = []
    app_outs = []

    if ctx.attr.mode == "hdrs":
        _run_dofile(ctx, crypto_outs)

        buildinf = ctx.actions.declare_file("crypto/buildinf.h")
        crypto_outs.append(buildinf)
        buildinf_args = ctx.actions.args()
        buildinf_args.add(ctx.executable._mkbuildinf)
        buildinf_args.add(buildinf)
        buildinf_args.add("--")
        buildinf_args.add("bazel")
        buildinf_args.add("bazel")
        ctx.actions.run(
            executable = ctx.executable._redirect_stdout,
            arguments = [buildinf_args],
            outputs = [buildinf],
            tools = [
                ctx.attr._mkbuildinf[DefaultInfo].files_to_run,
            ],
            env = _HERMETIC_ENV,
            mnemonic = "OpenSSLBuildinf",
            progress_message = "Generating %s" % buildinf.short_path,
        )

        app_outs.append(_run_progs(ctx, "-H", "apps/progs.h"))

    elif ctx.attr.mode == "srcs":
        _run_dofile(ctx, crypto_outs)

        app_outs.append(_run_progs(ctx, "-C", "apps/progs.c"))

    return [
        DefaultInfo(files = depset(crypto_outs)),
        OutputGroupInfo(app = depset(app_outs)),
    ]

_openssl_gen = rule(
    implementation = _openssl_gen_impl,
    doc = """Generates OpenSSL headers and sources from Perl templates at build time.

In "hdrs" mode: processes .h.in dofile templates, generates crypto/buildinf.h,
and produces apps/progs.h (in the "app" output group).

In "srcs" mode: processes .c.in dofile templates and produces apps/progs.c
(in the "app" output group).

Template outputs go into DefaultInfo; app outputs go into OutputGroupInfo("app").""",
    attrs = {
        "mode": attr.string(
            mandatory = True,
            values = ["hdrs", "srcs"],
            doc = "Generation mode: 'hdrs' for headers + buildinf + progs.h, " +
                  "'srcs' for sources + progs.c.",
        ),
        "templates_map": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Map of .in template file labels to their canonical output paths.",
        ),
        "_batch_dofile": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//bazel:batch_dofile"),
        ),
        "_mkbuildinf": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//:mkbuildinf"),
        ),
        "_progs_gen": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//:progs_gen"),
        ),
        "_redirect_stdout": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//bazel:redirect_stdout"),
        ),
    },
)

def openssl_perl_genrule(*, name, mode = None, **kwargs):
    """Generate platform-independent OpenSSL files from Perl templates.

    Args:
        name: Target name.
        mode: "hdrs" or "srcs". If None, inferred from name suffix.
        **kwargs: Additional keyword arguments.
    """
    if mode == None:
        if name.endswith("_hdrs"):
            mode = "hdrs"
        elif name.endswith("_srcs"):
            mode = "srcs"
        else:
            fail("Cannot infer mode from name '{}'; pass mode explicitly".format(name))

    if mode == "hdrs":
        templates = {}
        templates.update(_DOFILE_HDR_TEMPLATES)
        templates.update(_DOFILE_DER_HDR_TEMPLATES)
        _openssl_gen(
            name = name,
            mode = "hdrs",
            templates_map = templates,
            **kwargs
        )
    elif mode == "srcs":
        templates = {}
        templates.update(_DOFILE_SRC_TEMPLATES)
        templates.update(_DOFILE_DER_SRC_TEMPLATES)
        _openssl_gen(
            name = name,
            mode = "srcs",
            templates_map = templates,
            **kwargs
        )
    else:
        fail("mode must be 'hdrs' or 'srcs', got: " + mode)
