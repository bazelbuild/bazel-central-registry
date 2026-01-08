import os
import subprocess
import sys

from python.runfiles import Runfiles

# Ensure exactly zero arguments are provided
if len(sys.argv) != 1:
    print(f"Usage: {sys.argv[0]}", file=sys.stderr)
    sys.exit(1)

# Get the openssl binary path
extension = ".exe" if os.name == "nt" else ""
r = Runfiles.Create()
openssl = r.Rlocation("openssl/openssl" + extension)

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
