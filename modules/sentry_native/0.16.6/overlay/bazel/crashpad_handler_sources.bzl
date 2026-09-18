"""Exact snapshot, minidump, and handler manifests for Crashpad.

When updating the overlay, compare normalized path multisets with the upstream
Crashpad targets so snapshot, minidump, and handler boundaries remain explicit.
"""

CRASHPAD_SNAPSHOT_COMMON_SRCS = [
    "external/crashpad/snapshot/annotation_snapshot.cc",
    "external/crashpad/snapshot/capture_memory.cc",
    "external/crashpad/snapshot/cpu_context.cc",
    "external/crashpad/snapshot/crashpad_info_client_options.cc",
    "external/crashpad/snapshot/handle_snapshot.cc",
    "external/crashpad/snapshot/memory_snapshot.cc",
    "external/crashpad/snapshot/minidump/exception_snapshot_minidump.cc",
    "external/crashpad/snapshot/minidump/memory_snapshot_minidump.cc",
    "external/crashpad/snapshot/minidump/minidump_annotation_reader.cc",
    "external/crashpad/snapshot/minidump/minidump_context_converter.cc",
    "external/crashpad/snapshot/minidump/minidump_simple_string_dictionary_reader.cc",
    "external/crashpad/snapshot/minidump/minidump_string_list_reader.cc",
    "external/crashpad/snapshot/minidump/minidump_string_reader.cc",
    "external/crashpad/snapshot/minidump/module_snapshot_minidump.cc",
    "external/crashpad/snapshot/minidump/process_snapshot_minidump.cc",
    "external/crashpad/snapshot/minidump/system_snapshot_minidump.cc",
    "external/crashpad/snapshot/minidump/thread_snapshot_minidump.cc",
    "external/crashpad/snapshot/unloaded_module_snapshot.cc",
]

CRASHPAD_SNAPSHOT_COMMON_HDRS = [
    "external/crashpad/minidump/minidump_context.h",
    "external/crashpad/minidump/minidump_extensions.h",
    "external/crashpad/snapshot/annotation_snapshot.h",
    "external/crashpad/snapshot/capture_memory.h",
    "external/crashpad/snapshot/cpu_architecture.h",
    "external/crashpad/snapshot/cpu_context.h",
    "external/crashpad/snapshot/crashpad_info_client_options.h",
    "external/crashpad/snapshot/exception_snapshot.h",
    "external/crashpad/snapshot/handle_snapshot.h",
    "external/crashpad/snapshot/memory_map_region_snapshot.h",
    "external/crashpad/snapshot/memory_snapshot.h",
    "external/crashpad/snapshot/memory_snapshot_generic.h",
    "external/crashpad/snapshot/minidump/exception_snapshot_minidump.h",
    "external/crashpad/snapshot/minidump/memory_snapshot_minidump.h",
    "external/crashpad/snapshot/minidump/minidump_annotation_reader.h",
    "external/crashpad/snapshot/minidump/minidump_context_converter.h",
    "external/crashpad/snapshot/minidump/minidump_simple_string_dictionary_reader.h",
    "external/crashpad/snapshot/minidump/minidump_stream.h",
    "external/crashpad/snapshot/minidump/minidump_string_list_reader.h",
    "external/crashpad/snapshot/minidump/minidump_string_reader.h",
    "external/crashpad/snapshot/minidump/module_snapshot_minidump.h",
    "external/crashpad/snapshot/minidump/process_snapshot_minidump.h",
    "external/crashpad/snapshot/minidump/system_snapshot_minidump.h",
    "external/crashpad/snapshot/minidump/thread_snapshot_minidump.h",
    "external/crashpad/snapshot/module_snapshot.h",
    "external/crashpad/snapshot/process_snapshot.h",
    "external/crashpad/snapshot/snapshot_constants.h",
    "external/crashpad/snapshot/system_snapshot.h",
    "external/crashpad/snapshot/thread_snapshot.h",
    "external/crashpad/snapshot/unloaded_module_snapshot.h",
]

