---
name: anuma-optimization
description: Optimize NPU inference workloads for latency and throughput by performing CPU core affinity and NUMA placement tuning. This skill analyzes system topology, identifies bottlenecks, and generates executable core binding strategies for inference processes.
metadata:
  {
    "openclaw":
      {
        "emoji": "🚀",
        "os": ["linux"],
        "requires":
          { "bins": ["taskset", "npu-smi", "lscpu", "ps"], "env": ["ANUMA_HOME"] },
        "install":
          [
            {
              "id": "clone-anuma",
              "kind": "git-clone",
              "url": "https://github.com/jingxiaolu/ANUMA.git",
              "targetDir": "~/.openclaw/skills/anuma-optimization/anuma",
              "label": "Clone ANUMA optimization toolkit",
            },
          ],
      },
  }
---

# ANUMA Optimization Skill

Optimize NPU inference workloads (e.g., vLLM-Ascend) for latency and throughput by performing CPU core affinity and NUMA placement tuning.

## Overview

This skill provides a 5-phase workflow to eliminate long-tail latency and latency jitter in NPU inference workloads:

1. **Key Process/Thread Discovery** - Identify critical inference processes
2. **System Information Collection** - Gather NPU/CPU topology, affinity, memory distribution
3. **Bottleneck Analysis** - Analyze topology alignment, cache contention, NUMA communication
4. **Core Affinity Strategy Generation** - Generate executable `taskset`/`numactl` commands
5. **Affinity Implementation** - Apply bindings and verify results

## Prerequisites

- **OS**: Linux (required for NPU support)
- **Hardware**: NPU-equipped system (e.g., Ascend)
- **Tools**: `taskset`, `npu-smi`, `lscpu`, `ps`, optionally `numactl`, `perf`
- **Environment**: Set `ANUMA_HOME` to the ANUMA toolkit path

## Configuration

Set the ANUMA home directory in your config:

```json5
// ~/.openclaw/openclaw.json
{
  skills: {
    entries: {
      "anuma-optimization": {
        env: {
          ANUMA_HOME: "~/.openclaw/skills/anuma-optimization/anuma",
        },
      },
    },
  },
}
```

Edit the load command for your inference workload:

```bash
# Edit {ANUMA_HOME}/config/load_command.yaml
# This command runs before system collection to maintain load pressure
```

## Usage

### Quick Start

```bash
# 1. Identify inference processes
npu-smi info
ps -ef | grep vllm

# 2. Run full optimization workflow
witty skill anuma-optimize --pids <pid1,pid2,...> --analyze --bind

# 3. Or step by step
witty skill anuma-collect --pids <pid1,pid2,...>
witty skill anuma-analyze --input ./system-info.md
witty skill anuma-bind --strategy ./bind-strategy.json
```

### Detailed Workflow

#### Phase 1: Discover Key Processes

Identify the main inference process and its threads:

```bash
# Find vLLM or other inference processes
npu-smi info
ps -ef | grep -E "(vllm|python)" | grep -v grep

# List threads of a process
ps -T -p <pid> -o pid,tid,comm

# Identify critical threads (top 20-30)
# - Main inference process
# - Worker processes
# - Operator dispatch threads
# - Communication threads
```

#### Phase 2: Collect System Information

```bash
# Run ANUMA collection with load pressure
# (This internally runs the load_command from config/load_command.yaml)
witty skill anuma-collect --tids <tid1,tid2,...> --format markdown

# Or manually
cd $ANUMA_HOME
python3 scripts/collect_system_info.py <tid1> <tid2> ... --md
```

**Collected Data:**
- NPU topology and usage
- CPU topology (cores, NUMA nodes, cache hierarchy)
- Current PID-NPU mapping
- CPU affinity status
- Process memory distribution (NUMA-aware)
- LLC (Last Level Cache) usage

#### Phase 3: Analyze Bottlenecks

The skill analyzes:

- **Topology Misalignment**: Operator dispatch threads not on NUMA nodes affiliated with their NPU
- **L3 Cache Contention**: Critical threads sharing NUMA with cache-heavy processes
- **Cross-NUMA Communication**: High communication between physically distant entities
- **Over-concentration**: Too many threads bound to same CPUs causing scheduling conflicts
- **Memory Pressure**: Excessive memory usage on single NUMA node

**Guidelines for Analysis:**
- Workers should be **physically symmetric** across NUMA for consistent latency
- Operator dispatch threads are extremely latency-sensitive - isolate them
- Neighboring NUMA nodes are physically closer - prefer migration to adjacent nodes
- Threads can be bound at CPU granularity to leverage L1/L2 cache

#### Phase 4: Generate Binding Strategy

```bash
# Generate executable binding commands
witty skill anuma-generate-strategy --input ./system-info.md --output ./bindcore.sh

# Review the generated strategy
cat ./bindcore.sh
```

**Example Strategy Output:**

```bash
#!/bin/bash
# Core Affinity Strategy for Inference Workload

# Operator dispatch threads - bind to NPU-local cores
taskset -cp 144-155 12345
taskset -cp 144-155 12346

# Worker processes - symmetric distribution across NUMA nodes
taskset -cp 0-23 12347
taskset -cp 48-71 12348

# Memory migration to local NUMA
migratepages 12345 0-3 0
migratepages 12346 0-3 1
```

#### Phase 5: Apply and Verify

```bash
# Apply the binding strategy
witty skill anuma-apply --script ./bindcore.sh

# Verify bindings
taskset -p <pid>
cat /proc/<pid>/status | grep -E "Cpus_allowed|Mems_allowed"
```

## Commands Reference

### `witty skill anuma-optimize`

Run complete optimization workflow.

