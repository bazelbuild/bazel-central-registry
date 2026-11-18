// Consumer contract for @zenlib: the propagated UNICODE define, size_t
// overload resolution, linking libzen and its thread library, and a Ztring
// round trip at run time.

#include <cstddef>
#include <cstdio>

#include "ZenLib/CriticalSection.h"
#include "ZenLib/Ztring.h"

// UNICODE is public ABI: Ztring and Char are wide in libzen, so they must be
// wide in every consumer too.
static_assert(sizeof(ZenLib::Char) == sizeof(wchar_t), "UNICODE did not propagate");

int main() {
    ZenLib::CriticalSection lock;
    lock.Enter();
    ZenLib::Ztring number;
    // A size_t argument resolves to exactly one From_Number overload.
    number.From_Number(static_cast<std::size_t>(42));
    const bool ok = number == __T("42") && number.To_int32u() == 42;
    lock.Leave();
    if (!ok) {
        std::fprintf(stderr, "Ztring round-trip failed\n");
        return 1;
    }
    return 0;
}
