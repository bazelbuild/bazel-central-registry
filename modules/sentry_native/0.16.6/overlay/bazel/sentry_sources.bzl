"""Explicit sentry-native source manifests derived from upstream CMake."""

# Keep compiled source lists explicit: broad globs can silently add tests,
# tools, or mutually exclusive platforms when the upstream release changes.

COMMON_SRCS = [
    "src/path/sentry_path.c",
    "src/screenshot/sentry_screenshot.c",
    "src/sentry_alloc.c",
    "src/sentry_app_hang_latch.c",
    "src/sentry_app_hang_monitor.c",
    "src/sentry_attachment.c",
    "src/sentry_backend.c",
    "src/sentry_batcher.c",
    "src/sentry_client_report.c",
    "src/sentry_core.c",
    "src/sentry_database.c",
    "src/sentry_envelope.c",
    "src/sentry_hint.c",
    "src/sentry_info.c",
    "src/sentry_json.c",
    "src/sentry_logger.c",
    "src/sentry_logs.c",
    "src/sentry_metrics.c",
    "src/sentry_options.c",
    "src/sentry_os.c",
    "src/sentry_ratelimiter.c",
    "src/sentry_retry.c",
    "src/sentry_ringbuffer.c",
    "src/sentry_scope.c",
    "src/sentry_session.c",
    "src/sentry_slice.c",
    "src/sentry_string.c",
    "src/sentry_sync.c",
    "src/sentry_telemetry.c",
    "src/sentry_tracing.c",
    "src/sentry_transport.c",
    "src/sentry_utils.c",
    "src/sentry_uuid.c",
    "src/sentry_value.c",
    "src/sentry_writer.c",
    "src/session_replay/sentry_session_replay.c",
    "src/transports/sentry_function_transport.c",
    "src/transports/sentry_http_transport.c",
    "src/unwinder/sentry_unwinder.c",
]

COMMON_PRIVATE_HDRS = [
    "src/sentry_alloc.h",
    "src/sentry_app_hang_latch.h",
    "src/sentry_app_hang_monitor.h",
    "src/sentry_attachment.h",
    "src/sentry_backend.h",
    "src/sentry_batcher.h",
    "src/sentry_boot.h",
    "src/sentry_client_report.h",
    "src/sentry_core.h",
    "src/sentry_cpu_relax.h",
    "src/sentry_database.h",
    "src/sentry_elf.h",
    "src/sentry_envelope.h",
    "src/sentry_hint.h",
    "src/sentry_integration.h",
    "src/sentry_json.h",
    "src/sentry_logger.h",
    "src/sentry_logs.h",
    "src/sentry_metrics.h",
    "src/sentry_options.h",
    "src/sentry_os.h",
    "src/sentry_path.h",
    "src/sentry_process.h",
    "src/sentry_random.h",
    "src/sentry_ratelimiter.h",
    "src/sentry_retry.h",
    "src/sentry_ringbuffer.h",
    "src/sentry_sampling_context.h",
    "src/sentry_scope.h",
    "src/sentry_screenshot.h",
    "src/sentry_session.h",
    "src/sentry_session_replay.h",
    "src/sentry_slice.h",
    "src/sentry_string.h",
    "src/sentry_symbolizer.h",
    "src/sentry_sync.h",
    "src/sentry_telemetry.h",
    "src/sentry_thread_stackwalk.h",
    "src/sentry_tracing.h",
    "src/sentry_transport.h",
    "src/sentry_tsan.h",
    "src/sentry_unix_pageallocator.h",
    "src/sentry_unix_spinlock.h",
    "src/sentry_utils.h",
    "src/sentry_uuid.h",
    "src/sentry_value.h",
    "src/sentry_writer.h",
    "src/transports/sentry_http_transport.h",
    "src/unwinder/sentry_unwinder.h",
    "vendor/jsmn.h",
]

UNIX_SRCS = [
    "src/path/sentry_path_unix.c",
    "src/process/sentry_process_unix.c",
    "src/sentry_random.c",
    "src/sentry_unix_pageallocator.c",
    "src/symbolizer/sentry_symbolizer_unix.c",
]

LINUX_SRCS = [
    "src/modulefinder/sentry_modulefinder_linux.c",
    "src/modulefinder/sentry_modulefinder_linux.h",
    "src/sentry_thread_stackwalk_posix.c",
    "src/unwinder/sentry_unwinder_libunwind.c",
    "vendor/stb_sprintf.c",
    "vendor/stb_sprintf.h",
]

MACOS_SRCS = [
    "src/modulefinder/sentry_modulefinder_apple.c",
    "src/sentry_thread_stackwalk_mach.c",
    "src/unwinder/sentry_unwinder_libunwind_mac.c",
]

DEFAULT_FEATURE_SRCS = [
    "src/session_replay/sentry_session_replay_none.c",
]

BACKEND_SRCS = {
    "breakpad": ["src/backends/sentry_backend_breakpad.cpp"],
    "crashpad": ["src/backends/sentry_backend_crashpad.cpp"],
    "inproc": ["src/backends/sentry_backend_inproc.c"],
    "native": [
        "src/backends/native/sentry_crash_handler.c",
        "src/backends/native/sentry_crash_ipc.c",
        "src/backends/sentry_backend_native.c",
    ],
    "none": ["src/backends/sentry_backend_none.c"],
}

NATIVE_BACKEND_PRIVATE_HDRS = [
    "src/backends/native/sentry_crash_context.h",
    "src/backends/native/sentry_crash_handler.h",
    "src/backends/native/sentry_crash_ipc.h",
]

NATIVE_DAEMON_COMMON_SRCS = [
    "src/backends/native/minidump/sentry_minidump_common.c",
    "src/backends/native/minidump/sentry_minidump_indirect.c",
    "src/backends/native/sentry_crash_daemon.c",
]

NATIVE_DAEMON_PRIVATE_HDRS = [
    "src/backends/native/minidump/sentry_minidump_common.h",
    "src/backends/native/minidump/sentry_minidump_format.h",
    "src/backends/native/minidump/sentry_minidump_indirect.h",
    "src/backends/native/minidump/sentry_minidump_writer.h",
    "src/backends/native/sentry_crash_daemon.h",
]

NATIVE_DAEMON_LINUX_SRCS = [
    "src/backends/native/minidump/sentry_minidump_linux.c",
    "src/unwinder/sentry_unwinder_libunwind_remote.c",
]

NATIVE_DAEMON_MACOS_SRCS = [
    "src/backends/native/minidump/sentry_minidump_macos.c",
]

TRANSPORT_SRCS = {
    "curl": ["src/transports/sentry_http_transport_curl.c"],
    "none": ["src/transports/sentry_transport_none.c"],
}

SCREENSHOT_SRCS = {
    "none": ["src/screenshot/sentry_screenshot_none.c"],
}

INTEGRATION_SRCS = {
    "qt": [
        "src/integrations/sentry_integration_qt.cpp",
        "src/integrations/sentry_integration_qt.h",
    ],
}
