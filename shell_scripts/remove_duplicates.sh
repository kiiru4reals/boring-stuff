#!/bin/bash

# Usage: ./remove_duplicates.sh input.csv output.csv

input_csv="$1"
output_csv="$2"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 input.csv output.csv"
    exit 1
fi

if [ ! -f "$input_csv" ]; then
    echo "Input file not found: $input_csv"
    exit 1
fi

awk -F, '!seen[$3]++' "$input_csv" > "$output_csv"

echo "Duplicates removed and saved to $output_csv"