```
Usage: witty skill anuma-optimize --pids <pids> [options]

Options:
  --pids <pid1,pid2,...>     Target process IDs (comma-separated)
  --tids <tid1,tid2,...>     Target thread IDs (comma-separated, alternative to pids)
  --analyze                  Perform bottleneck analysis (default: true)
  --bind                     Apply binding strategy (default: false, dry-run)
  --force                    Apply bindings without confirmation
  --output <dir>             Output directory for reports (default: ./anuma-output)

Examples:
  witty skill anuma-optimize --pids 12345,12346 --analyze
  witty skill anuma-optimize --pids 12345 --bind --force
```

### `witty skill anuma-collect`

Collect system information for target processes/threads.

```
Usage: witty skill anuma-collect --pids <pids> | --tids <tids> [options]

Options:
  --pids <pids>              Process IDs to analyze
  --tids <tids>              Thread IDs to analyze (alternative to pids)
  --format <json|markdown>   Output format (default: markdown)
  --load                     Run load command before collection (default: true)
  --output <file>            Output file path

Examples:
  witty skill anuma-collect --pids 12345,12346 --format markdown --output ./sysinfo.md
  witty skill anuma-collect --tids 12346,12347,12348
```

### `witty skill anuma-analyze`

Analyze collected system information for bottlenecks.

```
Usage: witty skill anuma-analyze --input <file> [options]

Options:
  --input <file>             Path to system info file (markdown or json)
  --output <file>            Output analysis report path
  --format <json|markdown>   Output format (default: markdown)

Examples:
  witty skill anuma-analyze --input ./system-info.md --output ./analysis.md
```

### `witty skill anuma-generate-strategy`

Generate core binding strategy from analysis.

```
Usage: witty skill anuma-generate-strategy --input <file> [options]

Options:
  --input <file>             Path to analysis report or system info
  --output <file>            Output script path (default: ./bindcore.sh)
  --format <shell|json>      Output format (default: shell)

Examples:
  witty skill anuma-generate-strategy --input ./analysis.md --output ./bindcore.sh
```

### `witty skill anuma-apply`

Apply binding strategy to running processes.

```
Usage: witty skill anuma-apply --script <file> [options]

Options:
  --script <file>            Path to binding script (e.g., bindcore.sh)
  --dry-run                  Show commands without executing
  --verify                   Verify bindings after application (default: true)

Examples:
  witty skill anuma-apply --script ./bindcore.sh
  witty skill anuma-apply --script ./bindcore.sh --dry-run
```

### `witty skill anuma-verify`

Verify current CPU/NUMA bindings.

```
Usage: witty skill anuma-verify --pids <pids> | --tids <tids>

Options:
  --pids <pids>              Process IDs to verify
  --tids <tids>              Thread IDs to verify

Examples:
  witty skill anuma-verify --pids 12345,12346
```

## Output Reports

### System Information Report

Generated during collection phase:

```markdown
## System Topology

### NPU Topology
| NPU ID | NUMA Node | Usage |
|--------|-----------|-------|
| 0      | 0         | 85%   |
| 1      | 1         | 82%   |

### CPU Topology
- NUMA Nodes: 4
- Cores per NUMA: 24
- Total Cores: 96

### Process Mapping
| PID | TID | Name | NPU | NUMA | CPUs Allowed |
|-----|-----|------|-----|------|--------------|
| ... | ... | ...  | ... | ...  | ...          |
```

### Bottleneck Analysis Report

Identifies performance issues:

```markdown
## Bottleneck Summary

### Critical Issues
1. **Topology Misalignment**: Operator dispatch thread (TID: 12346) not on NPU-local NUMA
   - Current: NUMA 2
   - NPU 0 is on NUMA 0
   - Recommendation: Migrate to NUMA 0 cores 144-155

2. **Cache Contention**: Worker threads sharing NUMA 0 with system services
   - Recommendation: Isolate workers to dedicated cores
```

### Optimization Result Report

Final report after implementation:

```markdown
# Inference Core Affinity Optimization Result Report

## Key Processes/Threads & Pre-Affinity Status
- PIDs: 12345, 12346, 12347
- CPU/NUMA Summary: [See system info]

## Executed Affinity Strategy
- taskset -cp 144-155 12345 ✓
- taskset -cp 144-155 12346 ✓
- migratepages 12345 0-3 0 ✓

## Performance Comparison (Optional)
- Pre-optimization P99 latency: 45ms
- Post-optimization P99 latency: 28ms
- Improvement: 37.8%
```

## Best Practices

1. **Always test in non-production first**: Verify binding strategy impact before applying to production
2. **Maintain load during collection**: Ensure inference service is under realistic load when collecting system info
3. **Document thread roles**: Clearly identify which threads handle operator dispatch vs computation
4. **Monitor after binding**: Watch for performance improvements or regressions after applying bindings
5. **Symmetric worker placement**: Ensure worker processes are distributed symmetrically across NUMA for consistent latency
6. **Isolate operator dispatch**: Keep operator dispatch threads on NPU-local NUMA with minimal cache contention

## Troubleshooting

### Collection fails with "npu-smi not found"
- Ensure NPU drivers are installed
- Check `npu-smi` is in PATH

### Permission denied on taskset
- Run with appropriate privileges (sudo may be required for some bindings)
- Check `/proc/<pid>/status` ownership

### No performance improvement
- Verify inference service was under load during collection
- Check if bottleneck was correctly identified
- Consider LLC (Last Level Cache) contention from other system processes

## References

- [ANUMA Repository](https://github.com/jingxiaolu/ANUMA)
- [vLLM-Ascend Documentation](https://docs.vllm.ai/)
- Linux `taskset` and `numactl` man pages
