// Exercises every SFML module without needing a display or audio device.
// Pass a URL such as https://github.com to also test an HTTPS request.
#include <SFML/Audio.hpp>
#include <SFML/Graphics.hpp>
#include <SFML/Network.hpp>
#include <SFML/System.hpp>
#include <SFML/Window.hpp>

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <vector>

int main(int argc, char** argv) {
    int failures = 0;
    auto check = [&](bool ok, const char* what) {
        std::printf("%s: %s\n", ok ? "PASS" : "FAIL", what);
        if (!ok) ++failures;
    };

    // System
    const char utf8[] = "h\xc3\xa9llo";
    check(sf::String::fromUtf8(utf8, utf8 + 6).getSize() == 5, "system: sf::String UTF-8");
    check((sf::Vector2f(3, 4)).length() == 5.f, "system: sf::Vector2");

    // Window (no display needed)
    sf::Joystick::update();  // enumerates devices through libudev, no display needed
    check(!sf::Joystick::isConnected(sf::Joystick::Count - 1), "window: joystick enumeration (udev)");

    sf::Image image({4, 4}, sf::Color::Red);
    check(image.saveToFile("smoke.png"), "graphics: save PNG (stb_image_write)");
    sf::Image loaded;
    check(loaded.loadFromFile("smoke.png") && loaded.getPixel({1, 1}) == sf::Color::Red,
          "graphics: load PNG (stb_image)");

    // Audio: round-trip a tone through each codec (FLAC, Ogg Vorbis, WAV).
    std::vector<std::int16_t> samples(44100);
    for (std::size_t i = 0; i < samples.size(); ++i)
        samples[i] = static_cast<std::int16_t>(8000 * std::sin(i * 0.05));
    sf::SoundBuffer buffer(samples.data(), samples.size(), 1, 44100, {sf::SoundChannel::Mono});
    for (const char* file : {"smoke.flac", "smoke.ogg", "smoke.wav"}) {
        sf::SoundBuffer reloaded;
        const bool ok = buffer.saveToFile(file) && reloaded.loadFromFile(file) &&
                        reloaded.getSampleRate() == 44100 && reloaded.getSampleCount() > 40000;
        std::printf("%s: audio: %s round trip\n", ok ? "PASS" : "FAIL", file);
        if (!ok) ++failures;
    }

    // Network: IP parsing always; HTTPS (Mbed TLS) only when a host is given.
    check(sf::IpAddress::resolve("127.0.0.1").has_value(), "network: IpAddress");
    if (argc > 1) {
        sf::Http http(argv[1]);
        const sf::Http::Response response = http.sendRequest(sf::Http::Request("/"), sf::seconds(20));
        const int status = static_cast<int>(response.getStatus());
        std::printf("  HTTPS %s -> status %d\n", argv[1], status);
        check(status > 0 && status < 1000, "network: HTTPS request over Mbed TLS");
    }
    return failures == 0 ? 0 : 1;
}
