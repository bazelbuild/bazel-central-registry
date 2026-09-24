#ifndef COAL_DEPRECATED_HH
#define COAL_DEPRECATED_HH

#if __cplusplus >= 201402L
#define COAL_DEPRECATED [[deprecated]]
#define COAL_DEPRECATED_MESSAGE(message) [[deprecated(#message)]]
#elif defined(__GNUC__) || defined(__clang__)
#define COAL_DEPRECATED __attribute__((deprecated))
#define COAL_DEPRECATED_MESSAGE(message) __attribute__((deprecated(#message)))
#elif defined(_MSC_VER)
#define COAL_DEPRECATED __declspec(deprecated)
#define COAL_DEPRECATED_MESSAGE(message) __declspec(deprecated(#message))
#else
#define COAL_DEPRECATED
#define COAL_DEPRECATED_MESSAGE(message)
#endif

#endif  // COAL_DEPRECATED_HH
