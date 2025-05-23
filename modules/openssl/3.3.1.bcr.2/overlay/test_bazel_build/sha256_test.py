import sys
import subprocess

# Check if exactly one argument is provided
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} /path/to/openssl", file=sys.stderr)
    sys.exit(1)

# Get the openssl binary path from the argument
openssl = sys.argv[1]

# Run the openssl command to compute the SHA-256 hash
command = [openssl, "dgst", "-sha256"]
result = subprocess.run(command, input="European Burmese", text=True, capture_output=True)

# Extract the hash from the output
out = result.stdout.split()[-1]

# Compare the computed hash with the expected one
expected_hash = "693d8db7b05e99c6b7a7c0616456039d89c555029026936248085193559a0b5d"
if out != expected_hash:
    print(f"Wrong hash - got {out}", file=sys.stderr)
    sys.exit(1)
