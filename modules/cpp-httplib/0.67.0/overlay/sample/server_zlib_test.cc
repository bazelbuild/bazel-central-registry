#include "httplib.h"
#include <cassert>
#include <thread>

#ifndef CPPHTTPLIB_ZLIB_SUPPORT
#error "CPPHTTPLIB_ZLIB_SUPPORT must be defined to build this test"
#endif

int main() {
    httplib::Server svr;
    svr.Get("/hello", [](const httplib::Request&, httplib::Response& res) {
        res.set_content("world", "text/plain");
    });

    std::thread t([&svr]() { svr.listen("127.0.0.1", 18081); });

    std::this_thread::sleep_for(std::chrono::milliseconds(50));

    httplib::Client cli("127.0.0.1", 18081);
    cli.set_compress(true);
    auto result = cli.Get("/hello");
    assert(result && result->status == 200);
    assert(result->body == "world");

    svr.stop();
    t.join();
    return 0;
}
