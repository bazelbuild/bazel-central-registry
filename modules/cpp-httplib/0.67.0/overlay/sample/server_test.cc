#include "httplib.h"
#include <cassert>
#include <thread>

int main() {
    httplib::Server svr;
    svr.Get("/hello", [](const httplib::Request&, httplib::Response& res) {
        res.set_content("world", "text/plain");
    });

    std::thread t([&svr]() { svr.listen("127.0.0.1", 18080); });

    std::this_thread::sleep_for(std::chrono::milliseconds(50));

    httplib::Client cli("127.0.0.1", 18080);
    auto result = cli.Get("/hello");
    assert(result && result->status == 200);
    assert(result->body == "world");

    svr.stop();
    t.join();
    return 0;
}
