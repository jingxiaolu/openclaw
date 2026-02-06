#!/usr/bin/env bash
#
# ANUMA Optimization Skill Wrapper for OpenClaw/Witty
# Provides CLI interface to ANUMA NUMA optimization toolkit
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ANUMA_HOME="${ANUMA_HOME:-$SKILL_DIR/anuma}"
DEFAULT_OUTPUT_DIR="./anuma-output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" && exit 1; }

# Check prerequisites
check_prerequisites() {
    local missing=()
    
    for cmd in taskset npu-smi lscpu ps; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
    fi
    
    if [ ! -d "$ANUMA_HOME" ]; then
        log_error "ANUMA not found at $ANUMA_HOME. Please clone ANUMA repository first."
    fi
    
    if [ ! -f "$ANUMA_HOME/scripts/collect_system_info.py" ]; then
        log_error "ANUMA scripts not found. Please check ANUMA_HOME path."
    fi
}

# Show usage
usage() {
    cat <<EOF
ANUMA Optimization Skill for OpenClaw/Witty

Usage: $(basename "$0") <command> [options]

Commands:
  collect              Collect system information for target processes
  analyze              Analyze collected data for bottlenecks
  generate-strategy    Generate core binding strategy
  apply                Apply binding strategy to processes
  verify               Verify current CPU/NUMA bindings
  optimize             Run full optimization workflow

Global Options:
  -h, --help           Show this help message
  --output-dir DIR     Output directory (default: $DEFAULT_OUTPUT_DIR)

Collect Options:
  --pids PID1,PID2     Process IDs to analyze
  --tids TID1,TID2     Thread IDs to analyze
  --format FORMAT      Output format: json|markdown (default: markdown)
  --no-load            Skip running load command

Analyze Options:
  --input FILE         Input system info file
  --format FORMAT      Output format: json|markdown (default: markdown)

Generate Options:
  --input FILE         Input analysis or system info file
  --output FILE        Output script path (default: ./bindcore.sh)

Apply Options:
  --script FILE        Binding script to apply
  --dry-run            Show commands without executing

Verify Options:
  --pids PID1,PID2     Process IDs to verify
  --tids TID1,TID2     Thread IDs to verify

Optimize Options:
  --pids PID1,PID2     Target process IDs
  --analyze            Perform bottleneck analysis (default: true)
  --bind               Apply binding strategy (default: false)
  --force              Apply without confirmation

Examples:
  # Full optimization workflow
  $(basename "$0") optimize --pids 12345,12346 --analyze --bind

  # Collect system info
  $(basename "$0") collect --pids 12345 --format markdown --output ./sysinfo.md

  # Generate and apply strategy
  $(basename "$0") generate-strategy --input ./sysinfo.md --output ./bind.sh
  $(basename "$0") apply --script ./bind.sh

EOF
}

# Parse arguments
COMMAND=""
PIDS=""
TIDS=""
FORMAT="markdown"
INPUT=""
OUTPUT=""
SCRIPT=""
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
NO_LOAD=false
DRY_RUN=false
ANALYZE=true
BIND=false
FORCE=false

parse_args() {
    COMMAND="${1:-}"
    shift || true
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pids)
                PIDS="$2"
                shift 2
                ;;
            --tids)
                TIDS="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --input)
                INPUT="$2"
                shift 2
                ;;
            --output)
                OUTPUT="$2"
                shift 2
                ;;
            --script)
                SCRIPT="$2"
                shift 2
                ;;
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --no-load)
                NO_LOAD=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --analyze)
                ANALYZE=true
                shift
                ;;
            --bind)
                BIND=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done
}

