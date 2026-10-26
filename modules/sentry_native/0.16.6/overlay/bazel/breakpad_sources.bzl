"""Exact source manifests for the sentry-native Breakpad fork.

When updating the overlay, compare normalized path multisets with
external/CMakeLists.txt so platform selections remain explicit.
"""

# These groups mirror //external:CMakeLists.txt. Header discovery remains
# separate so the manifests cannot accidentally compile Breakpad tests/tools.

BREAKPAD_SOURCES_COMMON = [
    "//:external/breakpad/src/common/convert_UTF.cc",
    "//:external/breakpad/src/common/md5.cc",
    "//:external/breakpad/src/common/string_conversion.cc",
]

BREAKPAD_SOURCES_COMMON_LINUX = [
    "//:external/breakpad/src/common/linux/elf_core_dump.cc",
    "//:external/breakpad/src/common/linux/elfutils.cc",
    "//:external/breakpad/src/common/linux/file_id.cc",
    "//:external/breakpad/src/common/linux/guid_creator.cc",
    "//:external/breakpad/src/common/linux/linux_libc_support.cc",
    "//:external/breakpad/src/common/linux/memory_mapped_file.cc",
    "//:external/breakpad/src/common/linux/safe_readlink.cc",
    "//:external/breakpad/src/common/linux/scoped_pipe.cc",
    "//:external/breakpad/src/common/linux/scoped_tmpfile.cc",
]

BREAKPAD_SOURCES_COMMON_LINUX_GETCONTEXT = [
    # Upstream conditionally selects this fallback after probing the target
    # libc for getcontext(). Bazel cross-builds cannot run that probe
    # hermetically, so supported Linux architectures always use Breakpad's
    # bundled implementation. breakpad_getcontext.h remaps calls to its unique
    # symbol, avoiding a collision when libc also exports getcontext().
    "//:external/breakpad/src/common/linux/breakpad_getcontext.S",
]

BREAKPAD_SOURCES_COMMON_APPLE = [
    "//:external/breakpad/src/common/mac/arch_utilities.cc",
    "//:external/breakpad/src/common/mac/file_id.cc",
    "//:external/breakpad/src/common/mac/macho_id.cc",
    "//:external/breakpad/src/common/mac/macho_utilities.cc",
    "//:external/breakpad/src/common/mac/macho_walker.cc",
    "//:external/breakpad/src/common/mac/string_utilities.cc",
]

BREAKPAD_SOURCES_COMMON_MAC = [
    "//:external/breakpad/src/common/mac/bootstrap_compat.cc",
]

BREAKPAD_SOURCES_CLIENT_LINUX = [
    "//:external/breakpad/src/client/minidump_file_writer.cc",
    "//:external/breakpad/src/client/linux/crash_generation/crash_generation_client.cc",
    "//:external/breakpad/src/client/linux/crash_generation/crash_generation_server.cc",
    "//:external/breakpad/src/client/linux/dump_writer_common/thread_info.cc",
    "//:external/breakpad/src/client/linux/dump_writer_common/ucontext_reader.cc",
    "//:external/breakpad/src/client/linux/handler/exception_handler.cc",
    "//:external/breakpad/src/client/linux/handler/minidump_descriptor.cc",
    "//:external/breakpad/src/client/linux/log/log.cc",
    "//:external/breakpad/src/client/linux/microdump_writer/microdump_writer.cc",
    "//:external/breakpad/src/client/linux/minidump_writer/linux_core_dumper.cc",
    "//:external/breakpad/src/client/linux/minidump_writer/linux_dumper.cc",
    "//:external/breakpad/src/client/linux/minidump_writer/linux_ptrace_dumper.cc",
    "//:external/breakpad/src/client/linux/minidump_writer/minidump_writer.cc",
    "//:external/breakpad/src/client/linux/minidump_writer/pe_file.cc",
]

BREAKPAD_SOURCES_CLIENT_APPLE = [
    "//:external/breakpad/src/client/minidump_file_writer.cc",
    "//:external/breakpad/src/client/mac/handler/breakpad_nlist_64.cc",
    "//:external/breakpad/src/client/mac/handler/dynamic_images.cc",
    "//:external/breakpad/src/client/mac/handler/minidump_generator.cc",
]

BREAKPAD_SOURCES_CLIENT_MAC = [
    "//:external/breakpad/src/client/mac/crash_generation/crash_generation_client.cc",
    "//:external/breakpad/src/client/mac/handler/exception_handler.cc",
]

BREAKPAD_HEADERS_COMMON = [
    "//:external/breakpad/src/client/minidump_file_writer-inl.h",
    "//:external/breakpad/src/client/minidump_file_writer.h",
    "//:external/breakpad/src/common/basictypes.h",
    "//:external/breakpad/src/common/convert_UTF.h",
    "//:external/breakpad/src/common/macros.h",
    "//:external/breakpad/src/common/md5.h",
    "//:external/breakpad/src/common/memory_allocator.h",
    "//:external/breakpad/src/common/memory_range.h",
    "//:external/breakpad/src/common/minidump_type_helper.h",
    "//:external/breakpad/src/common/scoped_ptr.h",
    "//:external/breakpad/src/common/string_conversion.h",
    "//:external/breakpad/src/common/using_std_string.h",
    "//:external/breakpad/src/google_breakpad/common/breakpad_types.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_amd64.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_arm.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_arm64.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_mips.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_ppc.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_ppc64.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_riscv.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_sparc.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_cpu_x86.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_exception_fuchsia.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_exception_linux.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_exception_mac.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_exception_ps3.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_exception_solaris.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_exception_win32.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_format.h",
    "//:external/breakpad/src/google_breakpad/common/minidump_size.h",
]

