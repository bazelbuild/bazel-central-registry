"""Contains forwarding declarations to rules that should only ever be used by
`googleapis` itself (i.e. these rules come from dev-dependencies).

Do NOT directly load from this file. Always use `@com_google_googleapis_imports//:imports.bzl`
instead!
"""

load(
    "@rules_gapic//:gapic.bzl",
    _proto_library_with_info = "proto_library_with_info",
    _moved_proto_library = "moved_proto_library",
)
load(
    "@gapic_generator_java//rules_java_gapic:java_gapic.bzl",
    _java_gapic_library = "java_gapic_library",
    _java_gapic_test = "java_gapic_test",
)
load(
    "@gapic_generator_java//rules_java_gapic:java_gapic_pkg.bzl",
    _java_gapic_assembly_gradle_pkg = "java_gapic_assembly_gradle_pkg",
)
load(
    "@gapic_generator_python//rules_python_gapic:py_gapic.bzl",
    _py_gapic_library = "py_gapic_library",
)
load(
    "@gapic_generator_python//rules_python_gapic:py_gapic_pkg.bzl",
    _py_gapic_assembly_pkg = "py_gapic_assembly_pkg",
)
load(
    "@com_googleapis_gapic_generator_go//rules_go_gapic:go_gapic.bzl",
    _go_gapic_library = "go_gapic_library",
)
load(
    "@com_googleapis_gapic_generator_go//rules_go_gapic:go_gapic_pkg.bzl",
    _go_gapic_assembly_pkg = "go_gapic_assembly_pkg",
)
load(
    "@gapic_generator_php//rules_php_gapic:php_gapic.bzl",
    _php_proto_library = "php_proto_library",
    _php_grpc_library = "php_grpc_library",
    _php_gapic_library = "php_gapic_library",
)
load(
    "@gapic_generator_php//rules_php_gapic:php_gapic_pkg.bzl",
    _php_gapic_assembly_pkg = "php_gapic_assembly_pkg",
)
load(
    "@gapic_generator_typescript//rules_typescript_gapic:typescript_gapic.bzl",
    _typescript_gapic_library = "typescript_gapic_library",
)
load(
    "@gapic_generator_typescript//rules_typescript_gapic:typescript_gapic_pkg.bzl",
    _typescript_gapic_assembly_pkg = "typescript_gapic_assembly_pkg",
)
load(
    "@gapic_generator_ruby//rules_ruby_gapic:ruby_gapic.bzl",
    _ruby_proto_library = "ruby_proto_library",
    _ruby_grpc_library = "ruby_grpc_library",
    _ruby_ads_gapic_library = "ruby_ads_gapic_library",
    _ruby_cloud_gapic_library = "ruby_cloud_gapic_library",
)
load(
    "@gapic_generator_ruby//rules_ruby_gapic:ruby_gapic_pkg.bzl",
    _ruby_gapic_assembly_pkg = "ruby_gapic_assembly_pkg",
)
load(
    "@rules_gapic//csharp:csharp_gapic.bzl",
    _csharp_proto_library = "csharp_proto_library",
    _csharp_grpc_library = "csharp_grpc_library",
)
load(
    "@gapic_generator_csharp//rules_csharp_gapic:csharp_gapic.bzl",
    _csharp_gapic_library = "csharp_gapic_library",
)
load(
    "@gapic_generator_csharp//rules_csharp_gapic:csharp_gapic_pkg.bzl",
    _csharp_gapic_assembly_pkg = "csharp_gapic_assembly_pkg",
)

# Common
proto_library_with_info = _proto_library_with_info
moved_proto_library = _moved_proto_library

# Java
java_gapic_library = _java_gapic_library
java_gapic_test = _java_gapic_test
java_gapic_assembly_gradle_pkg = _java_gapic_assembly_gradle_pkg

# Python
py_gapic_library = _py_gapic_library
py_test = native.py_test
py_gapic_assembly_pkg = _py_gapic_assembly_pkg

# Go
def go_test(**kwargs): pass
go_gapic_library = _go_gapic_library
go_gapic_assembly_pkg = _go_gapic_assembly_pkg

# C++
def cc_gapic_library(**kwargs): pass

# PHP
php_proto_library = _php_proto_library
php_grpc_library = _php_grpc_library
php_gapic_library = _php_gapic_library
php_gapic_assembly_pkg = _php_gapic_assembly_pkg

# Node.js
nodejs_gapic_library = _typescript_gapic_library
nodejs_gapic_assembly_pkg = _typescript_gapic_assembly_pkg

# Ruby
ruby_proto_library = _ruby_proto_library
ruby_grpc_library = _ruby_grpc_library
ruby_ads_gapic_library = _ruby_ads_gapic_library
ruby_cloud_gapic_library = _ruby_cloud_gapic_library
ruby_gapic_assembly_pkg = _ruby_gapic_assembly_pkg

# C#
csharp_proto_library = _csharp_proto_library
csharp_grpc_library = _csharp_grpc_library
csharp_gapic_library = _csharp_gapic_library
csharp_gapic_assembly_pkg = _csharp_gapic_assembly_pkg

