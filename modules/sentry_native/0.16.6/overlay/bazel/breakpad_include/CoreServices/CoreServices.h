#ifndef SENTRY_NATIVE_BREAKPAD_CORESERVICES_H_
#define SENTRY_NATIVE_BREAKPAD_CORESERVICES_H_

// Breakpad's MachIPC wrapper includes the legacy CoreServices umbrella solely
// for these two endian helpers. The hermetic macOS SDK used by @llvm omits that
// umbrella while retaining the equivalent CoreFoundation API that upstream
// already links. Keep the compatibility local to the overlay.
#include <CoreFoundation/CFByteOrder.h>

#define EndianU32_LtoN(value) CFSwapInt32LittleToHost(value)
#define EndianU32_NtoL(value) CFSwapInt32HostToLittle(value)

#endif  // SENTRY_NATIVE_BREAKPAD_CORESERVICES_H_