BREAKPAD_HEADERS_LINUX = [
    "//:external/breakpad/src/client/linux/crash_generation/client_info.h",
    "//:external/breakpad/src/client/linux/crash_generation/crash_generation_client.h",
    "//:external/breakpad/src/client/linux/crash_generation/crash_generation_server.h",
    "//:external/breakpad/src/client/linux/dump_writer_common/mapping_info.h",
    "//:external/breakpad/src/client/linux/dump_writer_common/raw_context_cpu.h",
    "//:external/breakpad/src/client/linux/dump_writer_common/thread_info.h",
    "//:external/breakpad/src/client/linux/dump_writer_common/ucontext_reader.h",
    "//:external/breakpad/src/client/linux/handler/exception_handler.h",
    "//:external/breakpad/src/client/linux/handler/microdump_extra_info.h",
    "//:external/breakpad/src/client/linux/handler/minidump_descriptor.h",
    "//:external/breakpad/src/client/linux/log/log.h",
    "//:external/breakpad/src/client/linux/microdump_writer/microdump_writer.h",
    "//:external/breakpad/src/client/linux/minidump_writer/cpu_set.h",
    "//:external/breakpad/src/client/linux/minidump_writer/directory_reader.h",
    "//:external/breakpad/src/client/linux/minidump_writer/line_reader.h",
    "//:external/breakpad/src/client/linux/minidump_writer/linux_core_dumper.h",
    "//:external/breakpad/src/client/linux/minidump_writer/linux_dumper.h",
    "//:external/breakpad/src/client/linux/minidump_writer/linux_ptrace_dumper.h",
    "//:external/breakpad/src/client/linux/minidump_writer/minidump_writer.h",
    "//:external/breakpad/src/client/linux/minidump_writer/pe_file.h",
    "//:external/breakpad/src/client/linux/minidump_writer/pe_structs.h",
    "//:external/breakpad/src/client/linux/minidump_writer/proc_cpuinfo_reader.h",
    "//:external/breakpad/src/common/linux/breakpad_getcontext.h",
    "//:external/breakpad/src/common/linux/eintr_wrapper.h",
    "//:external/breakpad/src/common/linux/elf_core_dump.h",
    "//:external/breakpad/src/common/linux/elf_gnu_compat.h",
    "//:external/breakpad/src/common/linux/elfutils-inl.h",
    "//:external/breakpad/src/common/linux/elfutils.h",
    "//:external/breakpad/src/common/linux/file_id.h",
    "//:external/breakpad/src/common/linux/guid_creator.h",
    "//:external/breakpad/src/common/linux/ignore_ret.h",
    "//:external/breakpad/src/common/linux/linux_libc_support.h",
    "//:external/breakpad/src/common/linux/memory_mapped_file.h",
    "//:external/breakpad/src/common/linux/safe_readlink.h",
    "//:external/breakpad/src/common/linux/scoped_pipe.h",
    "//:external/breakpad/src/common/linux/scoped_tmpfile.h",
    "//:external/breakpad/src/common/linux/ucontext_constants.h",
]

BREAKPAD_HEADERS_MACOS = [
    "//:external/breakpad/src/client/mac/crash_generation/crash_generation_client.h",
    "//:external/breakpad/src/client/mac/crash_generation/crash_generation_server.h",
    "//:external/breakpad/src/client/mac/handler/breakpad_nlist_64.h",
    "//:external/breakpad/src/client/mac/handler/dynamic_images.h",
    "//:external/breakpad/src/client/mac/handler/exception_handler.h",
    "//:external/breakpad/src/client/mac/handler/mach_vm_compat.h",
    "//:external/breakpad/src/client/mac/handler/minidump_generator.h",
    "//:external/breakpad/src/client/mac/handler/ucontext_compat.h",
    "//:external/breakpad/src/common/linux/eintr_wrapper.h",
    "//:external/breakpad/src/common/linux/elf_core_dump.h",
    "//:external/breakpad/src/common/linux/elf_gnu_compat.h",
    "//:external/breakpad/src/common/linux/elfutils-inl.h",
    "//:external/breakpad/src/common/linux/elfutils.h",
    "//:external/breakpad/src/common/linux/file_id.h",
    "//:external/breakpad/src/common/linux/guid_creator.h",
    "//:external/breakpad/src/common/linux/linux_libc_support.h",
    "//:external/breakpad/src/common/linux/memory_mapped_file.h",
    "//:external/breakpad/src/common/linux/safe_readlink.h",
    "//:external/breakpad/src/common/linux/scoped_pipe.h",
    "//:external/breakpad/src/common/linux/scoped_tmpfile.h",
    "//:external/breakpad/src/common/linux/ucontext_constants.h",
    "//:external/breakpad/src/common/mac/MachIPC.h",
    "//:external/breakpad/src/common/mac/arch_utilities.h",
    "//:external/breakpad/src/common/mac/bootstrap_compat.h",
    "//:external/breakpad/src/common/mac/byteswap.h",
    "//:external/breakpad/src/common/mac/file_id.h",
    "//:external/breakpad/src/common/mac/macho_id.h",
    "//:external/breakpad/src/common/mac/macho_utilities.h",
    "//:external/breakpad/src/common/mac/macho_walker.h",
    "//:external/breakpad/src/common/mac/scoped_task_suspend-inl.h",
    "//:external/breakpad/src/common/mac/string_utilities.h",
]