CRASHPAD_SNAPSHOT_LINUX_SRCS = [
    "external/crashpad/snapshot/crashpad_types/crashpad_info_reader.cc",
    "external/crashpad/snapshot/crashpad_types/image_annotation_reader.cc",
    "external/crashpad/snapshot/elf/elf_dynamic_array_reader.cc",
    "external/crashpad/snapshot/elf/elf_image_reader.cc",
    "external/crashpad/snapshot/elf/elf_symbol_table_reader.cc",
    "external/crashpad/snapshot/elf/module_snapshot_elf.cc",
    "external/crashpad/snapshot/linux/capture_memory_delegate_linux.cc",
    "external/crashpad/snapshot/linux/cpu_context_linux.cc",
    "external/crashpad/snapshot/linux/debug_rendezvous.cc",
    "external/crashpad/snapshot/linux/exception_snapshot_linux.cc",
    "external/crashpad/snapshot/linux/process_reader_linux.cc",
    "external/crashpad/snapshot/linux/process_snapshot_linux.cc",
    "external/crashpad/snapshot/linux/system_snapshot_linux.cc",
    "external/crashpad/snapshot/linux/thread_snapshot_linux.cc",
    "external/crashpad/snapshot/posix/timezone.cc",
    "external/crashpad/snapshot/sanitized/memory_snapshot_sanitized.cc",
    "external/crashpad/snapshot/sanitized/module_snapshot_sanitized.cc",
    "external/crashpad/snapshot/sanitized/process_snapshot_sanitized.cc",
    "external/crashpad/snapshot/sanitized/sanitization_information.cc",
    "external/crashpad/snapshot/sanitized/thread_snapshot_sanitized.cc",
]

CRASHPAD_SNAPSHOT_LINUX_HDRS = [
    "external/crashpad/snapshot/crashpad_types/crashpad_info_reader.h",
    "external/crashpad/snapshot/crashpad_types/image_annotation_reader.h",
    "external/crashpad/snapshot/elf/elf_dynamic_array_reader.h",
    "external/crashpad/snapshot/elf/elf_image_reader.h",
    "external/crashpad/snapshot/elf/elf_symbol_table_reader.h",
    "external/crashpad/snapshot/elf/module_snapshot_elf.h",
    "external/crashpad/snapshot/linux/capture_memory_delegate_linux.h",
    "external/crashpad/snapshot/linux/cpu_context_linux.h",
    "external/crashpad/snapshot/linux/debug_rendezvous.h",
    "external/crashpad/snapshot/linux/exception_snapshot_linux.h",
    "external/crashpad/snapshot/linux/process_reader_linux.h",
    "external/crashpad/snapshot/linux/process_snapshot_linux.h",
    "external/crashpad/snapshot/linux/signal_context.h",
    "external/crashpad/snapshot/linux/system_snapshot_linux.h",
    "external/crashpad/snapshot/linux/thread_snapshot_linux.h",
    "external/crashpad/snapshot/posix/timezone.h",
    "external/crashpad/snapshot/sanitized/memory_snapshot_sanitized.h",
    "external/crashpad/snapshot/sanitized/module_snapshot_sanitized.h",
    "external/crashpad/snapshot/sanitized/process_snapshot_sanitized.h",
    "external/crashpad/snapshot/sanitized/sanitization_information.h",
    "external/crashpad/snapshot/sanitized/thread_snapshot_sanitized.h",
]

CRASHPAD_SNAPSHOT_MACOS_SRCS = [
    "external/crashpad/snapshot/mac/cpu_context_mac.cc",
    "external/crashpad/snapshot/mac/exception_snapshot_mac.cc",
    "external/crashpad/snapshot/mac/mach_o_image_annotations_reader.cc",
    "external/crashpad/snapshot/mac/mach_o_image_reader.cc",
    "external/crashpad/snapshot/mac/mach_o_image_segment_reader.cc",
    "external/crashpad/snapshot/mac/mach_o_image_symbol_table_reader.cc",
    "external/crashpad/snapshot/mac/module_snapshot_mac.cc",
    "external/crashpad/snapshot/mac/process_reader_mac.cc",
    "external/crashpad/snapshot/mac/process_snapshot_mac.cc",
    "external/crashpad/snapshot/mac/process_types.cc",
    "external/crashpad/snapshot/mac/process_types/custom.cc",
    "external/crashpad/snapshot/mac/system_snapshot_mac.cc",
    "external/crashpad/snapshot/mac/thread_snapshot_mac.cc",
    "external/crashpad/snapshot/posix/timezone.cc",
]

