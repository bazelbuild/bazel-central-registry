load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_python//python:py_runtime_pair.bzl", "py_runtime_pair")
load("@rules_python//python/cc:py_cc_toolchain.bzl", "py_cc_toolchain")
load("@bazel_skylib//rules:common_settings.bzl", "bool_setting")
load("//bazel:utils.bzl", "external_prefix")

py_runtime(
    name = "py_runtime",
    files = [":runtime"],
    interpreter = ":bin/python",
    python_version = "PY3",
)

py_runtime_pair(
    name = "py_runtime_pair",
    py3_runtime = ":py_runtime",
)

toolchain(
    name = "toolchain",
    toolchain = ":py_runtime_pair",
    toolchain_type = "@rules_python//python:toolchain_type",
    target_settings = [":bootstrap_disabled"],
)

py_cc_toolchain(
    name = "py_cc_toolchain",
    headers = ":headers",
    python_version = "3.12",
)

toolchain(
    name = "cc_toolchain",
    toolchain = ":py_cc_toolchain",
    toolchain_type = "@rules_python//python/cc:toolchain_type",
    target_settings = [":bootstrap_disabled"],
)

bool_setting(
    name ="cpython_bootstrap",
    build_setting_default = False,
)

config_setting(
    name = "bootstrap_disabled",
    flag_values = {":cpython_bootstrap": "False"},
)

config_setting(
    name = "bootstrap_enabled",
    flag_values = {":cpython_bootstrap": "True"},
)

# Everything within or depending on Python will need these flags.
PY_COPTS = [
    "-fwrapv",
    "-fno-omit-frame-pointer",
    "-mno-omit-leaf-frame-pointer",
    "-I%sInclude" % (external_prefix(),),
    "-I%sInclude/internal" % (external_prefix(),),
    "-I$(GENDIR)/%sInclude" % (external_prefix(),),
]

CORE_DEFINES = [
    '-DVERSION=\\"3.12\\"',
    '-DVPATH=\\"%s\\"' % (external_prefix(),),
    '-DPREFIX=\\"/usr\\"',
    '-DEXEC_PREFIX=\\"/usr\\"',
    '-DPYTHONPATH=\\":plat-linux:lib-tk:lib-old\\"',
    '-DPLATFORM=\\"linux\\"',
    '-DSOABI=\\"cpython-312-x86_64-linux-gnu\\"',
    '-DABIFLAGS=\\"\\"',
    '-DPLATLIBDIR=\\"lib\\"',
]

# Flags for building the core python executable (i.e., not a shared extension).
CORE_COPTS = PY_COPTS + CORE_DEFINES + [
    "-DPy_BUILD_CORE",
]

# Flags for building builtin extensions.
CORE_BUILTIN_COPTS = PY_COPTS + CORE_DEFINES + [
    "-DPy_BUILD_CORE_BUILTIN",
]

PUBLIC_PYTHON_HEADERS = [
    ":Include/pyconfig.h",
    "Include/Python.h",
    "Include/abstract.h",
    "Include/bltinmodule.h",
    "Include/boolobject.h",
    "Include/bytearrayobject.h",
    "Include/bytesobject.h",
    "Include/ceval.h",
    "Include/codecs.h",
    "Include/compile.h",
    "Include/complexobject.h",
    "Include/datetime.h",
    "Include/descrobject.h",
    "Include/dictobject.h",
    "Include/dynamic_annotations.h",
    "Include/enumobject.h",
    "Include/errcode.h",
    "Include/exports.h",
    "Include/fileobject.h",
    "Include/fileutils.h",
    "Include/floatobject.h",
    "Include/frameobject.h",
    "Include/genericaliasobject.h",
    "Include/import.h",
    "Include/interpreteridobject.h",
    "Include/intrcheck.h",
    "Include/iterobject.h",
    "Include/listobject.h",
    "Include/longobject.h",
    "Include/marshal.h",
    "Include/memoryobject.h",
    "Include/methodobject.h",
    "Include/modsupport.h",
    "Include/moduleobject.h",
    "Include/object.h",
    "Include/objimpl.h",
    "Include/opcode.h",
    "Include/osdefs.h",
    "Include/osmodule.h",
    "Include/patchlevel.h",
    "Include/py_curses.h",
    "Include/pybuffer.h",
    "Include/pycapsule.h",
    "Include/pydtrace.h",
    "Include/pyerrors.h",
    "Include/pyexpat.h",
    "Include/pyframe.h",
    "Include/pyhash.h",
    "Include/pylifecycle.h",
    "Include/pymacconfig.h",
    "Include/pymacro.h",
    "Include/pymath.h",
    "Include/pymem.h",
    "Include/pyport.h",
    "Include/pystate.h",
    "Include/pystats.h",
    "Include/pystrcmp.h",
    "Include/pystrtod.h",
    "Include/pythonrun.h",
    "Include/pythread.h",
    "Include/pytypedefs.h",
    "Include/rangeobject.h",
    "Include/setobject.h",
    "Include/sliceobject.h",
    "Include/structmember.h",
    "Include/structseq.h",
    "Include/sysmodule.h",
    "Include/traceback.h",
    "Include/tracemalloc.h",
    "Include/tupleobject.h",
    "Include/typeslots.h",
    "Include/unicodeobject.h",
    "Include/warnings.h",
    "Include/weakrefobject.h",
]

PUBLIC_CPYTHON_HEADERS = [
    "Include/cpython/abstract.h",
    "Include/cpython/bytearrayobject.h",
    "Include/cpython/bytesobject.h",
    "Include/cpython/cellobject.h",
    "Include/cpython/ceval.h",
    "Include/cpython/classobject.h",
    "Include/cpython/code.h",
    "Include/cpython/compile.h",
    "Include/cpython/complexobject.h",
    "Include/cpython/context.h",
    "Include/cpython/descrobject.h",
    "Include/cpython/dictobject.h",
    "Include/cpython/fileobject.h",
    "Include/cpython/fileutils.h",
    "Include/cpython/floatobject.h",
    "Include/cpython/frameobject.h",
    "Include/cpython/funcobject.h",
    "Include/cpython/genobject.h",
    "Include/cpython/import.h",
    "Include/cpython/initconfig.h",
    "Include/cpython/interpreteridobject.h",
    "Include/cpython/listobject.h",
    "Include/cpython/longintrepr.h",
    "Include/cpython/longobject.h",
    "Include/cpython/memoryobject.h",
    "Include/cpython/methodobject.h",
    "Include/cpython/modsupport.h",
    "Include/cpython/object.h",
    "Include/cpython/objimpl.h",
    "Include/cpython/odictobject.h",
    "Include/cpython/picklebufobject.h",
    "Include/cpython/pyctype.h",
    "Include/cpython/pydebug.h",
    "Include/cpython/pyerrors.h",
    "Include/cpython/pyfpe.h",
    "Include/cpython/pyframe.h",
    "Include/cpython/pylifecycle.h",
    "Include/cpython/pymem.h",
    "Include/cpython/pystate.h",
    "Include/cpython/pythonrun.h",
    "Include/cpython/pythread.h",
    "Include/cpython/pytime.h",
    "Include/cpython/setobject.h",
    "Include/cpython/sysmodule.h",
    "Include/cpython/traceback.h",
    "Include/cpython/tupleobject.h",
    "Include/cpython/unicodeobject.h",
    "Include/cpython/warnings.h",
    "Include/cpython/weakrefobject.h",
]

PRIVATE_PYTHON_HEADERS = [
    "Include/internal/pycore_abstract.h",
    "Include/internal/pycore_asdl.h",
    "Include/internal/pycore_ast.h",
    "Include/internal/pycore_ast_state.h",
    "Include/internal/pycore_atexit.h",
    "Include/internal/pycore_atomic.h",
    "Include/internal/pycore_atomic_funcs.h",
    "Include/internal/pycore_bitutils.h",
    "Include/internal/pycore_blocks_output_buffer.h",
    "Include/internal/pycore_bytes_methods.h",
    "Include/internal/pycore_bytesobject.h",
    "Include/internal/pycore_call.h",
    "Include/internal/pycore_ceval.h",
    "Include/internal/pycore_ceval_state.h",
    "Include/internal/pycore_code.h",
    "Include/internal/pycore_compile.h",
    "Include/internal/pycore_condvar.h",
    "Include/internal/pycore_context.h",
    "Include/internal/pycore_descrobject.h",
    "Include/internal/pycore_dict.h",
    "Include/internal/pycore_dict_state.h",
    "Include/internal/pycore_dtoa.h",
    "Include/internal/pycore_emscripten_signal.h",
    "Include/internal/pycore_exceptions.h",
    "Include/internal/pycore_faulthandler.h",
    "Include/internal/pycore_fileutils.h",
    "Include/internal/pycore_floatobject.h",
    "Include/internal/pycore_flowgraph.h",
    "Include/internal/pycore_format.h",
    "Include/internal/pycore_frame.h",
    "Include/internal/pycore_function.h",
    "Include/internal/pycore_gc.h",
    "Include/internal/pycore_genobject.h",
    "Include/internal/pycore_getopt.h",
    "Include/internal/pycore_gil.h",
    "Include/internal/pycore_global_objects.h",
    "Include/internal/pycore_global_objects_fini_generated.h",
    "Include/internal/pycore_global_strings.h",
    "Include/internal/pycore_hamt.h",
    "Include/internal/pycore_hashtable.h",
    "Include/internal/pycore_import.h",
    "Include/internal/pycore_initconfig.h",
    "Include/internal/pycore_instruments.h",
    "Include/internal/pycore_interp.h",
    "Include/internal/pycore_intrinsics.h",
    "Include/internal/pycore_list.h",
    "Include/internal/pycore_long.h",
    "Include/internal/pycore_memoryobject.h",
    "Include/internal/pycore_moduleobject.h",
    "Include/internal/pycore_namespace.h",
    "Include/internal/pycore_object.h",
    "Include/internal/pycore_object_state.h",
    "Include/internal/pycore_obmalloc.h",
    "Include/internal/pycore_obmalloc_init.h",
    "Include/internal/pycore_opcode.h",
    "Include/internal/pycore_opcode_utils.h",
    "Include/internal/pycore_parser.h",
    "Include/internal/pycore_pathconfig.h",
    "Include/internal/pycore_pyarena.h",
    "Include/internal/pycore_pyerrors.h",
    "Include/internal/pycore_pyhash.h",
    "Include/internal/pycore_pylifecycle.h",
    "Include/internal/pycore_pymath.h",
    "Include/internal/pycore_pymem.h",
    "Include/internal/pycore_pymem_init.h",
    "Include/internal/pycore_pystate.h",
    "Include/internal/pycore_pythread.h",
    "Include/internal/pycore_range.h",
    "Include/internal/pycore_runtime.h",
    "Include/internal/pycore_runtime_init.h",
    "Include/internal/pycore_runtime_init_generated.h",
    "Include/internal/pycore_signal.h",
    "Include/internal/pycore_sliceobject.h",
    "Include/internal/pycore_strhex.h",
    "Include/internal/pycore_structseq.h",
    "Include/internal/pycore_symtable.h",
    "Include/internal/pycore_sysmodule.h",
    "Include/internal/pycore_time.h",
    "Include/internal/pycore_token.h",
    "Include/internal/pycore_traceback.h",
    "Include/internal/pycore_tracemalloc.h",
    "Include/internal/pycore_tuple.h",
    "Include/internal/pycore_typeobject.h",
    "Include/internal/pycore_typevarobject.h",
    "Include/internal/pycore_ucnhash.h",
    "Include/internal/pycore_unicodeobject.h",
    "Include/internal/pycore_unicodeobject_generated.h",
    "Include/internal/pycore_unionobject.h",
    "Include/internal/pycore_warnings.h",
]

