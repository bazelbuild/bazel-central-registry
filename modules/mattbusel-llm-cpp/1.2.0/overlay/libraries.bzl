"""The llm-cpp libraries, grouped by what they need."""

# Libraries with no external dependency. llm_compress.hpp only needs libcurl
# when LLM_COMPRESS_SUMMARIZE is defined; add @curl yourself in that case.
PLAIN_LIBRARIES = [
    "cache",
    "compress",
    "cost",
    "format",
    "guard",
    "json",
    "log",
    "mock",
    "parse",
    "pool",
    "retry",
    "router",
    "template",
    "trace",
]

# Libraries that call model APIs over HTTP through libcurl. llm_eval.hpp and
# llm_stream.hpp include <curl/curl.h> in their declarations; the others only
# in their implementation.
CURL_LIBRARIES = [
    "ab",
    "agent",
    "audio",
    "batch",
    "chat",
    "embed",
    "eval",
    "finetune",
    "rag",
    "rank",
    "stream",
    "vision",
]

# Libraries that use std::thread or std::mutex.
THREAD_LIBRARIES = [
    "batch",
    "cache",
    "finetune",
    "mock",
    "pool",
    "retry",
    "stream",
]
