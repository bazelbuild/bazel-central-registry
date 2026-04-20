#!/usr/bin/env bash
#
# This script copies an input file to an output file, line by line.
#
# After writing each line, it checks if the line contains any of a list of match strings.
# For each match string found in the line, it inserts the content of the corresponding insert file.
#
# Arguments:
#   1. Input file path
#   2. Output file path
#   3+. Alternating list of insert file paths and match strings:
#        (Insert file 1) (Match string 1) (Insert file 2) (Match string 2) ...
#
# Example usage:
#   ./insert_script.sh input.txt output.txt insert1.txt "MATCH1" insert2.txt "MATCH2"
#
# Notes:
# - Each insert file is paired with a match string by their order in the arguments.
# - Multiple insertions can occur after the same line if multiple match strings match.
# - Inserted content is loaded into memory at startup for faster processing.

INPUT_FILE="$1"
OUTPUT_FILE="$2"
shift 2  # Shift away input and output filenames

# Remaining arguments are alternating INSERT_FILE and MATCH_STRING
INSERT_FILES=()
MATCH_STRINGS=()

while [[ $# -gt 0 ]]; do
    INSERT_FILES+=("$1")
    MATCH_STRINGS+=("$2")
    shift 2
done

# Preload all insert files
INSERT_CONTENTS=()
for insert_file in "${INSERT_FILES[@]}"; do
    INSERT_CONTENTS+=("$(<"$insert_file")")
done

while IFS= read -r line || [ -n "$line" ]; do
    echo "$line" >> "$OUTPUT_FILE"
    for i in "${!MATCH_STRINGS[@]}"; do
        if [[ "$line" == *"${MATCH_STRINGS[$i]}"* ]]; then
            printf '%s\n' "${INSERT_CONTENTS[$i]}" >> "$OUTPUT_FILE"
        fi
    done
done < "$INPUT_FILE"