CRASHPAD_SNAPSHOT_MACOS_HDRS = [
    "external/crashpad/snapshot/mac/cpu_context_mac.h",
    "external/crashpad/snapshot/mac/exception_snapshot_mac.h",
    "external/crashpad/snapshot/mac/mach_o_image_annotations_reader.h",
    "external/crashpad/snapshot/mac/mach_o_image_reader.h",
    "external/crashpad/snapshot/mac/mach_o_image_segment_reader.h",
    "external/crashpad/snapshot/mac/mach_o_image_symbol_table_reader.h",
    "external/crashpad/snapshot/mac/module_snapshot_mac.h",
    "external/crashpad/snapshot/mac/process_reader_mac.h",
    "external/crashpad/snapshot/mac/process_snapshot_mac.h",
    "external/crashpad/snapshot/mac/process_types.h",
    "external/crashpad/snapshot/mac/process_types/flavors.h",
    "external/crashpad/snapshot/mac/process_types/internal.h",
    "external/crashpad/snapshot/mac/process_types/traits.h",
    "external/crashpad/snapshot/mac/system_snapshot_mac.h",
    "external/crashpad/snapshot/mac/thread_snapshot_mac.h",
    "external/crashpad/snapshot/posix/timezone.h",
]

CRASHPAD_SNAPSHOT_MACOS_TEXTUAL_HDRS = [
    "external/crashpad/snapshot/mac/process_types/all.proctype",
    "external/crashpad/snapshot/mac/process_types/annotation.proctype",
    "external/crashpad/snapshot/mac/process_types/crashpad_info.proctype",
    "external/crashpad/snapshot/mac/process_types/crashreporterclient.proctype",
    "external/crashpad/snapshot/mac/process_types/dyld_images.proctype",
    "external/crashpad/snapshot/mac/process_types/loader.proctype",
    "external/crashpad/snapshot/mac/process_types/nlist.proctype",
]

CRASHPAD_SNAPSHOT_X86_SRCS = ["external/crashpad/snapshot/x86/cpuid_reader.cc"]
CRASHPAD_SNAPSHOT_X86_HDRS = ["external/crashpad/snapshot/x86/cpuid_reader.h"]

CRASHPAD_MINIDUMP_SRCS = [
    "external/crashpad/minidump/minidump_annotation_writer.cc",
    "external/crashpad/minidump/minidump_byte_array_writer.cc",
    "external/crashpad/minidump/minidump_context_writer.cc",
    "external/crashpad/minidump/minidump_crashpad_info_writer.cc",
    "external/crashpad/minidump/minidump_exception_writer.cc",
    "external/crashpad/minidump/minidump_extensions.cc",
    "external/crashpad/minidump/minidump_file_writer.cc",
    "external/crashpad/minidump/minidump_handle_writer.cc",
    "external/crashpad/minidump/minidump_memory_info_writer.cc",
    "external/crashpad/minidump/minidump_memory_writer.cc",
    "external/crashpad/minidump/minidump_misc_info_writer.cc",
    "external/crashpad/minidump/minidump_module_crashpad_info_writer.cc",
    "external/crashpad/minidump/minidump_module_writer.cc",
    "external/crashpad/minidump/minidump_rva_list_writer.cc",
    "external/crashpad/minidump/minidump_simple_string_dictionary_writer.cc",
    "external/crashpad/minidump/minidump_stream_writer.cc",
    "external/crashpad/minidump/minidump_string_writer.cc",
    "external/crashpad/minidump/minidump_system_info_writer.cc",
    "external/crashpad/minidump/minidump_thread_id_map.cc",
    "external/crashpad/minidump/minidump_thread_name_list_writer.cc",
    "external/crashpad/minidump/minidump_thread_writer.cc",
    "external/crashpad/minidump/minidump_unloaded_module_writer.cc",
    "external/crashpad/minidump/minidump_user_extension_stream_data_source.cc",
    "external/crashpad/minidump/minidump_user_stream_writer.cc",
    "external/crashpad/minidump/minidump_writable.cc",
    "external/crashpad/minidump/minidump_writer_util.cc",
]

