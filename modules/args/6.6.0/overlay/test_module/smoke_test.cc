#include <args.hxx>

#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

int main() {
    args::ArgumentParser parser("args smoke test");
    args::ValueFlag<int> number(parser, "N", "a number", {'n', "number"});
    args::Flag verbose(parser, "verbose", "a boolean", {'v', "verbose"});
    args::Positional<std::string> path(parser, "PATH", "a positional");

    // ParseArgs takes the argument list without argv[0].
    const std::vector<std::string> arguments = {"--number", "42", "-v", "in.txt"};

    try {
        parser.ParseArgs(arguments);
    } catch (const args::ParseError& e) {
        std::cerr << "parse failed: " << e.what() << "\n";
        return EXIT_FAILURE;
    }

    if (!number || args::get(number) != 42) {
        std::cerr << "expected --number to yield 42\n";
        return EXIT_FAILURE;
    }

    if (!verbose) {
        std::cerr << "expected -v to be set\n";
        return EXIT_FAILURE;
    }

    if (!path || args::get(path) != "in.txt") {
        std::cerr << "expected the positional to yield in.txt\n";
        return EXIT_FAILURE;
    }

    std::cout << "args parse ok\n";
    return EXIT_SUCCESS;
}
