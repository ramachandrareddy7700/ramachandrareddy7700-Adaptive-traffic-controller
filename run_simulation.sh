#!/bin/bash

# ==============================================================================
# Simulation Script for Adaptive Traffic Controller
# ==============================================================================
# This script compiles and runs the Verilog simulation using Icarus Verilog
# and opens the waveform viewer (GTKWave) for analysis.
#
# Prerequisites:
#   - Icarus Verilog (iverilog)
#   - GTKWave (optional, for waveform viewing)
#
# Usage:
#   ./run_simulation.sh [options]
#
# Options:
#   -c, --compile-only    Compile only, don't run simulation
#   -r, --run-only        Run simulation only (skip compilation)
#   -w, --wave            Open waveform viewer after simulation
#   -h, --help            Show this help message
# ==============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
COMPILE=true
RUN=true
WAVEFORM=false

# File names
DESIGN_FILE="adaptive_traffic_controller.v"
TESTBENCH_FILE="tb_adaptive_traffic_controller.v"
OUTPUT_EXEC="traffic_sim"
VCD_FILE="adaptive_traffic_controller.vcd"

# ==============================================================================
# Parse command line arguments
# ==============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--compile-only)
            RUN=false
            shift
            ;;
        -r|--run-only)
            COMPILE=false
            shift
            ;;
        -w|--wave)
            WAVEFORM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -c, --compile-only    Compile only, don't run simulation"
            echo "  -r, --run-only        Run simulation only (skip compilation)"
            echo "  -w, --wave            Open waveform viewer after simulation"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            exit 1
            ;;
    esac
done

# ==============================================================================
# Header
# ==============================================================================
echo -e "${BLUE}=============================================================${NC}"
echo -e "${BLUE}  Adaptive Traffic Controller - Simulation Script${NC}"
echo -e "${BLUE}=============================================================${NC}"
echo ""

# ==============================================================================
# Check for required tools
# ==============================================================================
if $COMPILE; then
    if ! command -v iverilog &> /dev/null; then
        echo -e "${RED}Error: Icarus Verilog (iverilog) not found!${NC}"
        echo "Please install it using:"
        echo "  Ubuntu/Debian: sudo apt-get install iverilog"
        echo "  macOS:         brew install icarus-verilog"
        exit 1
    fi
fi

if $RUN; then
    if ! command -v vvp &> /dev/null; then
        echo -e "${RED}Error: VVP (Verilog simulator) not found!${NC}"
        echo "VVP is part of Icarus Verilog package."
        exit 1
    fi
fi

if $WAVEFORM; then
    if ! command -v gtkwave &> /dev/null; then
        echo -e "${YELLOW}Warning: GTKWave not found!${NC}"
        echo "Waveform viewing will be skipped."
        echo "Install GTKWave:"
        echo "  Ubuntu/Debian: sudo apt-get install gtkwave"
        echo "  macOS:         brew install gtkwave"
        WAVEFORM=false
    fi
fi

# ==============================================================================
# Check for required files
# ==============================================================================
if $COMPILE; then
    if [ ! -f "$DESIGN_FILE" ]; then
        echo -e "${RED}Error: Design file '$DESIGN_FILE' not found!${NC}"
        exit 1
    fi

    if [ ! -f "$TESTBENCH_FILE" ]; then
        echo -e "${RED}Error: Testbench file '$TESTBENCH_FILE' not found!${NC}"
        exit 1
    fi
fi

# ==============================================================================
# Compilation
# ==============================================================================
if $COMPILE; then
    echo -e "${YELLOW}[1/3] Compiling Verilog files...${NC}"
    echo "  - Design:    $DESIGN_FILE"
    echo "  - Testbench: $TESTBENCH_FILE"
    echo ""

    # Run iverilog
    iverilog -o $OUTPUT_EXEC $DESIGN_FILE $TESTBENCH_FILE

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Compilation successful!${NC}"
        echo ""
    else
        echo -e "${RED}✗ Compilation failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[1/3] Skipping compilation (using existing executable)${NC}"
    echo ""
fi

# ==============================================================================
# Simulation
# ==============================================================================
if $RUN; then
    if [ ! -f "$OUTPUT_EXEC" ]; then
        echo -e "${RED}Error: Executable '$OUTPUT_EXEC' not found!${NC}"
        echo "Run with compilation first."
        exit 1
    fi

    echo -e "${YELLOW}[2/3] Running simulation...${NC}"
    echo ""
    echo -e "${BLUE}─────────────────────────────────────────────────────────${NC}"
    
    # Run simulation
    vvp $OUTPUT_EXEC
    
    if [ $? -eq 0 ]; then
        echo -e "${BLUE}─────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "${GREEN}✓ Simulation completed successfully!${NC}"
        echo ""
    else
        echo -e "${RED}✗ Simulation failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[2/3] Skipping simulation${NC}"
    echo ""
fi

# ==============================================================================
# Waveform Viewing
# ==============================================================================
if $WAVEFORM; then
    if [ ! -f "$VCD_FILE" ]; then
        echo -e "${RED}Error: VCD file '$VCD_FILE' not found!${NC}"
        echo "Make sure simulation completed successfully."
        exit 1
    fi

    echo -e "${YELLOW}[3/3] Opening waveform viewer...${NC}"
    echo "  VCD file: $VCD_FILE"
    echo ""
    
    # Open GTKWave in background
    gtkwave $VCD_FILE &
    
    echo -e "${GREEN}✓ GTKWave launched${NC}"
    echo ""
else
    echo -e "${YELLOW}[3/3] Skipping waveform viewer${NC}"
    echo "  Tip: Use '-w' flag to automatically open waveforms"
    echo ""
fi

# ==============================================================================
# Summary
# ==============================================================================
echo -e "${BLUE}=============================================================${NC}"
echo -e "${GREEN}All operations completed successfully!${NC}"
echo -e "${BLUE}=============================================================${NC}"
echo ""
echo "Generated Files:"
if [ -f "$OUTPUT_EXEC" ]; then
    echo "  ✓ Executable:  $OUTPUT_EXEC"
fi
if [ -f "$VCD_FILE" ]; then
    echo "  ✓ Waveform:    $VCD_FILE"
fi
echo ""

if [ -f "$VCD_FILE" ] && ! $WAVEFORM; then
    echo "To view waveforms manually:"
    echo "  gtkwave $VCD_FILE"
    echo ""
fi

echo "Next Steps:"
echo "  1. Review simulation output above"
echo "  2. Open waveforms in GTKWave (if not already opened)"
echo "  3. Verify all test cases passed"
echo "  4. Analyze timing and signal behavior"
echo ""
echo -e "${GREEN}Happy Simulating! 🚦${NC}"
