"""Converts a binary blob file into a C header declaring a static unsigned char array.

Equivalent to the CMake ocv_blob2hdr() function.

Usage: blob2hdr.py <input_blob> <output_header> <cpp_variable_name>

The generated header has the form:

    // Auto generated file.
    static const unsigned char <cpp_variable_name>[] =
    {
    0xNN, 0xNN, ..., 0xNN,
    ...
    0xNN, 0xNN, ..., 0xNN
    };

Full 16-byte lines carry a trailing ", " before the newline to match the
CMake ocv_blob2hdr() output format; the final (possibly partial) line does not.
"""

import sys

blob_path, out_path, cpp_variable = sys.argv[1], sys.argv[2], sys.argv[3]

with open(blob_path, "rb") as f:
    data = f.read()

hex_bytes = ["0x{:02x}".format(b) for b in data]
chunks = [hex_bytes[i:i + 16] for i in range(0, len(hex_bytes), 16)]
lines = []
for i, chunk in enumerate(chunks):
    if i < len(chunks) - 1:
        # Full 16-byte lines keep a trailing ", " before the newline.
        lines.append(", ".join(chunk) + ", ")
    else:
        lines.append(", ".join(chunk))
content = "\n".join(lines)

with open(out_path, "w") as f:
    f.write("// Auto generated file.\n")
    f.write("static const unsigned char " + cpp_variable + "[] =\n{\n")
    f.write(content)
    f.write("\n};\n")
