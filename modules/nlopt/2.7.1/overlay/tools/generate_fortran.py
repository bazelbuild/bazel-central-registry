#!/usr/bin/env python3
"""Generate nlopt.f from nlopt.h by extracting enum constants"""

import re
import sys


def extract_fortran_constants(nlopt_h_path):
    """Extract enum constants from nlopt.h and generate Fortran declarations"""
    with open(nlopt_h_path, "r") as f:
        lines = f.readlines()

    fortran_output = []
    i = 0

    for line in lines:
        # Match lines with NLOPT_ enum constants (but not NUM_ constants)
        match = re.search(r"^\s+NLOPT_([A-Z0-9_]+)", line)
        if match and not match.group(1).startswith("NUM_"):
            enum_name = match.group(1)

            # Check if there's an explicit value assignment
            value_match = re.search(r"NLOPT_[A-Z0-9_]+ = (-?[0-9]+)", line)
            if value_match:
                i = int(value_match.group(1))

            # Generate Fortran parameter declaration
            fortran_line = f"      integer NLOPT_{enum_name}\n"
            fortran_line += f"      parameter (NLOPT_{enum_name}={i})\n"
            fortran_output.append(fortran_line)

            # Increment for next enum (handle negative numbers)
            if i < 0:
                i = i + 1
            else:
                i = i + 1

    return "".join(fortran_output)


def generate_fortran_header(nlopt_h_path, output_path):
    """Generate nlopt.f from nlopt.h"""
    fortran_content = extract_fortran_constants(nlopt_h_path)

    with open(output_path, "w") as f:
        f.write(fortran_content)


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <nlopt.h> <nlopt.f>")
        sys.exit(1)

    nlopt_h_path = sys.argv[1]
    output_path = sys.argv[2]

    generate_fortran_header(nlopt_h_path, output_path)


if __name__ == "__main__":
    main()
