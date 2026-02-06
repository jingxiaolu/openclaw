---
name: osmind-monitor
description: System performance monitoring and bottleneck analysis using OSMind metrics collector. Collects CPU, memory, disk, network metrics in parallel and provides intelligent bottleneck detection with optimization recommendations.
metadata:
  {
    "openclaw":
      {
        "emoji": "📊",
        "os": ["darwin", "linux"],
        "requires":
          { "bins": ["python3"], "env": ["OSMIND_HOME"] },
        "install":
          [
            {
              "id": "clone-osmind",
              "kind": "git-clone",
              "url": "https://github.com/jingxiaolu/OSMind.git",
              "targetDir": "~/.openclaw/skills/osmind-monitor/osmind",
              "label": "Clone OSMind monitoring toolkit",
            },
            {
              "id": "install-deps",
              "kind": "command",
              "command": "pip3 install -r ~/.openclaw/skills/osmind-monitor/osmind/metrics-analysis/requirements.txt",
              "label": "Install OSMind Python dependencies",
            },
          ],
      },
  }
---

# OSMind Monitor Skill

System performance monitoring and bottleneck analysis for OpenClaw/Witty using OSMind metrics collector.

## Overview

This skill provides comprehensive system performance monitoring by leveraging OSMind's parallel metrics collection and intelligent bottleneck detection:

1. **Parallel Metrics Collection** - Simultaneously collect CPU, memory, disk, network, and microarchitecture metrics
2. **Automatic Bottleneck Detection** - Identify performance issues with configurable thresholds
3. **Intelligent Analysis** - Get actionable recommendations for resolving bottlenecks
4. **Multiple Output Formats** - Support for both human-readable text and machine-parseable JSON

## Prerequisites

- **OS**: macOS or Linux
- **Python**: 3.8 or higher
- **Tools**: python3, pip3
- **Environment**: Set `OSMIND_HOME` to the OSMind installation path

## Configuration

Set the OSMind home directory in your config:

```json5
// ~/.openclaw/openclaw.json
{
  skills: {
    entries: {
      "osmind-monitor": {
        env: {
          OSMIND_HOME: "~/.openclaw/skills/osmind-monitor/osmind",
        },
      },
    },
  },
}
```

## Usage

### Quick Start

```bash
# Run system performance check (30 seconds default)
witty skill osmind-monitor check

# Quick scan (10 seconds)
witty skill osmind-monitor check --duration 10

# Detailed analysis (60 seconds)
witty skill osmind-monitor check --duration 60 --interval 0.5

# Get JSON output for further processing
witty skill osmind-monitor check --format json --output report.json

# Interactive configuration
witty skill osmind-monitor check --interactive
```

### Commands Reference

#### `witty skill osmind-monitor check`

Run comprehensive system performance check.

```
Usage: witty skill osmind-monitor check [options]

Options:
  --duration SECONDS     Collection duration (default: 30)
  --interval SECONDS     Sampling interval (default: 1.0)
  --format FORMAT        Output format: json|text (default: text)
  --output FILE          Save output to file
  --interactive          Interactive configuration mode
  -i                     Alias for --interactive

Examples:
  witty skill osmind-monitor check
  witty skill osmind-monitor check --duration 60 --interval 2
  witty skill osmind-monitor check --format json --output /tmp/metrics.json
  witty skill osmind-monitor check -i
```

#### `witty skill osmind-monitor collect`

Collect raw metrics without analysis.

```
Usage: witty skill osmind-monitor collect [options]

Options:
  --duration SECONDS     Collection duration (default: 30)
  --interval SECONDS     Sampling interval (default: 1.0)
  --output FILE          Save raw metrics to file

Examples:
  witty skill osmind-monitor collect --duration 120 --output raw-metrics.json
```

#### `witty skill osmind-monitor analyze`

Analyze previously collected metrics.

```
Usage: witty skill osmind-monitor analyze --input FILE [options]

Options:
  --input FILE           Path to collected metrics file
  --format FORMAT        Output format: json|text (default: text)
  --output FILE          Save analysis to file

Examples:
  witty skill osmind-monitor analyze --input metrics.json
  witty skill osmind-monitor analyze --input metrics.json --format json
```

#### `witty skill osmind-monitor watch`

Continuous monitoring mode (like `top` but with analysis).

```
Usage: witty skill osmind-monitor watch [options]

Options:
  --interval SECONDS     Update interval (default: 5)
  --duration SECONDS     Total watch duration, 0 for infinite (default: 0)
  --thresholds FILE      Custom thresholds config file

Examples:
  witty skill osmind-monitor watch
  witty skill osmind-monitor watch --interval 10
  witty skill osmind-monitor watch --duration 300
```

#### `witty skill osmind-monitor test`

Run built-in tests to verify installation.

```
Usage: witty skill osmind-monitor test

Examples:
  witty skill osmind-monitor test
```

#### `witty skill osmind-monitor config`

View or edit threshold configuration.

```
Usage: witty skill osmind-monitor config [action]

Actions:
  show                   Display current configuration
  edit                   Open configuration in editor
  reset                  Reset to default configuration

Examples:
  witty skill osmind-monitor config show
  witty skill osmind-monitor config edit
```

## Metrics Collected

### CPU Metrics
- `usage_percent`: Overall CPU usage percentage
- `cores_usage`: Per-core usage statistics
- `load_avg`: 1/5/15 minute load averages
- `context_switches`: Context switch count
- `interrupts`: Interrupt count
- `freq_current/min/max`: CPU frequency information
- `processes`: Number of running processes
- `threads`: Total thread count

