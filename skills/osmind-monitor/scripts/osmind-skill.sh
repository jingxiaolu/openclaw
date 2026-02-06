#!/usr/bin/env bash
#
# OSMind Monitor Skill Wrapper for OpenClaw/Witty
# Provides CLI interface to OSMind metrics analysis toolkit
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OSMIND_HOME="${OSMIND_HOME:-$SKILL_DIR/osmind}"
METRICS_DIR="$OSMIND_HOME/metrics-analysis"
DEFAULT_OUTPUT_DIR="./osmind-output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" && exit 1; }
log_section() { echo -e "\n${BLUE}=== $* ===${NC}"; }

# Check prerequisites
check_prerequisites() {
    if ! command -v python3 &>/dev/null; then
        log_error "python3 is required but not installed"
    fi
    
    if [ ! -d "$OSMIND_HOME" ]; then
        log_error "OSMind not found at $OSMIND_HOME. Please run install first."
    fi
    
    if [ ! -f "$METRICS_DIR/collector.py" ]; then
        log_error "OSMind collector not found. Please check OSMIND_HOME path."
    fi
}

# Show usage
usage() {
    cat <<EOF
OSMind Monitor Skill for OpenClaw/Witty

Usage: $(basename "$0") <command> [options]

Commands:
  check                Run comprehensive system performance check
  collect              Collect raw metrics without analysis
  analyze              Analyze previously collected metrics
  watch                Continuous monitoring mode
  test                 Run built-in tests
  config               View or edit threshold configuration

Global Options:
  -h, --help           Show this help message
  --output-dir DIR     Output directory (default: $DEFAULT_OUTPUT_DIR)

check/collect Options:
  --duration SECONDS   Collection duration (default: 30)
  --interval SECONDS   Sampling interval (default: 1.0)
  --format FORMAT      Output format: json|text (default: text)
  --output FILE        Save output to file
  --interactive        Interactive configuration mode (-i)

analyze Options:
  --input FILE         Path to collected metrics file
  --format FORMAT      Output format: json|text (default: text)
  --output FILE        Save analysis to file

watch Options:
  --interval SECONDS   Update interval (default: 5)
  --duration SECONDS   Total watch duration, 0 for infinite (default: 0)

config Actions:
  show                 Display current configuration
  edit                 Open configuration in editor
  reset                Reset to default configuration

Examples:
  # Quick performance check
  $(basename "$0") check

  # Detailed analysis
  $(basename "$0") check --duration 60 --interval 0.5

  # JSON output for automation
  $(basename "$0") check --format json --output report.json

  # Interactive mode
  $(basename "$0") check --interactive

  # Watch mode
  $(basename "$0") watch --interval 5

EOF
}

# Parse arguments
COMMAND=""
DURATION=""
INTERVAL=""
FORMAT="text"
INPUT=""
OUTPUT=""
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
INTERACTIVE=false
CONFIG_ACTION=""

parse_args() {
    COMMAND="${1:-}"
    shift || true
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --duration)
                DURATION="$2"
                shift 2
                ;;
            --interval)
                INTERVAL="$2"
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
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --interactive|-i)
                INTERACTIVE=true
                shift
                ;;
            show|edit|reset)
                if [ "$COMMAND" = "config" ]; then
                    CONFIG_ACTION="$1"
                    shift
                else
                    log_error "Unknown option: $1"
                fi
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

