/**
 * @file cmakedefine_converter.cc
 * @brief A hand authored file to add support for `rules_cc_autoconf`.
 */

#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char* argv[])
{
    if (argc != 3)
    {
        std::cerr << "Usage: " << argv[0] << " <input> <output>\n";
        return 1;
    }

    std::ifstream in(argv[1]);
    if (!in)
    {
        std::cerr << "Cannot open input: " << argv[1] << "\n";
        return 1;
    }

    std::ofstream out(argv[2]);
    if (!out)
    {
        std::cerr << "Cannot open output: " << argv[2] << "\n";
        return 1;
    }

    const std::string prefix = "#cmakedefine";
    std::string line;
    while (std::getline(in, line))
    {
        size_t pos = line.find_first_not_of(" \t");
        if (pos != std::string::npos &&
            line.length() > pos + prefix.length() &&
            line.compare(pos, prefix.length(), prefix) == 0 &&
            (line[pos + prefix.length()] == ' ' ||
             line[pos + prefix.length()] == '\t'))
        {
            size_t name_start = line.find_first_not_of(
                " \t", pos + prefix.length());
            if (name_start != std::string::npos)
            {
                size_t name_end = line.find_first_of(" \t", name_start);
                std::string name = (name_end != std::string::npos)
                                       ? line.substr(name_start, name_end - name_start)
                                       : line.substr(name_start);
                out << "#undef " << name << "\n";
            }
            else
            {
                out << line << "\n";
            }
        }
        else
        {
            out << line << "\n";
        }
    }

    return 0;
}
