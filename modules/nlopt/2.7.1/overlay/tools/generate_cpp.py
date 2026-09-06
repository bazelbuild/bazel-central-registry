#!/usr/bin/env python3
"""Generate nlopt.hpp from nlopt-in.hpp template by inserting enums from nlopt.h"""

import re
import sys


def extract_enums_from_nlopt_h(nlopt_h_path):
    """Extract enum definitions from nlopt.h"""
    with open(nlopt_h_path, "r") as f:
        lines = f.readlines()

    enum_lines = []
    for line in lines:
        # Match lines with NLOPT_ enum constants
        if re.search(r"^\s+NLOPT_[A-Z0-9_]+", line):
            enum_lines.append(line)

    return enum_lines


def generate_cpp_enums(enum_lines):
    """Convert C enums to C++ enum format"""
    cpp_output = []
    cpp_output.append("  enum algorithm {\n")

    in_algorithm = True
    for line in enum_lines:
        # Convert NLOPT_ prefix to no prefix for C++
        cpp_line = re.sub(r"NLOPT_", "", line)
        cpp_output.append(cpp_line)

        # Switch from algorithm enum to result enum
        if "NUM_ALGORITHMS" in line:
            cpp_output.append("  };\n  enum result {\n")
            in_algorithm = False
        elif "NUM_RESULTS" in line:
            cpp_output.append("  };\n")
            break

    return "".join(cpp_output)


def generate_cpp_header(template_path, nlopt_h_path, output_path):
    """Generate nlopt.hpp from template and nlopt.h"""
    # Extract enums from nlopt.h
    enum_lines = extract_enums_from_nlopt_h(nlopt_h_path)
    cpp_enums = generate_cpp_enums(enum_lines)

    # Read template
    with open(template_path, "r") as f:
        template_content = f.read()

    # Replace GEN_ENUMS_HERE marker with actual enums
    output_content = template_content.replace("  // GEN_ENUMS_HERE", cpp_enums.rstrip("\n"))

    # Write output
    with open(output_path, "w") as f:
        f.write(output_content)


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <nlopt-in.hpp> <nlopt.h> <nlopt.hpp>")
        sys.exit(1)

    template_path = sys.argv[1]
    nlopt_h_path = sys.argv[2]
    output_path = sys.argv[3]

    generate_cpp_header(template_path, nlopt_h_path, output_path)


if __name__ == "__main__":
    main()