PYTHON_HEADERS = PUBLIC_PYTHON_HEADERS + PUBLIC_CPYTHON_HEADERS + PRIVATE_PYTHON_HEADERS

genrule(
    name = "include_public_headers",
    srcs = PUBLIC_PYTHON_HEADERS,
    outs = ["include/python3.12/" + h.partition("/")[2] for h in PUBLIC_PYTHON_HEADERS],
    cmd = "cp $(SRCS) $(RULEDIR)/include/python3.12/",
)

genrule(
    name = "include_public_cpython_headers",
    srcs = PUBLIC_CPYTHON_HEADERS,
    outs = ["include/python3.12/" + h.partition("/")[2] for h in PUBLIC_CPYTHON_HEADERS],
    cmd = "cp $(SRCS) $(RULEDIR)/include/python3.12/cpython",
)

genrule(
    name = "include_private_headers",
    srcs = PRIVATE_PYTHON_HEADERS,
    outs = ["include/python3.12/" + h.partition("/")[2] for h in PRIVATE_PYTHON_HEADERS],
    cmd = "cp $(SRCS) $(RULEDIR)/include/python3.12/internal/",
)

filegroup(
    name = "include_headers",
    srcs = [
        ":include_private_headers",
        ":include_public_cpython_headers",
        ":include_public_headers",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "headers",
    hdrs = PYTHON_HEADERS,
    linkstatic = True,
    visibility = ["//visibility:public"],
)

# All of the builtin extensions that we need from the Modules/ directory.
#
# These need to be a separate target so we can set CORE_BUILTIN_COPTS.
# These are the extensions we need for the freeze_module program.
cc_library(
    name = "builtin_extensions_bootstrap_minimal",
    srcs = [
        "Modules/_io/_iomodule.c",
        "Modules/_io/_iomodule.h",
        "Modules/_io/bufferedio.c",
        "Modules/_io/bytesio.c",
        "Modules/_io/clinic/_iomodule.c.h",
        "Modules/_io/clinic/bufferedio.c.h",
        "Modules/_io/clinic/bytesio.c.h",
        "Modules/_io/clinic/fileio.c.h",
        "Modules/_io/clinic/iobase.c.h",
        "Modules/_io/clinic/stringio.c.h",
        "Modules/_io/clinic/textio.c.h",
        "Modules/_io/clinic/winconsoleio.c.h",
        "Modules/_io/fileio.c",
        "Modules/_io/iobase.c",
        "Modules/_io/stringio.c",
        "Modules/_io/textio.c",
        "Modules/_io/winconsoleio.c",
        "Modules/_tracemalloc.c",
        "Modules/_typingmodule.c",
        "Modules/atexitmodule.c",
        "Modules/clinic/_tracemalloc.c.h",
        "Modules/clinic/_typingmodule.c.h",
        "Modules/clinic/gcmodule.c.h",
        "Modules/clinic/posixmodule.c.h",
        "Modules/clinic/signalmodule.c.h",
        "Modules/faulthandler.c",
        "Modules/gcmodule.c",
        "Modules/posixmodule.c",
        "Modules/posixmodule.h",
        "Modules/signalmodule.c",
        "Modules/timemodule.c",
    ],
    copts = CORE_BUILTIN_COPTS,
    deps = [":headers"],
)

cc_library(
    name = "builtin_extensions",
    srcs = [
        "Modules/_abc.c",
        "Modules/_asynciomodule.c",
        "Modules/_bisectmodule.c",
        "Modules/_bz2module.c",
        "Modules/_codecsmodule.c",
        "Modules/_collectionsmodule.c",
        "Modules/_contextvarsmodule.c",
        "Modules/_cryptmodule.c",
        "Modules/_csv.c",
        "Modules/_curses_panel.c",
        "Modules/_cursesmodule.c",
        "Modules/_datetimemodule.c",
        "Modules/_functoolsmodule.c",
        "Modules/_hacl/Hacl_Hash_MD5.c",
        "Modules/_hacl/Hacl_Hash_MD5.h",
        "Modules/_hacl/Hacl_Hash_SHA1.c",
        "Modules/_hacl/Hacl_Hash_SHA1.h",
        "Modules/_hacl/Hacl_Hash_SHA2.c",
        "Modules/_hacl/Hacl_Hash_SHA2.h",
        "Modules/_hacl/Hacl_Hash_SHA3.c",
        "Modules/_hacl/Hacl_Hash_SHA3.h",
        "Modules/_hacl/Hacl_Streaming_Types.h",
        "Modules/_hacl/internal/Hacl_Hash_MD5.h",
        "Modules/_hacl/internal/Hacl_Hash_SHA1.h",
        "Modules/_hacl/internal/Hacl_Hash_SHA2.h",
        "Modules/_hacl/internal/Hacl_Hash_SHA3.h",
        "Modules/_hacl/python_hacl_namespaces.h",
        "Modules/_hashopenssl.c",
        "Modules/_heapqmodule.c",
        "Modules/_json.c",
        "Modules/_localemodule.c",
        "Modules/_lsprof.c",
        "Modules/_lzmamodule.c",
        "Modules/_math.h",
        "Modules/_multiprocessing/clinic/multiprocessing.c.h",
        "Modules/_multiprocessing/clinic/posixshmem.c.h",
        "Modules/_multiprocessing/clinic/semaphore.c.h",
        "Modules/_multiprocessing/multiprocessing.c",
        "Modules/_multiprocessing/multiprocessing.h",
        "Modules/_multiprocessing/posixshmem.c",
        "Modules/_multiprocessing/semaphore.c",
        "Modules/_opcode.c",
        "Modules/_operator.c",
        "Modules/_pickle.c",
        "Modules/_posixsubprocess.c",
        "Modules/_queuemodule.c",
        "Modules/_randommodule.c",
        "Modules/_sre/clinic/sre.c.h",
        "Modules/_sre/sre.c",
        "Modules/_sre/sre.h",
        "Modules/_sre/sre_constants.h",
        "Modules/_sre/sre_lib.h",
        "Modules/_sre/sre_targets.h",
        "Modules/_ssl.c",
        "Modules/_ssl.h",
        "Modules/_ssl/clinic/cert.c.h",
        "Modules/_ssl_data.h",
        "Modules/_ssl_data_111.h",
        "Modules/_ssl_data_31.h",
        "Modules/_stat.c",
        "Modules/_struct.c",
        "Modules/_testinternalcapi.c",
        "Modules/_threadmodule.c",
        "Modules/_weakref.c",
        "Modules/addrinfo.h",
        "Modules/arraymodule.c",
        "Modules/audioop.c",
        "Modules/binascii.c",
        "Modules/cjkcodecs/_codecs_cn.c",
        "Modules/cjkcodecs/_codecs_hk.c",
        "Modules/cjkcodecs/_codecs_iso2022.c",
        "Modules/cjkcodecs/_codecs_jp.c",
        "Modules/cjkcodecs/_codecs_kr.c",
        "Modules/cjkcodecs/_codecs_tw.c",
        "Modules/cjkcodecs/alg_jisx0201.h",
        "Modules/cjkcodecs/cjkcodecs.h",
        "Modules/cjkcodecs/clinic/multibytecodec.c.h",
        "Modules/cjkcodecs/emu_jisx0213_2000.h",
        "Modules/cjkcodecs/mappings_cn.h",
        "Modules/cjkcodecs/mappings_hk.h",
        "Modules/cjkcodecs/mappings_jisx0213_pair.h",
        "Modules/cjkcodecs/mappings_jp.h",
        "Modules/cjkcodecs/mappings_kr.h",
        "Modules/cjkcodecs/mappings_tw.h",
        "Modules/cjkcodecs/multibytecodec.c",
        "Modules/cjkcodecs/multibytecodec.h",
        "Modules/clinic/_abc.c.h",
        "Modules/clinic/_asynciomodule.c.h",
        "Modules/clinic/_bisectmodule.c.h",
        "Modules/clinic/_bz2module.c.h",
        "Modules/clinic/_codecsmodule.c.h",
        "Modules/clinic/_collectionsmodule.c.h",
        "Modules/clinic/_contextvarsmodule.c.h",
        "Modules/clinic/_cryptmodule.c.h",
        "Modules/clinic/_csv.c.h",
        "Modules/clinic/_curses_panel.c.h",
        "Modules/clinic/_cursesmodule.c.h",
        "Modules/clinic/_datetimemodule.c.h",
        "Modules/clinic/_dbmmodule.c.h",
        "Modules/clinic/_elementtree.c.h",
        "Modules/clinic/_functoolsmodule.c.h",
        "Modules/clinic/_gdbmmodule.c.h",
        "Modules/clinic/_hashopenssl.c.h",
        "Modules/clinic/_heapqmodule.c.h",
        "Modules/clinic/_localemodule.c.h",
        "Modules/clinic/_lsprof.c.h",
        "Modules/clinic/_lzmamodule.c.h",
        "Modules/clinic/_opcode.c.h",
        "Modules/clinic/_operator.c.h",
        "Modules/clinic/_pickle.c.h",
        "Modules/clinic/_posixsubprocess.c.h",
        "Modules/clinic/_queuemodule.c.h",
        "Modules/clinic/_randommodule.c.h",
        "Modules/clinic/_ssl.c.h",
        "Modules/clinic/_statisticsmodule.c.h",
        "Modules/clinic/_struct.c.h",
        "Modules/clinic/_testinternalcapi.c.h",
        "Modules/clinic/_tkinter.c.h",
        "Modules/clinic/_weakref.c.h",
        "Modules/clinic/_winapi.c.h",
        "Modules/clinic/arraymodule.c.h",
        "Modules/clinic/audioop.c.h",
        "Modules/clinic/binascii.c.h",
        "Modules/clinic/cmathmodule.c.h",
        "Modules/clinic/fcntlmodule.c.h",
        "Modules/clinic/grpmodule.c.h",
        "Modules/clinic/itertoolsmodule.c.h",
        "Modules/clinic/mathmodule.c.h",
        "Modules/clinic/md5module.c.h",
        "Modules/clinic/pwdmodule.c.h",
        "Modules/clinic/pyexpat.c.h",
        "Modules/clinic/readline.c.h",
        "Modules/clinic/resource.c.h",
        "Modules/clinic/selectmodule.c.h",
        "Modules/clinic/sha1module.c.h",
        "Modules/clinic/sha2module.c.h",
        "Modules/clinic/sha3module.c.h",
        "Modules/clinic/socketmodule.c.h",
        "Modules/clinic/spwdmodule.c.h",
        "Modules/clinic/symtablemodule.c.h",
        "Modules/clinic/syslogmodule.c.h",
        "Modules/clinic/termios.c.h",
        "Modules/clinic/unicodedata.c.h",
        "Modules/clinic/zlibmodule.c.h",
        "Modules/cmathmodule.c",
        "Modules/errnomodule.c",
        "Modules/fcntlmodule.c",
        "Modules/grpmodule.c",
        "Modules/hashlib.h",
        "Modules/itertoolsmodule.c",
        "Modules/mathmodule.c",
        "Modules/md5module.c",
        "Modules/mmapmodule.c",
        "Modules/pwdmodule.c",
        "Modules/pyexpat.c",
        "Modules/readline.c",
        "Modules/resource.c",
        "Modules/rotatingtree.c",
        "Modules/rotatingtree.h",
        "Modules/selectmodule.c",
        "Modules/sha1module.c",
        "Modules/sha2module.c",
        "Modules/sha3module.c",
        "Modules/socketmodule.c",
        "Modules/socketmodule.h",
        "Modules/spwdmodule.c",
        "Modules/symtablemodule.c",
        "Modules/syslogmodule.c",
        "Modules/termios.c",
        "Modules/unicodedata.c",
        "Modules/unicodedata_db.h",
        "Modules/unicodename_db.h",
        "Modules/xxsubtype.c",
        "Modules/zlibmodule.c",
    ],
    copts = CORE_BUILTIN_COPTS,
    # for Modules/_ssl.c
    textual_hdrs = [
        "Modules/_ssl/debughelpers.c",
        "Modules/_ssl/misc.c",
        "Modules/_ssl/cert.c",
    ],
    deps = [
        ":_blake2",
        ":_ctypes",
        ":_decimal",
        ":_elementtree",
        ":_sqlite3",
        ":_ssl",
        ":builtin_extensions_bootstrap_minimal",
        ":libhacl_headers",
        "@libxcrypt",
        "@zlib",
        "@bzip2//:bz2",
        "@readline",
        "@openssl//:crypto",
        "@openssl//:ssl",
        "@xz//:lzma",
        "@ncurses//:panel",
    ],
)

# We can't use cc_library for this because bin/python needs special copts when it
# compiles these. So we do it multiple times, one for each bootstrap phase.
PYTHON_SRCS = [
    # $(info $$LIBRARY_OBJS is [${LIBRARY_OBJS}]) in Makefile, then translate .o -> .c/.h
    "Objects/abstract.c",
    "Objects/boolobject.c",
    "Objects/bytearrayobject.c",
    "Objects/bytes_methods.c",
    "Objects/bytesobject.c",
    "Objects/call.c",
    "Objects/capsule.c",
    "Objects/cellobject.c",
    "Objects/classobject.c",
    "Objects/clinic/bytearrayobject.c.h",
    "Objects/clinic/bytesobject.c.h",
    "Objects/clinic/classobject.c.h",
    "Objects/clinic/codeobject.c.h",
    "Objects/clinic/complexobject.c.h",
    "Objects/clinic/descrobject.c.h",
    "Objects/clinic/dictobject.c.h",
    "Objects/clinic/enumobject.c.h",
    "Objects/clinic/floatobject.c.h",
    "Objects/clinic/funcobject.c.h",
    "Objects/clinic/listobject.c.h",
    "Objects/clinic/longobject.c.h",
    "Objects/clinic/memoryobject.c.h",
    "Objects/clinic/moduleobject.c.h",
    "Objects/clinic/odictobject.c.h",
    "Objects/clinic/structseq.c.h",
    "Objects/clinic/tupleobject.c.h",
    "Objects/clinic/typeobject.c.h",
    "Objects/clinic/typevarobject.c.h",
    "Objects/clinic/unicodeobject.c.h",
    "Objects/codeobject.c",
    "Objects/complexobject.c",
    "Objects/descrobject.c",
    "Objects/dictobject.c",
    "Objects/enumobject.c",
    "Objects/exceptions.c",
    "Objects/fileobject.c",
    "Objects/floatobject.c",
    "Objects/frameobject.c",
    "Objects/funcobject.c",
    "Objects/genericaliasobject.c",
    "Objects/genobject.c",
    "Objects/interpreteridobject.c",
    "Objects/iterobject.c",
    "Objects/listobject.c",
    "Objects/longobject.c",
    "Objects/memoryobject.c",
    "Objects/methodobject.c",
    "Objects/moduleobject.c",
    "Objects/namespaceobject.c",
    "Objects/object.c",
    "Objects/obmalloc.c",
    "Objects/odictobject.c",
    "Objects/picklebufobject.c",
    "Objects/rangeobject.c",
    "Objects/setobject.c",
    "Objects/sliceobject.c",
    "Objects/stringlib/asciilib.h",
    "Objects/stringlib/clinic/transmogrify.h.h",
    "Objects/stringlib/codecs.h",
    "Objects/stringlib/count.h",
    "Objects/stringlib/ctype.h",
    "Objects/stringlib/eq.h",
    "Objects/stringlib/fastsearch.h",
    "Objects/stringlib/find.h",
    "Objects/stringlib/find_max_char.h",
    "Objects/stringlib/join.h",
    "Objects/stringlib/localeutil.h",
    "Objects/stringlib/partition.h",
    "Objects/stringlib/replace.h",
    "Objects/stringlib/split.h",
    "Objects/stringlib/stringdefs.h",
    "Objects/stringlib/transmogrify.h",
    "Objects/stringlib/ucs1lib.h",
    "Objects/stringlib/ucs2lib.h",
    "Objects/stringlib/ucs4lib.h",
    "Objects/stringlib/undef.h",
    "Objects/stringlib/unicode_format.h",
    "Objects/structseq.c",
    "Objects/tupleobject.c",
    "Objects/typeobject.c",
    "Objects/typeslots.inc",
    "Objects/typevarobject.c",
    "Objects/unicodectype.c",
    "Objects/unicodeobject.c",
    "Objects/unicodetype_db.h",
    "Objects/unionobject.c",
    "Objects/weakrefobject.c",
    "Parser/action_helpers.c",
    "Parser/myreadline.c",
    "Parser/parser.c",
    "Parser/peg_api.c",
    "Parser/pegen.c",
    "Parser/pegen.h",
    "Parser/pegen_errors.c",
    "Parser/string_parser.c",
    "Parser/string_parser.h",
    "Parser/token.c",
    "Parser/tokenizer.c",
    "Parser/tokenizer.h",
    "Python/Python-ast.c",
    "Python/Python-tokenize.c",
    "Python/_warnings.c",
    "Python/asdl.c",
    "Python/asm_trampoline.S",
    "Python/assemble.c",
    "Python/ast.c",
    "Python/ast_opt.c",
    "Python/ast_unparse.c",
    "Python/bltinmodule.c",
    "Python/bootstrap_hash.c",
    "Python/ceval.c",
    "Python/ceval_gil.c",
    "Python/ceval_macros.h",
    "Python/clinic/Python-tokenize.c.h",
    "Python/clinic/_warnings.c.h",
    "Python/clinic/bltinmodule.c.h",
    "Python/clinic/context.c.h",
    "Python/clinic/import.c.h",
    "Python/clinic/instrumentation.c.h",
    "Python/clinic/marshal.c.h",
    "Python/clinic/sysmodule.c.h",
    "Python/clinic/traceback.c.h",
    "Python/codecs.c",
    "Python/compile.c",
    "Python/condvar.h",
    "Python/context.c",
    "Python/dtoa.c",
    "Python/dynamic_annotations.c",
    "Python/dynload_shlib.c",
    "Python/errors.c",
    "Python/fileutils.c",
    "Python/flowgraph.c",
    "Python/formatter_unicode.c",
    "Python/frame.c",
    "Python/frozenmain.c",
    "Python/future.c",
    "Python/generated_cases.c.h",
    "Python/getargs.c",
    "Python/getcompiler.c",
    "Python/getcopyright.c",
    "Python/getopt.c",
    "Python/getplatform.c",
    "Python/getversion.c",
    "Python/hamt.c",
    "Python/hashtable.c",
    "Python/import.c",
    "Python/importdl.c",
    "Python/importdl.h",
    "Python/initconfig.c",
    "Python/instrumentation.c",
    "Python/intrinsics.c",
    "Python/legacy_tracing.c",
    "Python/marshal.c",
    "Python/modsupport.c",
    "Python/mysnprintf.c",
    "Python/mystrtoul.c",
    "Python/opcode_metadata.h",
    "Python/opcode_targets.h",
    "Python/pathconfig.c",
    "Python/perf_trampoline.c",
    "Python/preconfig.c",
    "Python/pyarena.c",
    "Python/pyctype.c",
    "Python/pyfpe.c",
    "Python/pyhash.c",
    "Python/pylifecycle.c",
    "Python/pymath.c",
    "Python/pystate.c",
    "Python/pystrcmp.c",
    "Python/pystrhex.c",
    "Python/pystrtod.c",
    "Python/pythonrun.c",
    "Python/pytime.c",
    "Python/specialize.c",
    "Python/stdlib_module_names.h",
    "Python/structmember.c",
    "Python/suggestions.c",
    "Python/symtable.c",
    "Python/sysmodule.c",
    "Python/thread.c",
    "Python/thread_pthread.h",
    "Python/traceback.c",
    "Python/tracemalloc.c",
    "Modules/getbuildinfo.c",
]

genrule(
    name = "gen_symbols",
    outs = ["symbols.lds"],
    cmd = """cat >$@ <<E_O_F
{
	global:
		Py*;
		_Py*;
		PyDict_GetItem;
	local:
		*;
};""")

# The main python executable including the interpreter and stdlib extension
# modules. Note that any file that's exporting Python C API symbols needs to be
# directly in srcs.
PYTHON_LINKOPTS = [
    "-pthread",
    "-ldl",
    "-lutil",
    "-lrt",
    "-Wl,--version-script=$(location :symbols.lds)",
    "-Wl,--export-dynamic",
]

cc_binary(
    name = "bin/bootstrap_python",
    srcs = PYTHON_SRCS + [
        "Modules/getpath.c",
        "Modules/main.c",
        "Programs/_bootstrap_python.c",
        ":frozen_bootstrap_headers",
        ":modules-config",
    ],
    copts = CORE_COPTS,
    linkopts = PYTHON_LINKOPTS,
    deps = [
        ":builtin_extensions",
        ":headers",
        ":symbols.lds",
    ],
)

cc_binary(
    name = "bin/python",
    srcs = PYTHON_SRCS + [
        # A few things in Modules/ that are not just for built in extensions
        "Modules/getpath.c",
        "Modules/main.c",
        # This can't be included in PYTHON_SRCS since it won't exist for bootstrap
        "Python/frozen.c",
        # plus the main python target
        "Programs/python.c",
        # plus the modules configuration
        ":modules-config",
        # plus all the stuff we generated using bootstrap python
        ":deepfreeze_srcs",
    ],
    copts = CORE_COPTS,
    linkopts = PYTHON_LINKOPTS,
    visibility = ["//visibility:public"],
    deps = [
        ":all_frozen_headers",
        ":builtin_extensions",
        ":expat",
        ":headers",
        "@cpython//bazel:buildinfo",
        ":symbols.lds",
    ],
)

cc_library(
    name = "all_frozen_headers",
    hdrs = [
        ":frozen_bootstrap_headers",
        ":frozen_headers",
    ],
    strip_include_prefix = "Python",
    visibility = ["//visibility:public"],
)

# Next are some extension modules that we statically link in but can't be
# directly in the main rule because they require special copts or dependencies.

cc_library(
    name = "_blake2",
    srcs = [
        "Modules/_blake2/blake2b_impl.c",
        "Modules/_blake2/blake2module.c",
        "Modules/_blake2/blake2module.h",
        "Modules/_blake2/blake2s_impl.c",
        "Modules/_blake2/clinic/blake2b_impl.c.h",
        "Modules/_blake2/clinic/blake2s_impl.c.h",
        "Modules/hashlib.h",
    ],
    copts = CORE_BUILTIN_COPTS + ["-DBLAKE2_USE_SSE"],
    deps = [
        ":blake2",
        ":headers",
    ],
)

cc_library(
    name = "blake2",
    srcs = [
        "Modules/_blake2/impl/blake2-config.h",
        "Modules/_blake2/impl/blake2-impl.h",
        "Modules/_blake2/impl/blake2b-load-sse2.h",
        "Modules/_blake2/impl/blake2b-round.h",
        "Modules/_blake2/impl/blake2s-load-sse2.h",
        "Modules/_blake2/impl/blake2s-round.h",
    ],
    hdrs = ["Modules/_blake2/impl/blake2.h"],
    textual_hdrs = [
        "Modules/_blake2/impl/blake2b.c",
        "Modules/_blake2/impl/blake2b-ref.c",
        "Modules/_blake2/impl/blake2s.c",
        "Modules/_blake2/impl/blake2s-ref.c",
    ],
)

cc_library(
    name = "_decimal",
    srcs = [
        "Modules/_decimal/_decimal.c",
        "Modules/_decimal/docstrings.h",
    ],
    copts = CORE_BUILTIN_COPTS + [
        "-DCONFIG_64",
        "-DANSI",
    ],
    linkstatic = True,
    deps = [
        ":headers",
        ":libmpdec",
    ],
)

cc_library(
    name = "libmpdec",
    srcs = [
        "Modules/_decimal/libmpdec/basearith.c",
        "Modules/_decimal/libmpdec/constants.c",
        "Modules/_decimal/libmpdec/context.c",
        "Modules/_decimal/libmpdec/convolute.c",
        "Modules/_decimal/libmpdec/crt.c",
        "Modules/_decimal/libmpdec/difradix2.c",
        "Modules/_decimal/libmpdec/fnt.c",
        "Modules/_decimal/libmpdec/fourstep.c",
        "Modules/_decimal/libmpdec/io.c",
        "Modules/_decimal/libmpdec/mpalloc.c",
        "Modules/_decimal/libmpdec/mpdecimal.c",
        "Modules/_decimal/libmpdec/numbertheory.c",
        "Modules/_decimal/libmpdec/sixstep.c",
        "Modules/_decimal/libmpdec/transpose.c",
    ],
    hdrs = [
        "Modules/_decimal/libmpdec/basearith.h",
        "Modules/_decimal/libmpdec/bits.h",
        "Modules/_decimal/libmpdec/constants.h",
        "Modules/_decimal/libmpdec/convolute.h",
        "Modules/_decimal/libmpdec/crt.h",
        "Modules/_decimal/libmpdec/difradix2.h",
        "Modules/_decimal/libmpdec/fnt.h",
        "Modules/_decimal/libmpdec/fourstep.h",
        "Modules/_decimal/libmpdec/io.h",
        "Modules/_decimal/libmpdec/mpalloc.h",
        "Modules/_decimal/libmpdec/mpdecimal.h",
        "Modules/_decimal/libmpdec/numbertheory.h",
        "Modules/_decimal/libmpdec/sixstep.h",
        "Modules/_decimal/libmpdec/transpose.h",
        "Modules/_decimal/libmpdec/typearith.h",
        "Modules/_decimal/libmpdec/umodarith.h",
    ],
    copts = CORE_BUILTIN_COPTS + [
        "-DCONFIG_64",
        "-DANSI",
    ],
    strip_include_prefix = "Modules/_decimal/libmpdec",
    deps = [
        ":headers",
    ],
)

cc_library(
    name = "libhacl_headers",
    hdrs = [
        "Modules/_hacl/include/krml/FStar_UInt128_Verified.h",
        "Modules/_hacl/include/krml/FStar_UInt_8_16_32_64.h",
        "Modules/_hacl/include/krml/fstar_uint128_struct_endianness.h",
        "Modules/_hacl/include/krml/internal/target.h",
        "Modules/_hacl/include/krml/lowstar_endianness.h",
        "Modules/_hacl/include/krml/types.h",
    ],
    strip_include_prefix = "Modules/_hacl/include",
)

cc_library(
    name = "_sqlite3",
    srcs = [
        "Modules/_sqlite/blob.c",
        "Modules/_sqlite/blob.h",
        "Modules/_sqlite/clinic/blob.c.h",
        "Modules/_sqlite/clinic/connection.c.h",
        "Modules/_sqlite/clinic/cursor.c.h",
        "Modules/_sqlite/clinic/module.c.h",
        "Modules/_sqlite/clinic/row.c.h",
        "Modules/_sqlite/connection.c",
        "Modules/_sqlite/connection.h",
        "Modules/_sqlite/cursor.c",
        "Modules/_sqlite/cursor.h",
        "Modules/_sqlite/microprotocols.c",
        "Modules/_sqlite/microprotocols.h",
        "Modules/_sqlite/module.c",
        "Modules/_sqlite/module.h",
        "Modules/_sqlite/prepare_protocol.c",
        "Modules/_sqlite/prepare_protocol.h",
        "Modules/_sqlite/row.c",
        "Modules/_sqlite/row.h",
        "Modules/_sqlite/statement.c",
        "Modules/_sqlite/statement.h",
        "Modules/_sqlite/util.c",
        "Modules/_sqlite/util.h",
    ],
    copts = CORE_BUILTIN_COPTS + [
        "-DSQLITE_OMIT_LOAD_EXTENSION",
        '-DMODULE_NAME=\\"sqlite3\\"',
    ],
    linkstatic = True,
    deps = [
        ":headers",
        "@sqlite3",
    ],
)

cc_library(
    name = "_elementtree",
    srcs = [
        "Modules/_elementtree.c",
        "Modules/clinic/_elementtree.c.h",
    ],
    copts = CORE_BUILTIN_COPTS,
    deps = [
        ":expat",
        ":headers",
    ],
)

cc_library(
    name = "_ctypes",
    srcs = [
        "Modules/_ctypes/_ctypes.c",
        "Modules/_ctypes/callbacks.c",
        "Modules/_ctypes/callproc.c",
        "Modules/_ctypes/cfield.c",
        "Modules/_ctypes/ctypes.h",
        "Modules/_ctypes/stgdict.c",
    ],
    copts = CORE_BUILTIN_COPTS,
    deps = [
        ":headers",
        "@libffi",
    ],
)

cc_library(
    name = "_ssl",
    srcs = [
    ],
    copts = CORE_BUILTIN_COPTS,
    deps = [":headers"],
)

# Python's vendorized expat library.
cc_library(
    name = "expat",
    srcs = [
        "Modules/expat/ascii.h",
        "Modules/expat/asciitab.h",
        "Modules/expat/iasciitab.h",
        "Modules/expat/internal.h",
        "Modules/expat/latin1tab.h",
        "Modules/expat/nametab.h",
        "Modules/expat/siphash.h",
        "Modules/expat/utf8tab.h",
        "Modules/expat/xmlparse.c",
        "Modules/expat/xmlrole.c",
        "Modules/expat/xmlrole.h",
        "Modules/expat/xmltok.c",
        "Modules/expat/xmltok.h",
        "Modules/expat/xmltok_impl.h",
    ],
    hdrs = [
        "Modules/expat/expat.h",
        "Modules/expat/expat_config.h",
        "Modules/expat/expat_external.h",
        "Modules/expat/pyexpatns.h",
    ],
    copts = [
        "-DHAVE_MEMMOVE",
        "-DXML_NS",
        "-DXML_DTD",
        "-DXML_CONTEXT_BYTES=1234",
        "-DBYTEORDER=1234",
        # This prevents expat from barfing because it can't detect any
        # randomness syscall. Python takes care of injecting entropy.
        "-DXML_POOR_ENTROPY",
        # Need to add PY_COPTS here beuse the config header includes pyconfig.h
    ] + PY_COPTS,
    strip_include_prefix = "Modules/expat",
    deps = [
        ":expat-textual-hdrs",
        ":headers",
    ],
)

cc_library(
    name = "expat-textual-hdrs",
    textual_hdrs = [
        "Modules/expat/xmltok_impl.c",
        "Modules/expat/xmltok_ns.c",
    ],
)

# We compile test extensions into shared objects, so they aren't included in our
# production build. It's also good to have a few shared extensions to verify we
# can load them.

cc_binary(
    name = "Lib/_ctypes_test.so",
    srcs = ["Modules/_ctypes/_ctypes_test.c"],
    copts = PY_COPTS,
    linkshared = True,
    deps = [":headers"],
)

cc_binary(
    name = "Lib/_testcapi.so",
    srcs = [
        "Modules/_testcapi/abstract.c",
        "Modules/_testcapi/buffer.c",
        "Modules/_testcapi/bytearray.c",
        "Modules/_testcapi/bytes.c",
        "Modules/_testcapi/clinic/exceptions.c.h",
        "Modules/_testcapi/clinic/float.c.h",
        "Modules/_testcapi/clinic/vectorcall.c.h",
        "Modules/_testcapi/clinic/watchers.c.h",
        "Modules/_testcapi/code.c",
        "Modules/_testcapi/codec.c",
        "Modules/_testcapi/complex.c",
        "Modules/_testcapi/datetime.c",
        "Modules/_testcapi/dict.c",
        "Modules/_testcapi/docstring.c",
        "Modules/_testcapi/exceptions.c",
        "Modules/_testcapi/file.c",
        "Modules/_testcapi/float.c",
        "Modules/_testcapi/gc.c",
        "Modules/_testcapi/getargs.c",
        "Modules/_testcapi/heaptype.c",
        "Modules/_testcapi/heaptype_relative.c",
        "Modules/_testcapi/immortal.c",
        "Modules/_testcapi/list.c",
        "Modules/_testcapi/long.c",
        "Modules/_testcapi/mem.c",
        "Modules/_testcapi/numbers.c",
        "Modules/_testcapi/parts.h",
        "Modules/_testcapi/pyos.c",
        "Modules/_testcapi/pytime.c",
        "Modules/_testcapi/run.c",
        "Modules/_testcapi/set.c",
        "Modules/_testcapi/structmember.c",
        "Modules/_testcapi/sys.c",
        "Modules/_testcapi/testcapi_long.h",
        "Modules/_testcapi/tuple.c",
        "Modules/_testcapi/unicode.c",
        "Modules/_testcapi/util.h",
        "Modules/_testcapi/vectorcall.c",
        "Modules/_testcapi/vectorcall_limited.c",
        "Modules/_testcapi/watchers.c",
        "Modules/_testcapimodule.c",
    ],
    copts = PY_COPTS,
    linkshared = True,
    deps = [
        ":_testcapi_feature_macros",
        ":headers",
    ],
)

cc_library(
    name = "_testcapi_feature_macros",
    textual_hdrs = [
        "Modules/_testcapi_feature_macros.inc",
    ],
)

cc_binary(
    name = "Lib/xxsubtype.so",
    srcs = ["Modules/xxsubtype.c"],
    copts = PY_COPTS,
    linkshared = True,
    deps = [":headers"],
)

cc_binary(
    name = "Lib/_testimportmultiple.so",
    srcs = ["Modules/_testimportmultiple.c"],
    copts = PY_COPTS,
    linkshared = True,
    deps = [":headers"],
)

cc_binary(
    name = "Lib/_testmultiphase.so",
    srcs = [
        "Modules/_testmultiphase.c",
        "Modules/clinic/_testmultiphase.c.h",
    ],
    copts = PY_COPTS,
    linkshared = True,
    deps = [":headers"],
)

# There are some modules we can't use with freeze_python because they fail link
# when used with getpath_noop.c. We use the full modules-config with bootstrap_python
# to reduce tedium since it needs a significant amount of modules to function
genrule(
    name = "modules-config-bootstrap-minimal",
    outs = ["Modules/config_core.c"],
    cmd = '''
cat <<'E_O_F' >$@
#include "Python.h"

extern PyObject* PyInit__io(void);
extern PyObject* PyInit__signal(void);
extern PyObject* PyInit__tracemalloc(void);
extern PyObject* PyInit_atexit(void);
extern PyObject* PyInit_faulthandler(void);
extern PyObject* PyInit_gc(void);

struct _inittab _PyImport_Inittab[] = {
    {"_io", PyInit__io},
    {"_signal", PyInit__signal},
    {"_tracemalloc", PyInit__tracemalloc},
    {"atexit", PyInit_atexit},
    {"faulthandler", PyInit_faulthandler},
    {"gc", PyInit_gc},
    {"sys", NULL},
    /* Sentinel */
    {0, 0}
};

E_O_F
''',
)

# Static table of extension modules. All extension modules that are statically
# linked into the interpreter must be listed here, so that import can find them.
genrule(
    name = "modules-config",
    outs = ["Modules/config.c"],
    cmd = '''
cat <<'E_O_F' >$@
#include "Python.h"
extern PyObject* PyInit__abc(void);
extern PyObject* PyInit__ast(void);
extern PyObject* PyInit__asyncio(void);
extern PyObject* PyInit__bisect(void);
extern PyObject* PyInit__blake2(void);
extern PyObject* PyInit__bz2(void);
extern PyObject* PyInit__codecs(void);
extern PyObject* PyInit__codecs_cn(void);
extern PyObject* PyInit__codecs_hk(void);
extern PyObject* PyInit__codecs_iso2022(void);
extern PyObject* PyInit__codecs_jp(void);
extern PyObject* PyInit__codecs_kr(void);
extern PyObject* PyInit__codecs_tw(void);
extern PyObject* PyInit__collections(void);
extern PyObject* PyInit__contextvars(void);
extern PyObject* PyInit__crypt(void);
extern PyObject* PyInit__csv(void);
extern PyObject* PyInit__ctypes(void);
extern PyObject* PyInit__curses(void);
extern PyObject* PyInit__curses_panel(void);
extern PyObject* PyInit__datetime(void);
extern PyObject* PyInit__decimal(void);
extern PyObject* PyInit__elementtree(void);
extern PyObject* PyInit__functools(void);
extern PyObject* PyInit__hashlib(void);
extern PyObject* PyInit__heapq(void);
extern PyObject* PyInit__imp(void);
extern PyObject* PyInit__io(void);
extern PyObject* PyInit__json(void);
extern PyObject* PyInit__locale(void);
extern PyObject* PyInit__lsprof(void);
extern PyObject* PyInit__lzma(void);
extern PyObject* PyInit__md5(void);
extern PyObject* PyInit__multibytecodec(void);
extern PyObject* PyInit__multiprocessing(void);
extern PyObject* PyInit__opcode(void);
extern PyObject* PyInit__operator(void);
extern PyObject* PyInit__pickle(void);
extern PyObject* PyInit__posixshmem(void);
extern PyObject* PyInit__posixsubprocess(void);
extern PyObject* PyInit__queue(void);
extern PyObject* PyInit__random(void);
extern PyObject* PyInit__sha1(void);
extern PyObject* PyInit__sha2(void);
extern PyObject* PyInit__sha3(void);
extern PyObject* PyInit__signal(void);
extern PyObject* PyInit__socket(void);
extern PyObject* PyInit__sqlite3(void);
extern PyObject* PyInit__sre(void);
extern PyObject* PyInit__ssl(void);
extern PyObject* PyInit__stat(void);
extern PyObject* PyInit__string(void);
extern PyObject* PyInit__struct(void);
extern PyObject* PyInit__symtable(void);
extern PyObject* PyInit__testinternalcapi(void);
extern PyObject* PyInit__thread(void);
extern PyObject* PyInit__tokenize(void);
extern PyObject* PyInit__tracemalloc(void);
extern PyObject* PyInit__typing(void);
extern PyObject* PyInit__weakref(void);
extern PyObject* PyInit_array(void);
extern PyObject* PyInit_atexit(void);
extern PyObject* PyInit_audioop(void);
extern PyObject* PyInit_binascii(void);
extern PyObject* PyInit_cmath(void);
extern PyObject* PyInit_errno(void);
extern PyObject* PyInit_faulthandler(void);
extern PyObject* PyInit_fcntl(void);
extern PyObject* PyInit_gc(void);
extern PyObject* PyInit_grp(void);
extern PyObject* PyInit_itertools(void);
extern PyObject* PyInit_math(void);
extern PyObject* PyInit_mmap(void);
extern PyObject* PyInit_posix(void);
extern PyObject* PyInit_pwd(void);
extern PyObject* PyInit_pyexpat(void);
extern PyObject* PyInit_readline(void);
extern PyObject* PyInit_resource(void);
extern PyObject* PyInit_select(void);
extern PyObject* PyInit_spwd(void);
extern PyObject* PyInit_syslog(void);
extern PyObject* PyInit_termios(void);
extern PyObject* PyInit_time(void);
extern PyObject* PyInit_unicodedata(void);
extern PyObject* PyInit_zipimport(void);
extern PyObject* PyInit_zlib(void);
extern PyObject* PyMarshal_Init(void);
extern PyObject* _PyWarnings_Init(void);

struct _inittab _PyImport_Inittab[] = {
    {"_abc", PyInit__abc},
    {"_ast", PyInit__ast},
    {"_asyncio", PyInit__asyncio},
    {"_bisect", PyInit__bisect},
    {"_blake2", PyInit__blake2},
    {"_bz2", PyInit__bz2},
    {"_codecs", PyInit__codecs},
    {"_codecs_cn", PyInit__codecs_cn},
    {"_codecs_hk", PyInit__codecs_hk},
    {"_codecs_iso2022", PyInit__codecs_iso2022},
    {"_codecs_jp", PyInit__codecs_jp},
    {"_codecs_kr", PyInit__codecs_kr},
    {"_codecs_tw", PyInit__codecs_tw},
    {"_collections", PyInit__collections},
    {"_contextvars", PyInit__contextvars},
    {"_crypt", PyInit__crypt},
    {"_csv", PyInit__csv},
    {"_ctypes", PyInit__ctypes},
    {"_curses", PyInit__curses},
    {"_curses_panel", PyInit__curses_panel},
    {"_datetime", PyInit__datetime},
    {"_decimal", PyInit__decimal},
    {"_elementtree", PyInit__elementtree},
    {"_functools", PyInit__functools},
    {"_hashlib", PyInit__hashlib},
    {"_heapq", PyInit__heapq},
    {"_imp", PyInit__imp},
    {"_io", PyInit__io},
    {"_json", PyInit__json},
    {"_locale", PyInit__locale},
    {"_lsprof", PyInit__lsprof},
    {"_lzma", PyInit__lzma},
    {"_md5", PyInit__md5},
    {"_multibytecodec", PyInit__multibytecodec},
    {"_multiprocessing", PyInit__multiprocessing},
    {"_opcode", PyInit__opcode},
    {"_operator", PyInit__operator},
    {"_pickle", PyInit__pickle},
    {"_posixshmem", PyInit__posixshmem},
    {"_posixsubprocess", PyInit__posixsubprocess},
    {"_queue", PyInit__queue},
    {"_random", PyInit__random},
    {"_sha1", PyInit__sha1},
    {"_sha2", PyInit__sha2},
    {"_sha3", PyInit__sha3},
    {"_signal", PyInit__signal},
    {"_socket", PyInit__socket},
    {"_sqlite3", PyInit__sqlite3},
    {"_sre", PyInit__sre},
    {"_ssl", PyInit__ssl},
    {"_stat", PyInit__stat},
    {"_string", PyInit__string},
    {"_struct", PyInit__struct},
    {"_symtable", PyInit__symtable},
    {"_testinternalcapi", PyInit__testinternalcapi},
    {"_thread", PyInit__thread},
    {"_tokenize", PyInit__tokenize},
    {"_tracemalloc", PyInit__tracemalloc},
    {"_typing", PyInit__typing},
    {"_warnings", _PyWarnings_Init},
    {"_weakref", PyInit__weakref},
    {"array", PyInit_array},
    {"atexit", PyInit_atexit},
    {"audioop", PyInit_audioop},
    {"binascii", PyInit_binascii},
    {"builtins", NULL},
    {"cmath", PyInit_cmath},
    {"errno", PyInit_errno},
    {"faulthandler", PyInit_faulthandler},
    {"fcntl", PyInit_fcntl},
    {"gc", PyInit_gc},
    {"grp", PyInit_grp},
    {"itertools", PyInit_itertools},
    {"marshal", PyMarshal_Init},
    {"math", PyInit_math},
    {"mmap", PyInit_mmap},
    {"posix", PyInit_posix},
    {"pwd", PyInit_pwd},
    {"pyexpat", PyInit_pyexpat},
    {"readline", PyInit_readline},
    {"resource", PyInit_resource},
    {"select", PyInit_select},
    {"spwd", PyInit_spwd},
    {"sys", NULL},
    {"syslog", PyInit_syslog},
    {"termios", PyInit_termios},
    {"time", PyInit_time},
    {"unicodedata", PyInit_unicodedata},
    {"zlib", PyInit_zlib},
    /* Sentinel */
    {0, 0}
};
E_O_F
''',
)

# Zipping of the stdlib.

genrule(
    name = "test-stdlib-zip",
    srcs = glob(["Lib/**"]) + [
        ":Lib/_ctypes_test.so",
        ":Lib/_testcapi.so",
        ":Lib/_testimportmultiple.so",
        ":Lib/_testmultiphase.so",
        ":Lib/xxsubtype.so",
        ":sysconfigdata",
    ],
    outs = ["test-stdlib.zip"],
    cmd = "$(location @cpython//bazel:zip-stdlib) sloppy $@ $(SRCS)",
    tools = ["@cpython//bazel:zip-stdlib"],
)

filegroup(
    name = "production-stdlib",
    srcs = glob(
        ["Lib/**/*.py"],
        exclude = [
            "Lib/ensurepip/**",
            "Lib/idlelib/**",
            "Lib/lib-tk/**",
            "Lib/plat-*/**",
            "Lib/turtledemo/**",
            "**/test/**",
            "**/tests/**",
        ],
    ) + [":sysconfigdata"],
)

genrule(
    name = "stdlib-zip",
    srcs = [
        ":bin/python",
        ":production-stdlib",
        "Lib/lib2to3/Grammar.txt",
        "Lib/lib2to3/PatternGrammar.txt",
    ],
    outs = ["lib/python312.zip"],
    cmd = """
export ASAN_OPTIONS=detect_leaks=0
export PYTHONHASHSEED=0
mkdir $(@D)/python3.12
touch $(@D)/python3.12/os.py
mkdir $(@D)/python3.12/lib-dynload
# First, create an initial stdlib zip with the system Python.
$(location @cpython//:bazel:zip-stdlib) sloppy $@ $(locations :production-stdlib)
# Then do the final zip with our python using the temporary stdlib.
cp $(location :bin/python) $(location :bin/python)-prime
mkdir -p tmp/Lib/lib2to3
gram=$$($(location :bin/python)-prime $(location @cpython//bazel:gen_2to3_grammar.py) $(location Lib/lib2to3/Grammar.txt))
patgram=$$($(location :bin/python)-prime $(location @cpython//bazel:gen_2to3_grammar.py) $(location Lib/lib2to3/PatternGrammar.txt))
$(location :bin/python)-prime $(location @cpython//bazel:zip_stdlib.py) final $@ $(locations :production-stdlib) $$gram $$patgram
""",
    tools = [
        "@cpython//bazel:gen_2to3_grammar.py",
        "@cpython//bazel:zip-stdlib",
        "@cpython//bazel:zip_stdlib.py",
    ],
)

# The final package.
_tar_files = {
    ":bin/python": "bin/python",
    ":stdlib-zip": "lib/python312.zip",
}

_tar_files.update({h: "include/python3.12/" + h.partition("/")[2] for h in PYTHON_HEADERS})

pkg_tar(
    name = "drte-python",
    empty_files = [
        # Sentinels for Python to find its prefix.
        "lib/python3.12/os.py",
        "lib/python3.12/lib-dynload/.SENTINEL",
    ],
    extension = "tar.xz",
    files = _tar_files,
    visibility = ["//visibility:public"],
)

genrule(
    name = "runtime_sentinels",
    outs = [
        "lib/python3.12/os.py",
        "lib/python3.12/lib-dynload/.SENTINEL",
    ],
    cmd = "touch $(OUTS)",
)

filegroup(
    name = "runtime",
    srcs = [
        "bin/python",
        "lib/python3.12/lib-dynload/.SENTINEL",
        "lib/python3.12/os.py",
        "lib/python312.zip",
    ],
    visibility = ["//visibility:public"],
)

# Python has a complex bootstrap process to create frozen modules. We need to create
# a bootstrap python, but creating a bootstrap python requires a frozen importlib.
# To do that, we need
cc_binary(
    name = "freeze_module",
    srcs = [
        "Programs/_freeze_module.c",
        "Modules/getpath_noop.c",
        # minimal modules config
        ":modules-config-bootstrap-minimal",
    ] + PYTHON_SRCS,
    copts = CORE_COPTS,
    linkopts = [
        "-pthread",
        "-lrt",
    ],
    deps = [
        ":builtin_extensions_bootstrap_minimal",
        ":headers",
    ],
)

# These are the headers that are only needed by bootstrap python.
genrule(
    name = "frozen_bootstrap_headers",
    srcs = [
        "Lib/importlib/_bootstrap.py",
        "Lib/importlib/_bootstrap_external.py",
        "Modules/getpath.py",
        "Lib/zipimport.py",
    ],
    outs = [
        "Python/frozen_modules/importlib._bootstrap.h",
        "Python/frozen_modules/importlib._bootstrap_external.h",
        "Python/frozen_modules/getpath.h",
        "Python/frozen_modules/zipimport.h",
    ],
    cmd = """
$(location //:freeze_module) importlib._bootstrap $(location Lib/importlib/_bootstrap.py) $(location Python/frozen_modules/importlib._bootstrap.h)
$(location //:freeze_module) importlib._bootstrap_external $(location Lib/importlib/_bootstrap_external.py) $(location Python/frozen_modules/importlib._bootstrap_external.h)
$(location //:freeze_module) getpath $(location Modules/getpath.py) $(location Python/frozen_modules/getpath.h)
$(location //:freeze_module) zipimport $(location Lib/zipimport.py) $(location Python/frozen_modules/zipimport.h)
""",
    tools = [":freeze_module"],
)

genrule(
    name = "frozen_headers",
    srcs = glob([
        "Lib/**",
    ]) + [
        "Programs/_freeze_module.py",
        "Tools/freeze/flag.py",
    ],
    outs = [
        "Python/frozen_modules/abc.h",
        "Python/frozen_modules/codecs.h",
        "Python/frozen_modules/io.h",
        "Python/frozen_modules/_collections_abc.h",
        "Python/frozen_modules/_sitebuiltins.h",
        "Python/frozen_modules/genericpath.h",
        "Python/frozen_modules/ntpath.h",
        "Python/frozen_modules/posixpath.h",
        "Python/frozen_modules/os.h",
        "Python/frozen_modules/site.h",
        "Python/frozen_modules/stat.h",
        "Python/frozen_modules/importlib.util.h",
        "Python/frozen_modules/importlib.machinery.h",
        "Python/frozen_modules/runpy.h",
        "Python/frozen_modules/__hello__.h",
        "Python/frozen_modules/__phello__.h",
        "Python/frozen_modules/__phello__.ham.h",
        "Python/frozen_modules/__phello__.ham.eggs.h",
        "Python/frozen_modules/__phello__.spam.h",
        "Python/frozen_modules/frozen_only.h",
    ],
    cmd = '''
mkdir temp-bin
# Construct a python tree that can find the stdlib files we need.
mkdir temp-bin/bin
mkdir temp-bin/lib
cp $(location :bin/bootstrap_python) temp-bin/bin/
cp -r $$(dirname $(location Lib/os.py)) temp-bin/lib/python3.12
ls temp-bin/lib
mkdir temp-bin/lib/python3.12/lib-dynload
touch temp-bin/lib/python3.12/lib-dynload/.SENTINEL
# And actually execute freeze_module.py for the things we need.
FREEZE_MODULE="temp-bin/bin/bootstrap_python $(location Programs/_freeze_module.py)"

# These can be found in the # BEGIN: freezing_modules section.
# Pay attention to which use FREEZE_MODULE and which use FREEZE_MODULE_BOOTSTRAP.
$$FREEZE_MODULE abc $(location Lib/abc.py) $(location Python/frozen_modules/abc.h)
$$FREEZE_MODULE codecs $(location Lib/codecs.py) $(location Python/frozen_modules/codecs.h)
$$FREEZE_MODULE io $(location Lib/io.py) $(location Python/frozen_modules/io.h)
$$FREEZE_MODULE _collections_abc $(location Lib/_collections_abc.py) $(location Python/frozen_modules/_collections_abc.h)
$$FREEZE_MODULE _sitebuiltins $(location Lib/_sitebuiltins.py) $(location Python/frozen_modules/_sitebuiltins.h)
$$FREEZE_MODULE genericpath $(location Lib/genericpath.py) $(location Python/frozen_modules/genericpath.h)
$$FREEZE_MODULE ntpath $(location Lib/ntpath.py) $(location Python/frozen_modules/ntpath.h)
$$FREEZE_MODULE posixpath $(location Lib/posixpath.py) $(location Python/frozen_modules/posixpath.h)
$$FREEZE_MODULE os $(location Lib/os.py) $(location Python/frozen_modules/os.h)
$$FREEZE_MODULE site $(location Lib/site.py) $(location Python/frozen_modules/site.h)
$$FREEZE_MODULE stat $(location Lib/stat.py) $(location Python/frozen_modules/stat.h)
$$FREEZE_MODULE importlib.util $(location Lib/importlib/util.py) $(location Python/frozen_modules/importlib.util.h)
$$FREEZE_MODULE importlib.machinery $(location Lib/importlib/machinery.py) $(location Python/frozen_modules/importlib.machinery.h)
$$FREEZE_MODULE runpy $(location Lib/runpy.py) $(location Python/frozen_modules/runpy.h)
# Its kind of unclear whether we need these, but including to be safe.
$$FREEZE_MODULE __hello__ $(location Lib/__hello__.py) $(location Python/frozen_modules/__hello__.h)
$$FREEZE_MODULE __phello__ $(location Lib/__phello__/__init__.py) $(location Python/frozen_modules/__phello__.h)
$$FREEZE_MODULE __phello__.ham $(location Lib/__phello__/ham/__init__.py) $(location Python/frozen_modules/__phello__.ham.h)
$$FREEZE_MODULE __phello__.ham.eggs $(location Lib/__phello__/ham/eggs.py) $(location Python/frozen_modules/__phello__.ham.eggs.h)
$$FREEZE_MODULE __phello__.spam $(location Lib/__phello__/spam.py) $(location Python/frozen_modules/__phello__.spam.h)
# This one is used as some sentinel or something.
$$FREEZE_MODULE frozen_only $(location Tools/freeze/flag.py) $(location Python/frozen_modules/frozen_only.h)
''',
    tools = [":bin/bootstrap_python"],
)

genrule(
    name = "deepfreeze_srcs",
    srcs = glob([
        "Lib/**",
    ]) + [
        "Tools/build/deepfreeze.py",
        # We have to manually list out the headers, which is annoying.
        "Python/frozen_modules/importlib._bootstrap.h",
        "Python/frozen_modules/importlib._bootstrap_external.h",
        "Python/frozen_modules/getpath.h",
        "Python/frozen_modules/zipimport.h",
        "Python/frozen_modules/abc.h",
        "Python/frozen_modules/codecs.h",
        "Python/frozen_modules/io.h",
        "Python/frozen_modules/_collections_abc.h",
        "Python/frozen_modules/_sitebuiltins.h",
        "Python/frozen_modules/genericpath.h",
        "Python/frozen_modules/ntpath.h",
        "Python/frozen_modules/posixpath.h",
        "Python/frozen_modules/os.h",
        "Python/frozen_modules/site.h",
        "Python/frozen_modules/stat.h",
        "Python/frozen_modules/importlib.util.h",
        "Python/frozen_modules/importlib.machinery.h",
        "Python/frozen_modules/runpy.h",
        "Python/frozen_modules/__hello__.h",
        "Python/frozen_modules/__phello__.h",
        "Python/frozen_modules/__phello__.ham.h",
        "Python/frozen_modules/__phello__.ham.eggs.h",
        "Python/frozen_modules/__phello__.spam.h",
        "Python/frozen_modules/frozen_only.h",
    ],
    outs = ["Python/deepfreeze/deepfreeze.c"],
    cmd = """
mkdir temp-bin
# Construct a python tree that can find the stdlib files we need.
mkdir temp-bin/bin
mkdir temp-bin/lib
cp $(location :bin/bootstrap_python) temp-bin/bin/
cp -r $$(dirname $(location Lib/os.py)) temp-bin/lib/python3.12
ls temp-bin/lib
mkdir temp-bin/lib/python3.12/lib-dynload
touch temp-bin/lib/python3.12/lib-dynload/.SENTINEL

# Sadly `bzl fmt` goes rogue and ruins formatting if you attempt to use \
# to put this on multiple lines.
temp-bin/bin/bootstrap_python $(location Tools/build/deepfreeze.py)     $(location Python/frozen_modules/importlib._bootstrap.h):importlib._bootstrap     $(location Python/frozen_modules/importlib._bootstrap_external.h):importlib._bootstrap_external     $(location Python/frozen_modules/zipimport.h):zipimport     $(location Python/frozen_modules/abc.h):abc     $(location Python/frozen_modules/codecs.h):codecs     $(location Python/frozen_modules/io.h):io     $(location Python/frozen_modules/_collections_abc.h):_collections_abc     $(location Python/frozen_modules/_sitebuiltins.h):_sitebuiltins     $(location Python/frozen_modules/genericpath.h):genericpath     $(location Python/frozen_modules/ntpath.h):ntpath     $(location Python/frozen_modules/posixpath.h):posixpath     $(location Python/frozen_modules/os.h):os     $(location Python/frozen_modules/site.h):site     $(location Python/frozen_modules/stat.h):stat     $(location Python/frozen_modules/importlib.util.h):importlib.util     $(location Python/frozen_modules/importlib.machinery.h):importlib.machinery     $(location Python/frozen_modules/runpy.h):runpy     $(location Python/frozen_modules/__hello__.h):__hello__     $(location Python/frozen_modules/__phello__.h):__phello__     $(location Python/frozen_modules/__phello__.ham.h):__phello__.ham     $(location Python/frozen_modules/__phello__.ham.eggs.h):__phello__.ham.eggs     $(location Python/frozen_modules/__phello__.spam.h):__phello__.spam     $(location Python/frozen_modules/frozen_only.h):frozen_only     -o $(location Python/deepfreeze/deepfreeze.c)
""",
    tools = [":bin/bootstrap_python"],
)

# CPython dumps every variable in its Makefile into Lib/_sysconfigdata.py and
# then exposes the resulting dictionary as an API through the sysconfig and
# distutils.sysconfig modules. This is, of course, a terrible idea. What follows
# is a small subset of that experimentally shown to allow distutils to work. In
# practice, we override most of these things in vpip.
genrule(
    name = "sysconfigdata",
    outs = ["Lib/_sysconfigdata__linux_.py"],
    cmd = """
cat <<'E_O_F' >$@
build_time_vars = {
 'Py_ENABLE_SHARED': 0,
 'LIBDIR': '/usr/local/lib',
 'SHLIBS': '-lpthread -ldl  -lutil',
 'BINDIR': '/usr/local/bin',
 'VERSION': '3.12',
 'EXE': '',
 'exec_prefix': '/usr/local',
 'prefix': '/usr/local',
 'CC': 'gcc -pthread',
 'CCSHARED': '-fPIC',
 'OPT': '-fno-strict-aliasing -DNDEBUG -fwrapv -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -O3 -Wall -Wstrict-prototypes',
 'CFLAGS': '-fno-strict-aliasing -O2 -DNDEBUG -fwrapv -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -O3 -Wall -Wstrict-prototypes',
 'CFLAGSFORSHARED': '',
 'CXX': 'g++ -pthread',
 'LDSHARED': 'gcc -pthread -shared',
 'LDFLAGS': '',
 'AR': 'ar',
 'ARFLAGS': 'rc',
 'EXT_SUFFIX': '.cpython-312-x86_64-linux-gnu.so',
 'WITH_DOC_STRINGS': 1,
 'HAVE_GETRANDOM_SYSCALL': 1,
}
E_O_F
""",
)

genrule(
    name = "pyconfig-h",
    outs = ["Include/pyconfig.h"],
    cmd = '''
cat <<'E_O_F' >$@
#ifndef Py_PYCONFIG_H
#define Py_PYCONFIG_H
#define ALIGNOF_LONG 8
#define ALIGNOF_MAX_ALIGN_T 16
#define ALIGNOF_SIZE_T 8
#define DOUBLE_IS_LITTLE_ENDIAN_IEEE754 1
#define ENABLE_IPV6 1
#define HAVE_ACCEPT 1
#define HAVE_ACCEPT4 1
#define HAVE_ACOSH 1
#define HAVE_ADDRINFO 1
#define HAVE_ALARM 1
#define HAVE_ALLOCA_H 1
#define HAVE_ASINH 1
#define HAVE_ASM_TYPES_H 1
#define HAVE_ATANH 1
#define HAVE_BIND 1
#define HAVE_BIND_TEXTDOMAIN_CODESET 1
#define HAVE_BUILTIN_ATOMIC 1
#define HAVE_CHMOD 1
#define HAVE_CHOWN 1
#define HAVE_CHROOT 1
#define HAVE_CLOCK 1
#define HAVE_CLOCK_GETRES 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_CLOCK_NANOSLEEP 1
#define HAVE_CLOCK_SETTIME 1
#define HAVE_COMPUTED_GOTOS 1
#define HAVE_CONFSTR 1
#define HAVE_CONNECT 1
#define HAVE_COPY_FILE_RANGE 1
#define HAVE_CRYPT_H 1
#define HAVE_CRYPT_R 1
#define HAVE_CTERMID 1
#define HAVE_CURSES_FILTER 1
#define HAVE_CURSES_H 1
#define HAVE_CURSES_HAS_KEY 1
#define HAVE_CURSES_IMMEDOK 1
#define HAVE_CURSES_IS_PAD 1
#define HAVE_CURSES_IS_TERM_RESIZED 1
#define HAVE_CURSES_RESIZETERM 1
#define HAVE_CURSES_RESIZE_TERM 1
#define HAVE_CURSES_SYNCOK 1
#define HAVE_CURSES_TYPEAHEAD 1
#define HAVE_CURSES_USE_ENV 1
#define HAVE_CURSES_WCHGAT 1
#define HAVE_DECL_RTLD_DEEPBIND 1
#define HAVE_DECL_RTLD_GLOBAL 1
#define HAVE_DECL_RTLD_LAZY 1
#define HAVE_DECL_RTLD_LOCAL 1
#define HAVE_DECL_RTLD_MEMBER 0
#define HAVE_DECL_RTLD_NODELETE 1
#define HAVE_DECL_RTLD_NOLOAD 1
#define HAVE_DECL_RTLD_NOW 1
#define HAVE_DEVICE_MACROS 1
#define HAVE_DEV_PTMX 1
#define HAVE_DIRENT_D_TYPE 1
#define HAVE_DIRENT_H 1
#define HAVE_DIRFD 1
#define HAVE_DLFCN_H 1
#define HAVE_DLOPEN 1
#define HAVE_DUP 1
#define HAVE_DUP2 1
#define HAVE_DUP3 1
#define HAVE_DYNAMIC_LOADING 1
#define HAVE_ENDIAN_H 1
#define HAVE_EPOLL 1
#define HAVE_EPOLL_CREATE1 1
#define HAVE_ERF 1
#define HAVE_ERFC 1
#define HAVE_ERRNO_H 1
#define HAVE_EVENTFD 1
#define HAVE_EXECV 1
#define HAVE_EXPLICIT_BZERO 1
#define HAVE_EXPM1 1
#define HAVE_FACCESSAT 1
#define HAVE_FCHDIR 1
#define HAVE_FCHMOD 1
#define HAVE_FCHMODAT 1
#define HAVE_FCHOWN 1
#define HAVE_FCHOWNAT 1
#define HAVE_FCNTL_H 1
#define HAVE_FDATASYNC 1
#define HAVE_FDOPENDIR 1
#define HAVE_FEXECVE 1
#define HAVE_FLOCK 1
#define HAVE_FORK 1
#define HAVE_FORKPTY 1
#define HAVE_FPATHCONF 1
#define HAVE_FSEEKO 1
#define HAVE_FSTATAT 1
#define HAVE_FSTATVFS 1
#define HAVE_FSYNC 1
#define HAVE_FTELLO 1
#define HAVE_FTIME 1
#define HAVE_FTRUNCATE 1
#define HAVE_FUTIMENS 1
#define HAVE_FUTIMES 1
#define HAVE_FUTIMESAT 1
#define HAVE_GAI_STRERROR 1
#define HAVE_GCC_ASM_FOR_X64 1
#define HAVE_GCC_ASM_FOR_X87 1
#define HAVE_GCC_UINT128_T 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETC_UNLOCKED 1
#define HAVE_GETEGID 1
#define HAVE_GETENTROPY 1
#define HAVE_GETEUID 1
#define HAVE_GETGID 1
#define HAVE_GETGRGID 1
#define HAVE_GETGRGID_R 1
#define HAVE_GETGRNAM_R 1
#define HAVE_GETGROUPLIST 1
#define HAVE_GETGROUPS 1
#define HAVE_GETHOSTBYADDR 1
#define HAVE_GETHOSTBYNAME 1
#define HAVE_GETHOSTBYNAME_R 1
#define HAVE_GETHOSTBYNAME_R_6_ARG 1
#define HAVE_GETHOSTNAME 1
#define HAVE_GETITIMER 1
#define HAVE_GETLOADAVG 1
#define HAVE_GETLOGIN 1
#define HAVE_GETNAMEINFO 1
#define HAVE_GETPAGESIZE 1
#define HAVE_GETPEERNAME 1
#define HAVE_GETPGID 1
#define HAVE_GETPGRP 1
#define HAVE_GETPID 1
#define HAVE_GETPPID 1
#define HAVE_GETPRIORITY 1
#define HAVE_GETPROTOBYNAME 1
#define HAVE_GETPWENT 1
#define HAVE_GETPWNAM_R 1
#define HAVE_GETPWUID 1
#define HAVE_GETPWUID_R 1
#define HAVE_GETRANDOM 1
#define HAVE_GETRANDOM_SYSCALL 1
#define HAVE_GETRESGID 1
#define HAVE_GETRESUID 1
#define HAVE_GETRUSAGE 1
#define HAVE_GETSERVBYNAME 1
#define HAVE_GETSERVBYPORT 1
#define HAVE_GETSID 1
#define HAVE_GETSOCKNAME 1
#define HAVE_GETSPENT 1
#define HAVE_GETSPNAM 1
#define HAVE_GETUID 1
#define HAVE_GETWD 1
#define HAVE_GRP_H 1
#define HAVE_HSTRERROR 1
#define HAVE_HTOLE64 1
#define HAVE_IF_NAMEINDEX 1
#define HAVE_INET_ATON 1
#define HAVE_INET_NTOA 1
#define HAVE_INET_PTON 1
#define HAVE_INITGROUPS 1
#define HAVE_INTTYPES_H 1
#define HAVE_KILL 1
#define HAVE_KILLPG 1
#define HAVE_LANGINFO_H 1
#define HAVE_LCHOWN 1
#define HAVE_LIBDL 1
#define HAVE_LIBINTL_H 1
#define HAVE_LIBSQLITE3 1
#define HAVE_LINK 1
#define HAVE_LINKAT 1
#define HAVE_LINUX_AUXVEC_H 1
#define HAVE_LINUX_CAN_BCM_H 1
#define HAVE_LINUX_CAN_H 1
#define HAVE_LINUX_CAN_J1939_H 1
#define HAVE_LINUX_CAN_RAW_FD_FRAMES 1
#define HAVE_LINUX_CAN_RAW_H 1
#define HAVE_LINUX_CAN_RAW_JOIN_FILTERS 1
#define HAVE_LINUX_FS_H 1
#define HAVE_LINUX_LIMITS_H 1
#define HAVE_LINUX_MEMFD_H 1
#define HAVE_LINUX_NETLINK_H 1
#define HAVE_LINUX_QRTR_H 1
#define HAVE_LINUX_RANDOM_H 1
#define HAVE_LINUX_SOUNDCARD_H 1
#define HAVE_LINUX_TIPC_H 1
#define HAVE_LINUX_VM_SOCKETS_H 1
#define HAVE_LINUX_WAIT_H 1
#define HAVE_LISTEN 1
#define HAVE_LOCKF 1
#define HAVE_LOG1P 1
#define HAVE_LOG2 1
#define HAVE_LOGIN_TTY 1
#define HAVE_LONG_DOUBLE 1
#define HAVE_LSTAT 1
#define HAVE_LUTIMES 1
#define HAVE_MADVISE 1
#define HAVE_MAKEDEV 1
#define HAVE_MBRTOWC 1
#define HAVE_MEMFD_CREATE 1
#define HAVE_MEMRCHR 1
#define HAVE_MKDIRAT 1
#define HAVE_MKFIFO 1
#define HAVE_MKFIFOAT 1
#define HAVE_MKNOD 1
#define HAVE_MKNODAT 1
#define HAVE_MKTIME 1
#define HAVE_MMAP 1
#define HAVE_MREMAP 1
#define HAVE_NANOSLEEP 1
#define HAVE_NCURSES_H 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_NETPACKET_PACKET_H 1
#define HAVE_NET_ETHERNET_H 1
#define HAVE_NET_IF_H 1
#define HAVE_NICE 1
#define HAVE_OPENAT 1
#define HAVE_OPENDIR 1
#define HAVE_OPENPTY 1
#define HAVE_PATHCONF 1
#define HAVE_PAUSE 1
#define HAVE_PIPE 1
#define HAVE_PIPE2 1
#define HAVE_POLL 1
#define HAVE_POLL_H 1
#define HAVE_POSIX_FADVISE 1
#define HAVE_POSIX_FALLOCATE 1
#define HAVE_POSIX_SPAWN 1
#define HAVE_POSIX_SPAWNP 1
#define HAVE_PREAD 1
#define HAVE_PREADV 1
#define HAVE_PREADV2 1
#define HAVE_PRLIMIT 1
#define HAVE_PROTOTYPES 1
#define HAVE_PTHREAD_CONDATTR_SETCLOCK 1
#define HAVE_PTHREAD_GETCPUCLOCKID 1
#define HAVE_PTHREAD_H 1
#define HAVE_PTHREAD_KILL 1
#define HAVE_PTHREAD_SIGMASK 1
#define HAVE_PTY_H 1
#define HAVE_PWRITE 1
#define HAVE_PWRITEV 1
#define HAVE_PWRITEV2 1
#define HAVE_READLINK 1
#define HAVE_READLINKAT 1
#define HAVE_READV 1
#define HAVE_REALPATH 1
#define HAVE_RECVFROM 1
#define HAVE_RENAMEAT 1
#define HAVE_RL_APPEND_HISTORY 1
#define HAVE_RL_CATCH_SIGNAL 1
#define HAVE_RL_COMPDISP_FUNC_T 1
#define HAVE_RL_COMPLETION_APPEND_CHARACTER 1
#define HAVE_RL_COMPLETION_DISPLAY_MATCHES_HOOK 1
#define HAVE_RL_COMPLETION_MATCHES 1
#define HAVE_RL_COMPLETION_SUPPRESS_APPEND 1
#define HAVE_RL_PRE_INPUT_HOOK 1
#define HAVE_RL_RESIZE_TERMINAL 1
#define HAVE_RPC_RPC_H 1
#define HAVE_SCHED_GET_PRIORITY_MAX 1
#define HAVE_SCHED_H 1
#define HAVE_SCHED_RR_GET_INTERVAL 1
#define HAVE_SCHED_SETAFFINITY 1
#define HAVE_SCHED_SETPARAM 1
#define HAVE_SCHED_SETSCHEDULER 1
#define HAVE_SEM_CLOCKWAIT 1
#define HAVE_SEM_GETVALUE 1
#define HAVE_SEM_OPEN 1
#define HAVE_SEM_TIMEDWAIT 1
#define HAVE_SEM_UNLINK 1
#define HAVE_SENDFILE 1
#define HAVE_SENDTO 1
#define HAVE_SETEGID 1
#define HAVE_SETEUID 1
#define HAVE_SETGID 1
#define HAVE_SETGROUPS 1
#define HAVE_SETHOSTNAME 1
#define HAVE_SETITIMER 1
#define HAVE_SETJMP_H 1
#define HAVE_SETLOCALE 1
#define HAVE_SETNS 1
#define HAVE_SETPGID 1
#define HAVE_SETPGRP 1
#define HAVE_SETPRIORITY 1
#define HAVE_SETREGID 1
#define HAVE_SETRESGID 1
#define HAVE_SETRESUID 1
#define HAVE_SETREUID 1
#define HAVE_SETSID 1
#define HAVE_SETSOCKOPT 1
#define HAVE_SETUID 1
#define HAVE_SETVBUF 1
#define HAVE_SHADOW_H 1
#define HAVE_SHM_OPEN 1
#define HAVE_SHM_UNLINK 1
#define HAVE_SHUTDOWN 1
#define HAVE_SIGACTION 1
#define HAVE_SIGALTSTACK 1
#define HAVE_SIGFILLSET 1
#define HAVE_SIGINFO_T_SI_BAND 1
#define HAVE_SIGINTERRUPT 1
#define HAVE_SIGNAL_H 1
#define HAVE_SIGPENDING 1
#define HAVE_SIGRELSE 1
#define HAVE_SIGTIMEDWAIT 1
#define HAVE_SIGWAIT 1
#define HAVE_SIGWAITINFO 1
#define HAVE_SNPRINTF 1
#define HAVE_SOCKADDR_ALG 1
#define HAVE_SOCKADDR_STORAGE 1
#define HAVE_SOCKET 1
#define HAVE_SOCKETPAIR 1
#define HAVE_SPAWN_H 1
#define HAVE_SPLICE 1
#define HAVE_SSIZE_T 1
#define HAVE_STATVFS 1
#define HAVE_STAT_TV_NSEC 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STD_ATOMIC 1
#define HAVE_STRFTIME 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_STRSIGNAL 1
#define HAVE_STRUCT_PASSWD_PW_GECOS 1
#define HAVE_STRUCT_PASSWD_PW_PASSWD 1
#define HAVE_STRUCT_STAT_ST_BLKSIZE 1
#define HAVE_STRUCT_STAT_ST_BLOCKS 1
#define HAVE_STRUCT_STAT_ST_RDEV 1
#define HAVE_STRUCT_TM_TM_ZONE 1
#define HAVE_SYMLINK 1
#define HAVE_SYMLINKAT 1
#define HAVE_SYNC 1
#define HAVE_SYSCONF 1
#define HAVE_SYSEXITS_H 1
#define HAVE_SYSLOG_H 1
#define HAVE_SYSTEM 1
#define HAVE_SYS_AUXV_H 1
#define HAVE_SYS_EPOLL_H 1
#define HAVE_SYS_EVENTFD_H 1
#define HAVE_SYS_FILE_H 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_POLL_H 1
#define HAVE_SYS_RANDOM_H 1
#define HAVE_SYS_RESOURCE_H 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_SYS_SENDFILE_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_SOUNDCARD_H 1
#define HAVE_SYS_STATVFS_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_SYSCALL_H 1
#define HAVE_SYS_SYSMACROS_H 1
#define HAVE_SYS_TIMES_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_UIO_H 1
#define HAVE_SYS_UN_H 1
#define HAVE_SYS_UTSNAME_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_SYS_XATTR_H 1
#define HAVE_TCGETPGRP 1
#define HAVE_TCSETPGRP 1
#define HAVE_TEMPNAM 1
#define HAVE_TERMIOS_H 1
#define HAVE_TERM_H 1
#define HAVE_TIMEGM 1
#define HAVE_TIMES 1
#define HAVE_TMPFILE 1
#define HAVE_TMPNAM 1
#define HAVE_TMPNAM_R 1
#define HAVE_TM_ZONE 1
#define HAVE_TRUNCATE 1
#define HAVE_TTYNAME 1
#define HAVE_UMASK 1
#define HAVE_UNAME 1
#define HAVE_UNISTD_H 1
#define HAVE_UNLINKAT 1
#define HAVE_UNSHARE 1
#define HAVE_UTIMENSAT 1
#define HAVE_UTIMES 1
#define HAVE_UTIME_H 1
#define HAVE_UTMP_H 1
#define HAVE_VFORK 1
#define HAVE_WAIT 1
#define HAVE_WAIT3 1
#define HAVE_WAIT4 1
#define HAVE_WAITID 1
#define HAVE_WAITPID 1
#define HAVE_WCHAR_H 1
#define HAVE_WCSCOLL 1
#define HAVE_WCSFTIME 1
#define HAVE_WCSXFRM 1
#define HAVE_WMEMCMP 1
#define HAVE_WORKING_TZSET 1
#define HAVE_WRITEV 1
#define HAVE_ZLIB_COPY 1
#define MVWDELCH_IS_EXPRESSION 1
#define MAJOR_IN_SYSMACROS 1
#define PTHREAD_KEY_T_IS_COMPATIBLE_WITH_INT 1
#define PTHREAD_SYSTEM_SCHED_SUPPORTED 1
#define PY_BUILTIN_HASHLIB_HASHES "md5,sha1,sha2,sha3,blake2"
#define PY_COERCE_C_LOCALE 1
#define PY_HAVE_PERF_TRAMPOLINE 1
#define PY_SQLITE_HAVE_SERIALIZE 1
#define PY_SSL_DEFAULT_CIPHERS 1
#define PY_SUPPORT_TIER 1
#define RETSIGTYPE void
#define SIZEOF_DOUBLE 8
#define SIZEOF_FLOAT 4
#define SIZEOF_FPOS_T 16
#define SIZEOF_INT 4
#define SIZEOF_LONG 8
#define SIZEOF_LONG_DOUBLE 16
#define SIZEOF_LONG_LONG 8
#define SIZEOF_OFF_T 8
#define SIZEOF_PID_T 4
#define SIZEOF_PTHREAD_KEY_T 4
#define SIZEOF_PTHREAD_T 8
#define SIZEOF_SHORT 2
#define SIZEOF_SIZE_T 8
#define SIZEOF_TIME_T 8
#define SIZEOF_UINTPTR_T 8
#define SIZEOF_VOID_P 8
#define SIZEOF_WCHAR_T 4
#define SIZEOF__BOOL 1
#define STDC_HEADERS 1
#define SYS_SELECT_WITH_SYS_TIME 1
#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
#ifndef _DARWIN_C_SOURCE
# define _DARWIN_C_SOURCE 1
#endif
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
#ifndef _HPUX_ALT_XOPEN_SOCKET_API
# define _HPUX_ALT_XOPEN_SOCKET_API 1
#endif
#ifndef _NETBSD_SOURCE
# define _NETBSD_SOURCE 1
#endif
#ifndef _OPENBSD_SOURCE
# define _OPENBSD_SOURCE 1
#endif
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
#ifndef __STDC_WANT_IEC_60559_ATTRIBS_EXT__
# define __STDC_WANT_IEC_60559_ATTRIBS_EXT__ 1
#endif
#ifndef __STDC_WANT_IEC_60559_BFP_EXT__
# define __STDC_WANT_IEC_60559_BFP_EXT__ 1
#endif
#ifndef __STDC_WANT_IEC_60559_DFP_EXT__
# define __STDC_WANT_IEC_60559_DFP_EXT__ 1
#endif
#ifndef __STDC_WANT_IEC_60559_FUNCS_EXT__
# define __STDC_WANT_IEC_60559_FUNCS_EXT__ 1
#endif
#ifndef __STDC_WANT_IEC_60559_TYPES_EXT__
# define __STDC_WANT_IEC_60559_TYPES_EXT__ 1
#endif
#ifndef __STDC_WANT_LIB_EXT2__
# define __STDC_WANT_LIB_EXT2__ 1
#endif
#ifndef __STDC_WANT_MATH_SPEC_FUNCS__
# define __STDC_WANT_MATH_SPEC_FUNCS__ 1
#endif
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
#ifndef _XOPEN_SOURCE
# define _XOPEN_SOURCE 700
#endif
#define WINDOW_HAS_FLAGS 1
#define WITH_DECIMAL_CONTEXTVAR 1
#define WITH_DOC_STRINGS 1
#define WITH_FREELISTS 1
#define WITH_PYMALLOC 1
#if defined AC_APPLE_UNIVERSAL_BUILD
# if defined __BIG_ENDIAN__
#  define WORDS_BIGENDIAN 1
# endif
#else
# ifndef WORDS_BIGENDIAN
# endif
#endif
#define _DARWIN_C_SOURCE 1
#define _FILE_OFFSET_BITS 64
#define _LARGEFILE_SOURCE 1
#define _NETBSD_SOURCE 1
#define _POSIX_C_SOURCE 200809L
#define _PYTHONFRAMEWORK ""
#define _REENTRANT 1
#define _XOPEN_SOURCE 700
#define _XOPEN_SOURCE_EXTENDED 1
#define __BSD_VISIBLE 1
#if defined(__USLC__) && defined(__SCO_VERSION__)
#define STRICT_SYSV_CURSES /* Don't use ncurses extensions */
#endif
#endif /*Py_PYCONFIG_H*/
E_O_F
''',
)