# Run system check
cmd_check() {
    check_prerequisites
    
    log_info "Starting OSMind system performance check..."
    
    # Build arguments
    local args=()
    [ -n "$DURATION" ] && args+=("--duration" "$DURATION")
    [ -n "$INTERVAL" ] && args+=("--interval" "$INTERVAL")
    [ "$FORMAT" = "json" ] && args+=("--format" "json")
    [ -n "$OUTPUT" ] && args+=("--output" "$OUTPUT")
    [ "$INTERACTIVE" = true ] && args+=("--interactive")
    
    # Create output directory if needed
    if [ -n "$OUTPUT" ]; then
        mkdir -p "$(dirname "$OUTPUT")"
    fi
    
    # Run collector
    cd "$METRICS_DIR"
    if [ ${#args[@]} -eq 0 ]; then
        python3 collector.py
    else
        python3 collector.py "${args[@]}"
    fi
}

# Collect raw metrics
cmd_collect() {
    check_prerequisites
    
    log_info "Collecting raw metrics..."
    
    # For raw collection, we use json format by default
    local args=()
    [ -n "$DURATION" ] && args+=("--duration" "$DURATION")
    [ -n "$INTERVAL" ] && args+=("--interval" "$INTERVAL")
    args+=("--format" "json")
    
    local output_file="${OUTPUT:-$OUTPUT_DIR/raw-metrics-$(date +%Y%m%d-%H%M%S).json}"
    mkdir -p "$OUTPUT_DIR"
    args+=("--output" "$output_file")
    
    cd "$METRICS_DIR"
    python3 collector.py "${args[@]}"
    
    log_info "Raw metrics saved to: $output_file"
}

# Analyze existing metrics
cmd_analyze() {
    check_prerequisites
    
    if [ -z "$INPUT" ]; then
        log_error "--input file must be specified for analyze command"
    fi
    
    if [ ! -f "$INPUT" ]; then
        log_error "Input file not found: $INPUT"
    fi
    
    log_info "Analyzing metrics from: $INPUT"
    
    # Check if it's a metrics file we can analyze
    if ! python3 -c "import json; json.load(open('$INPUT'))" 2>/dev/null; then
        log_error "Invalid JSON file: $INPUT"
    fi
    
    # For now, we'll just display a summary
    # In a full implementation, this would use OSMind's analysis functions
    log_section "Metrics Analysis Summary"
    
    python3 <<EOF
import json
with open('$INPUT', 'r') as f:
    data = json.load(f)

if 'analysis' in data:
    analysis = data['analysis']
    print(f"Total Issues: {analysis.get('summary', {}).get('total_issues', 'N/A')}")
    print(f"Critical: {analysis.get('summary', {}).get('critical', 'N/A')}")
    print(f"Warnings: {analysis.get('summary', {}).get('warnings', 'N/A')}")
    
    if 'issues' in analysis and analysis['issues']:
        print("\nDetected Issues:")
        for issue in analysis['issues'][:5]:  # Show first 5
            severity = issue.get('severity', 'unknown')
            component = issue.get('component', 'unknown')
            message = issue.get('message', 'N/A')
            icon = "[!]" if severity == "warning" else "[!!!]"
            print(f"  {icon} [{component.upper()}] {message}")
    
    if 'recommendations' in analysis and analysis['recommendations']:
        print("\nRecommendations:")
        for i, rec in enumerate(analysis['recommendations'][:3], 1):
            print(f"  {i}. {rec}")
else:
    print("No analysis data found. Raw metrics only.")
    if 'metrics' in data:
        metrics = data['metrics']
        print(f"\nAvailable Metrics: {', '.join(metrics.keys())}")
EOF

    if [ -n "$OUTPUT" ]; then
        cp "$INPUT" "$OUTPUT"
        log_info "Analysis saved to: $OUTPUT"
    fi
}

# Watch mode (continuous monitoring)
cmd_watch() {
    check_prerequisites
    
    local interval="${INTERVAL:-5}"
    local duration="${DURATION:-0}"
    
    log_info "Starting continuous monitoring (interval: ${interval}s, press Ctrl+C to stop)..."
    
    local count=0
    local max_count=$((duration > 0 ? duration / interval : 999999))
    
    while [ $count -lt $max_count ]; do
        clear
        echo "$(date '+%Y-%m-%d %H:%M:%S') - System Monitor (Update $((count+1)))"
        echo "============================================================"
        
        cd "$METRICS_DIR"
        python3 collector.py --duration 1 --interval 1 --format text 2>/dev/null || true
        
        count=$((count + 1))
        
        if [ $count -lt $max_count ]; then
            echo ""
            echo "Next update in ${interval}s... (Ctrl+C to stop)"
            sleep "$interval"
        fi
    done
}

# Run tests
cmd_test() {
    check_prerequisites
    
    log_info "Running OSMind tests..."
    
    cd "$METRICS_DIR"
    
    if [ -f "test.py" ]; then
        python3 test.py
    else
        log_warn "No test.py found, running basic collector test..."
        python3 collector.py --duration 5 --interval 1 --format text
    fi
}

# Config management
cmd_config() {
    check_prerequisites
    
    local config_file="$METRICS_DIR/config.json"
    
    case "${CONFIG_ACTION:-show}" in
        show)
            log_info "Current OSMind Configuration:"
            if [ -f "$config_file" ]; then
                cat "$config_file"
            else
                echo "No custom configuration found. Using defaults."
            fi
            ;;
        edit)
            log_info "Opening configuration in editor..."
            ${EDITOR:-vi} "$config_file"
            ;;
        reset)
            log_warn "Resetting configuration to defaults..."
            if [ -f "$config_file" ]; then
                rm "$config_file"
                log_info "Configuration reset. Defaults will be used."
            else
                log_info "No custom configuration to reset."
            fi
            ;;
        *)
            log_error "Unknown config action: $CONFIG_ACTION"
            ;;
    esac
}

# Main
main() {
    parse_args "$@"
    
    if [ -z "$COMMAND" ]; then
        usage
        exit 1
    fi
    
    case "$COMMAND" in
        check)
            cmd_check
            ;;
        collect)
            cmd_collect
            ;;
        analyze)
            cmd_analyze
            ;;
        watch)
            cmd_watch
            ;;
        test)
            cmd_test
            ;;
        config)
            cmd_config
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            ;;
    esac
}

main "$@"
