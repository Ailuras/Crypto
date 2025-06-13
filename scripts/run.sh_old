#!/bin/bash

# This script processes a batch of files serially
# Usage: batch.sh --solver-path <solver_path> --timeout <timeout> --output-file <output_file> --task <task_name> --files <file1> <file2> ...

# Default values
SOLVER_PATH=""
TIMEOUT=""
OUTPUT_FILE=""
TASK_NAME=""
FILES=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --solver-path)
            SOLVER_PATH="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --task)
            TASK_NAME="$2"
            shift 2
            ;;
        --files)
            shift  # Remove --files
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                FILES+=("$1")
                shift
            done
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 --solver-path <solver_path> --timeout <timeout> --output-file <output_file> --task <task_name> --files <file1> <file2> ..."
            exit 1
            ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$SOLVER_PATH" ] || [ -z "$TIMEOUT" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$TASK_NAME" ] || [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --solver-path <solver_path> --timeout <timeout> --output-file <output_file> --task <task_name> --files <file1> <file2> ..."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Function to print separators
print_double_separator() {
    echo "===========================================================" >> "$OUTPUT_FILE"
}

print_single_separator() {
    echo "-----------------------------------------------------------" >> "$OUTPUT_FILE"
}

for file in "${FILES[@]}"; do
    print_double_separator
    echo "FILE: $(basename "$file")" >> "$OUTPUT_FILE"
    echo "PATH: $file" >> "$OUTPUT_FILE"
    echo "TASK: $TASK_NAME" >> "$OUTPUT_FILE"
    echo "SOLVER: $(basename "$(dirname "$SOLVER_PATH")")" >> "$OUTPUT_FILE"
    echo "TIMEOUT: $TIMEOUT" >> "$OUTPUT_FILE"
    print_single_separator
    
    # Record start time in seconds since epoch
    START_TIME=$(date +%s.%N)
    
    # Create a temporary file for solver output
    TEMP_OUTPUT=$(mktemp)
    
    # Run the solver and capture the output to temporary file
    timeout "$TIMEOUT"s "$SOLVER_PATH" "$TIMEOUT" "$file" > "$TEMP_OUTPUT" 2>&1
    
    # Capture exit status
    STATUS=$?
    
    # Record end time in seconds since epoch
    END_TIME=$(date +%s.%N)
    
    # Calculate solving time
    SOLVING_TIME=$(echo "$END_TIME - $START_TIME" | bc)
    
    # Write solver output to the main output file
    cat "$TEMP_OUTPUT" >> "$OUTPUT_FILE"
    rm -f "$TEMP_OUTPUT"
    
    print_single_separator
    echo "SOLVING_TIME: $SOLVING_TIME" >> "$OUTPUT_FILE"
    
    if [ $STATUS -eq 124 ] || [ $STATUS -eq 137 ]; then
        echo "RESULT: TIMEOUT" >> "$OUTPUT_FILE"
    elif [ $STATUS -eq 0 ]; then
        echo "RESULT: SUCCESS" >> "$OUTPUT_FILE"
    else
        echo "RESULT: ERROR" >> "$OUTPUT_FILE"
    fi
done

echo "Batch processing complete. Results saved in: $OUTPUT_FILE" 