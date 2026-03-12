# objc.bzl

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _objc_rename_impl(ctx):
    outputs = []
    for f in ctx.files.srcs:
        if f.extension in ["m", "mm"]:
            # 为 .m/.mm 生成一个 .c/.cc 的存根文件
            ext = ".c" if f.extension == "m" else ".cc"
            out = ctx.actions.declare_file(f.basename + ext)
            
            # 计算相对于仓库根目录的路径
            # 如果是外部仓库，f.path 以 external/repo_name/ 开头
            # 我们需要去掉这个前缀，因为仓库根目录已经在搜索路径中了
            include_path = f.path
            workspace_root = f.owner.workspace_root
            if workspace_root:
                prefix = workspace_root + "/"
                if include_path.startswith(prefix):
                    include_path = include_path[len(prefix):]

            # 存根内容仅包含对原始文件的引用
            ctx.actions.write(
                output = out,
                content = '#include "%s"\n' % include_path,
            )
            outputs.append(out)
    return [DefaultInfo(files = depset(outputs))]

_objc_rename = rule(
    implementation = _objc_rename_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
)

def _objc_common(name, rule_fn, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    # 检测是否包含 Objective-C++
    has_mm = False
    if type(srcs) == "list":
        has_mm = any([s.endswith(".mm") for s in srcs])
    lang = "objective-c++" if has_mm else "objective-c"

    # 生成存根文件
    _objc_rename(
        name = name + "_stubs",
        srcs = srcs,
    )

    rule_fn(
        name = name,
        srcs = [":" + name + "_stubs"],
        # 将原始源码和头文件都作为 textual_hdrs 传入，确保它们在编译存根时在沙盒中可用
        textual_hdrs = srcs + hdrs,
        deps = deps,
        copts = copts + ["-x", lang, "-fobjc-arc"],
        **kwargs
    )

def objc_library(name, **kwargs):
    _objc_common(name, cc_library, **kwargs)

def objc_binary(name, **kwargs):
    _objc_common(name, cc_binary, **kwargs)

def objc_test(name, **kwargs):
    _objc_common(name, cc_test, **kwargs)