# Collect system information
cmd_collect() {
    check_prerequisites
    
    if [ -z "$PIDS" ] && [ -z "$TIDS" ]; then
        log_error "Either --pids or --tids must be specified"
    fi
    
    # Prepare TID list
    local tid_list=()
    if [ -n "$TIDS" ]; then
        IFS=',' read -ra tid_list <<< "$TIDS"
    elif [ -n "$PIDS" ]; then
        # Get all threads from PIDs
        IFS=',' read -ra pids <<< "$PIDS"
        for pid in "${pids[@]}"; do
            local threads=$(ps -T -p "$pid" -o tid= 2>/dev/null | tr '\n' ' ')
            for tid in $threads; do
                tid_list+=("$tid")
            done
        done
    fi
    
    if [ ${#tid_list[@]} -eq 0 ]; then
        log_error "No threads found to analyze"
    fi
    
    log_info "Collecting system information for TIDs: ${tid_list[*]}"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Run load command if enabled
    if [ "$NO_LOAD" = false ]; then
        local load_cmd_file="$ANUMA_HOME/config/load_command.yaml"
        if [ -f "$load_cmd_file" ]; then
            log_info "Starting load command (20s preheat)..."
            local load_cmd=$(grep "load_command:" "$load_cmd_file" | sed 's/load_command: *//' | tr -d "'")
            if [ -n "$load_cmd" ]; then
                eval "$load_cmd" &
                local load_pid=$!
                sleep 20
                log_info "Load command running (PID: $load_pid)"
            fi
        fi
    fi
    
    # Run collection
    local output_file="${OUTPUT:-$OUTPUT_DIR/system-info.md}"
    local md_flag=""
    [ "$FORMAT" = "markdown" ] && md_flag="--md"
    
    log_info "Running ANUMA collection..."
    python3 "$ANUMA_HOME/scripts/collect_system_info.py" "${tid_list[@]}" $md_flag > "$output_file"
    
    log_info "System information saved to: $output_file"
    
    # Cleanup load command
    if [ "$NO_LOAD" = false ] && [ -n "${load_pid:-}" ]; then
        kill $load_pid 2>/dev/null || true
        log_info "Load command stopped"
    fi
}

# Analyze bottlenecks
cmd_analyze() {
    check_prerequisites
    
    if [ -z "$INPUT" ]; then
        log_error "--input file must be specified"
    fi
    
    if [ ! -f "$INPUT" ]; then
        log_error "Input file not found: $INPUT"
    fi
    
    log_info "Analyzing bottlenecks from: $INPUT"
    
    local output_file="${OUTPUT:-$OUTPUT_DIR/bottleneck-analysis.md}"
    
    # For now, output guidance for manual analysis
    cat > "$output_file" <<EOF
# Bottleneck Analysis Report

## Input
System Info: $INPUT

## Analysis Guidelines

Based on the collected system information, analyze the following:

1. **Topology Misalignment**
   - Check if operator dispatch threads are on NUMA nodes local to their NPU
   - Look for threads on NUMA 2+ when NPU is on NUMA 0

2. **L3 Cache Contention**
   - Identify cache-heavy threads sharing NUMA with latency-sensitive threads
   - Check LLC usage distribution across NUMA nodes

3. **Cross-NUMA Communication**
   - Identify high-communication thread pairs with large NUMA distance
   - Look for asymmetric worker placement

4. **CPU Affinity Over-concentration**
   - Check if too many threads are bound to same CPU range
   - Look for scheduling conflicts in /proc/<pid>/status

5. **Memory Pressure**
   - Check for excessive memory usage on single NUMA node
   - Look for frequent page-ins/outs

## Recommendations

Please review the system info file and identify specific bottlenecks.
Then use 'generate-strategy' command to create binding commands.

EOF

    log_info "Analysis template saved to: $output_file"
    log_info "Please review and identify specific bottlenecks manually"
}

# Generate binding strategy
cmd_generate_strategy() {
    check_prerequisites
    
    if [ -z "$INPUT" ]; then
        log_error "--input file must be specified"
    fi
    
    if [ ! -f "$INPUT" ]; then
        log_error "Input file not found: $INPUT"
    fi
    
    log_info "Generating binding strategy from: $INPUT"
    
    local output_file="${OUTPUT:-./bindcore.sh}"
    
    # Create template binding script
    cat > "$output_file" <<'EOF'
#!/bin/bash
# Core Affinity Strategy for Inference Workload
# Generated by ANUMA Optimization Skill

set -euo pipefail

echo "Applying core affinity bindings..."

# TODO: Replace with actual bindings based on bottleneck analysis
# Example:
# taskset -cp <cpu_list> <pid>
# migratepages <pid> <from-nodes> <to-nodes>

echo "Bindings applied successfully"
EOF

    chmod +x "$output_file"
    
    log_info "Binding strategy template saved to: $output_file"
    log_info "Please edit the script with actual binding commands based on your analysis"
}

# Apply binding strategy
cmd_apply() {
    if [ -z "$SCRIPT" ]; then
        log_error "--script file must be specified"
    fi
    
    if [ ! -f "$SCRIPT" ]; then
        log_error "Script file not found: $SCRIPT"
    fi
    
    log_info "Applying binding strategy from: $SCRIPT"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN - Commands that would be executed:"
        cat "$SCRIPT"
        return
    fi
    
    # Confirm before applying
    if [ "$FORCE" = false ]; then
        echo -n "Apply binding strategy? This will modify running processes. [y/N] "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 0
        fi
    fi
    
    # Execute the script
    bash "$SCRIPT"
    
    log_info "Binding strategy applied successfully"
}

# Verify bindings
cmd_verify() {
    if [ -z "$PIDS" ] && [ -z "$TIDS" ]; then
        log_error "Either --pids or --tids must be specified"
    fi
    
    local targets=()
    if [ -n "$TIDS" ]; then
        IFS=',' read -ra targets <<< "$TIDS"
    elif [ -n "$PIDS" ]; then
        IFS=',' read -ra targets <<< "$PIDS"
    fi
    
    log_info "Verifying CPU/NUMA bindings..."
    
    for target in "${targets[@]}"; do
        echo ""
        echo "=== Process/Thread $target ==="
        
        if [ -d "/proc/$target" ]; then
            echo "CPU Affinity:"
            taskset -p "$target" 2>/dev/null || echo "  N/A"
            
            echo "Allowed CPUs/Memory:"
            grep -E "Cpus_allowed|Mems_allowed" "/proc/$target/status" 2>/dev/null || echo "  N/A"
            
            echo "Current CPU:"
            ps -o pid,tid,psr,comm -p "$target" 2>/dev/null || echo "  N/A"
        else
            log_warn "Process/Thread $target not found"
        fi
    done
}

# Full optimization workflow
cmd_optimize() {
    check_prerequisites
    
    if [ -z "$PIDS" ]; then
        log_error "--pids must be specified for optimization workflow"
    fi
    
    log_info "Starting ANUMA optimization workflow..."
    
    # Phase 1 & 2: Collect
    log_info "Phase 1-2: Collecting system information..."
    cmd_collect
    
    local sysinfo_file="${OUTPUT:-$OUTPUT_DIR/system-info.md}"
    
    # Phase 3: Analyze (if enabled)
    if [ "$ANALYZE" = true ]; then
        log_info "Phase 3: Analyzing bottlenecks..."
        INPUT="$sysinfo_file"
        OUTPUT="$OUTPUT_DIR/bottleneck-analysis.md"
        cmd_analyze
    fi
    
    # Phase 4: Generate strategy
    log_info "Phase 4: Generating binding strategy..."
    INPUT="$sysinfo_file"
    OUTPUT="$OUTPUT_DIR/bindcore.sh"
    cmd_generate_strategy
    
    # Phase 5: Apply (if enabled)
    if [ "$BIND" = true ]; then
        log_info "Phase 5: Applying binding strategy..."
        SCRIPT="$OUTPUT_DIR/bindcore.sh"
        cmd_apply
        
        # Verify
        log_info "Verifying bindings..."
        cmd_verify
    else
        log_info "Skipping binding application (use --bind to apply)"
        log_info "Binding script saved to: $OUTPUT_DIR/bindcore.sh"
        log_info "Review and edit the script, then run:"
        log_info "  $(basename "$0") apply --script $OUTPUT_DIR/bindcore.sh"
    fi
    
    log_info "Optimization workflow complete!"
    log_info "Results saved to: $OUTPUT_DIR/"
}

# Main
main() {
    parse_args "$@"
    
    if [ -z "$COMMAND" ]; then
        usage
        exit 1
    fi
    
    case "$COMMAND" in
        collect)
            cmd_collect
            ;;
        analyze)
            cmd_analyze
            ;;
        generate-strategy)
            cmd_generate_strategy
            ;;
        apply)
            cmd_apply
            ;;
        verify)
            cmd_verify
            ;;
        optimize)
            cmd_optimize
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            ;;
    esac
}

main "$@"