### Memory Metrics
- `total/used/free/available`: Memory usage breakdown
- `percent`: Memory usage percentage
- `swap_total/used/percent`: Swap space statistics
- `swap_sin/sout`: Swap in/out activity

### Disk Metrics
- `read/write_bytes`: I/O throughput
- `read/write_count`: I/O operation counts
- `read/write_time_ms`: I/O latency
- `busy_time`: Disk busy percentage
- `partitions`: Per-partition usage

### Network Metrics
- `bytes_sent/recv`: Network throughput
- `packets_sent/recv`: Packet counts
- `errin/errout`: Error counts
- `dropin/dropout`: Dropped packets
- `connections_established`: Active connections

### Microarchitecture Metrics
- `cpu_times`: Per-CPU time distribution
- `perf_stats`: Performance counter statistics

## Bottleneck Detection Thresholds

Default thresholds (can be customized in config):

```python
{
  'cpu': {
    'high_usage': 80,      # Warning at 80%
    'critical_usage': 95,  # Critical at 95%
    'high_load_per_core': 2.0
  },
  'memory': {
    'high_usage': 80,      # Warning at 80%
    'critical_usage': 90,  # Critical at 90%
    'swap_usage_warning': 20
  },
  'disk': {
    'high_usage': 90       # Warning at 90%
  },
  'network': {
    'high_error_rate': 0.01  # Warning at 1% error rate
  }
}
```

## Output Examples

### Text Format

```
============================================================
系统指标分析报告
============================================================

总问题数: 3
严重问题: 1
警告: 2

------------------------------------------------------------
发现的问题:
------------------------------------------------------------
  [!!!] CPU使用率过高: 95.3%
  [!] 内存使用率较高: 85.2%
  [!] 磁盘空间不足: 92.1%

------------------------------------------------------------
建议:
------------------------------------------------------------
  1. 考虑优化CPU密集型任务，使用更好的并行化策略
  2. 检查是否有异常进程占用大量CPU资源
  3. 检查内存泄漏或内存使用过高的进程
  4. 清理磁盘空间，删除不必要的文件
============================================================
```

### JSON Format

```json
{
  "metrics": {
    "cpu": [
      {
        "timestamp": 1704067200.123,
        "usage_percent": 45.2,
        "cores_usage": [40.1, 50.3, ...],
        "load_avg": [2.1, 1.8, 1.5]
      }
    ],
    "memory": [...],
    "disk": [...],
    "network": [...],
    "microarch": [...]
  },
  "analysis": {
    "summary": {
      "total_issues": 3,
      "critical": 1,
      "warnings": 2
    },
    "issues": [
      {
        "severity": "critical",
        "component": "cpu",
        "message": "CPU使用率过高: 95.3%",
        "value": 95.3,
        "threshold": 95
      }
    ],
    "recommendations": [
      "考虑优化CPU密集型任务，使用更好的并行化策略",
      "检查是否有异常进程占用大量CPU资源"
    ]
  }
}
```

## Use Cases

### 1. Performance Diagnostics

When your system is slow or unresponsive:

```bash
witty skill osmind-monitor check --duration 60
```

### 2. Baseline Establishment

Before deploying a new application:

```bash
witty skill osmind-monitor check --format json --output baseline.json
```

### 3. Continuous Monitoring

Watch system performance in real-time:

```bash
witty skill osmind-monitor watch --interval 5
```

### 4. Automated Health Checks

Integrate into scripts or CI/CD:

```bash
#!/bin/bash
witty skill osmind-monitor check --format json | \
  jq -e '.analysis.summary.critical == 0' || \
  echo "Critical performance issues detected!"
```

### 5. Historical Analysis

Collect metrics over time for trend analysis:

```bash
# Every hour, collect 5 minutes of metrics
0 * * * * witty skill osmind-monitor collect --duration 300 --output /var/log/metrics/$(date +\%Y\%m\%d-\%H).json
```

## Best Practices

1. **Establish Baseline**: Run metrics collection during normal operation to establish baseline performance
2. **Regular Checks**: Schedule periodic checks (e.g., daily or weekly) to detect degradation early
3. **Under Load**: When diagnosing issues, ensure the system is under realistic load
4. **Multiple Samples**: Use longer durations (60+ seconds) for more accurate analysis
5. **Compare Baselines**: Compare current metrics with historical baselines to identify trends
6. **Interactive Mode**: Use `--interactive` for first-time use to understand available options

## Troubleshooting

### ImportError: No module named 'psutil'

```bash
pip3 install psutil
# Or reinstall OSMind dependencies
pip3 install -r $OSMIND_HOME/metrics-analysis/requirements.txt
```

### Permission Denied

Some metrics require elevated privileges:

```bash
# Run with sudo for complete metrics
sudo witty skill osmind-monitor check
```

### No Metrics Collected

Check Python version and OSMind installation:

```bash
python3 --version  # Should be 3.8+
witty skill osmind-monitor test
```

## Integration with Other Skills

Combine with other OpenClaw/Witty skills:

```bash
# Check system health before running intensive tasks
witty skill osmind-monitor check && witty skill anuma-optimization optimize --pids 12345

# Monitor during optimization
witty skill osmind-monitor watch --duration 300 &
witty skill anuma-optimization apply --script bindcore.sh
```

## References

- [OSMind Repository](https://github.com/jingxiaolu/OSMind)
- [psutil Documentation](https://psutil.readthedocs.io/)
- Linux Performance Monitoring Best Practices
