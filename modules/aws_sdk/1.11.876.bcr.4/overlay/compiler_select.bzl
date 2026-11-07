def compiler_select(values):
    if "gcc" not in values:
        fail("Need to handle gcc!", "values")
    if "clang" not in values:
        fail("Need to handle clang!", "values")
    return select({
        "@rules_cc//cc/compiler:gcc": values["gcc"],
        "@rules_cc//cc/compiler:clang": values["clang"],
    })