CRASHPAD_MINIDUMP_HDRS = [
    "external/crashpad/minidump/minidump_annotation_writer.h",
    "external/crashpad/minidump/minidump_byte_array_writer.h",
    "external/crashpad/minidump/minidump_context.h",
    "external/crashpad/minidump/minidump_context_writer.h",
    "external/crashpad/minidump/minidump_crashpad_info_writer.h",
    "external/crashpad/minidump/minidump_exception_writer.h",
    "external/crashpad/minidump/minidump_extensions.h",
    "external/crashpad/minidump/minidump_file_writer.h",
    "external/crashpad/minidump/minidump_handle_writer.h",
    "external/crashpad/minidump/minidump_memory_info_writer.h",
    "external/crashpad/minidump/minidump_memory_writer.h",
    "external/crashpad/minidump/minidump_misc_info_writer.h",
    "external/crashpad/minidump/minidump_module_crashpad_info_writer.h",
    "external/crashpad/minidump/minidump_module_writer.h",
    "external/crashpad/minidump/minidump_rva_list_writer.h",
    "external/crashpad/minidump/minidump_simple_string_dictionary_writer.h",
    "external/crashpad/minidump/minidump_stream_writer.h",
    "external/crashpad/minidump/minidump_string_writer.h",
    "external/crashpad/minidump/minidump_system_info_writer.h",
    "external/crashpad/minidump/minidump_thread_id_map.h",
    "external/crashpad/minidump/minidump_thread_name_list_writer.h",
    "external/crashpad/minidump/minidump_thread_writer.h",
    "external/crashpad/minidump/minidump_unloaded_module_writer.h",
    "external/crashpad/minidump/minidump_user_extension_stream_data_source.h",
    "external/crashpad/minidump/minidump_user_stream_writer.h",
    "external/crashpad/minidump/minidump_writable.h",
    "external/crashpad/minidump/minidump_writer_util.h",
]

CRASHPAD_HANDLER_COMMON_SRCS = [
    "external/crashpad/handler/crash_report_upload_rate_limit.cc",
    "external/crashpad/handler/crash_report_upload_thread.cc",
    "external/crashpad/handler/handler_main.cc",
    "external/crashpad/handler/minidump_to_upload_parameters.cc",
    "external/crashpad/handler/prune_crash_reports_thread.cc",
    "external/crashpad/handler/user_stream_data_source.cc",
]

CRASHPAD_HANDLER_COMMON_HDRS = [
    "external/crashpad/handler/crash_report_upload_rate_limit.h",
    "external/crashpad/handler/crash_report_upload_thread.h",
    "external/crashpad/handler/handler_main.h",
    "external/crashpad/handler/minidump_to_upload_parameters.h",
    "external/crashpad/handler/prune_crash_reports_thread.h",
    "external/crashpad/handler/user_stream_data_source.h",
]

CRASHPAD_HANDLER_LINUX_SRCS = [
    "external/crashpad/handler/linux/capture_snapshot.cc",
    "external/crashpad/handler/linux/crash_report_exception_handler.cc",
    "external/crashpad/handler/linux/cros_crash_report_exception_handler.cc",
    "external/crashpad/handler/linux/exception_handler_server.cc",
]

CRASHPAD_HANDLER_LINUX_HDRS = [
    "external/crashpad/handler/linux/capture_snapshot.h",
    "external/crashpad/handler/linux/crash_report_exception_handler.h",
    "external/crashpad/handler/linux/cros_crash_report_exception_handler.h",
    "external/crashpad/handler/linux/exception_handler_server.h",
]

CRASHPAD_HANDLER_MACOS_SRCS = [
    "external/crashpad/handler/mac/crash_report_exception_handler.cc",
    "external/crashpad/handler/mac/exception_handler_server.cc",
    "external/crashpad/handler/mac/file_limit_annotation.cc",
]

CRASHPAD_HANDLER_MACOS_HDRS = [
    "external/crashpad/handler/mac/crash_report_exception_handler.h",
    "external/crashpad/handler/mac/exception_handler_server.h",
    "external/crashpad/handler/mac/file_limit_annotation.h",
]
