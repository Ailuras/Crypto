#!/bin/bash

# Serial solver execution script for a single model
# Usage: run.sh --model-file <file> --solvers <solver1 solver2 ...> --timeout <timeout> --output-file <output_file>

# Default values
MODEL_FILE=""
SOLVERS=()
TIMEOUT=300
OUTPUT_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model-file)
            MODEL_FILE="$2"
            shift 2
            ;;
        --solvers)
            shift  # Remove --solvers
            while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                SOLVERS+=("$1")
                shift
            done
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 --model-file <file> --solvers <solver1 solver2 ...> --timeout <timeout> --output-file <output_file>"
            exit 1
            ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$MODEL_FILE" ] || [ ${#SOLVERS[@]} -eq 0 ] || [ -z "$TIMEOUT" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 --model-file <file> --solvers <solver1 solver2 ...> --timeout <timeout> --output-file <output_file>"
    exit 1
fi

# Check if model file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: Model file not found: $MODEL_FILE"
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

# Initialize log file
MODEL_NAME=$(basename "$MODEL_FILE" .mzn)
cat > "$OUTPUT_FILE" << EOF
MODEL: $MODEL_NAME
FILE: $MODEL_FILE
TEST_START: $(date)
TIMEOUT: ${TIMEOUT}s
SOLVERS: ${SOLVERS[*]}
===========================================================

EOF

# Test each solver
for solver in "${SOLVERS[@]}"; do
    print_double_separator
    echo "SOLVER: $solver" >> "$OUTPUT_FILE"
    echo "MODEL: $(basename "$MODEL_FILE")" >> "$OUTPUT_FILE"
    echo "PATH: $MODEL_FILE" >> "$OUTPUT_FILE"
    echo "TIMEOUT: $TIMEOUT" >> "$OUTPUT_FILE"
    echo "START_TIME: $(date)" >> "$OUTPUT_FILE"
    print_single_separator
    
    # Record start time in seconds since epoch
    START_TIME=$(date +%s.%N)
    
    # Create a temporary file for solver output
    TEMP_OUTPUT=$(mktemp)
    
    # Check if data file exists (for models that need .dzn files)
    DATA_FILE="${MODEL_FILE%.*}.dzn"
    if [ -f "$DATA_FILE" ]; then
        # Run with data file
        timeout "${TIMEOUT}s" minizinc --solver "$solver" "$MODEL_FILE" "$DATA_FILE" > "$TEMP_OUTPUT" 2>&1
    else
        # Run without data file
        timeout "${TIMEOUT}s" minizinc --solver "$solver" "$MODEL_FILE" > "$TEMP_OUTPUT" 2>&1
    fi
    
    # Capture exit status
    STATUS=$?
    
    # Record end time in seconds since epoch
    END_TIME=$(date +%s.%N)
    
    # Calculate solving time
    SOLVING_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
    
    # Write solver output to the main output file
    cat "$TEMP_OUTPUT" >> "$OUTPUT_FILE"
    rm -f "$TEMP_OUTPUT"
    
    print_single_separator
    echo "END_TIME: $(date)" >> "$OUTPUT_FILE"
    echo "SOLVING_TIME: $SOLVING_TIME" >> "$OUTPUT_FILE"
    
    if [ $STATUS -eq 124 ] || [ $STATUS -eq 137 ]; then
        echo "RESULT: TIMEOUT" >> "$OUTPUT_FILE"
    elif [ $STATUS -eq 0 ]; then
        echo "RESULT: SUCCESS" >> "$OUTPUT_FILE"
    else
        echo "RESULT: ERROR" >> "$OUTPUT_FILE"
        echo "EXIT_CODE: $STATUS" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
done

# Write test completion info
cat >> "$OUTPUT_FILE" << EOF
===========================================================
TEST_COMPLETE: $(date)
TOTAL_SOLVERS: ${#SOLVERS[@]}
===========================================================
EOF

echo "Completed testing $MODEL_NAME with ${#SOLVERS[@]} solvers"
