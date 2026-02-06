# OSMind Monitor Skill

为 Witty/OpenClaw 提供的系统性能监控和瓶颈分析 Skill。

## 功能

基于 OSMind 的 metrics-analysis 工具，提供：

- **并行指标采集**: CPU、内存、磁盘、网络、微结构指标
- **自动瓶颈检测**: 识别性能问题并分类（严重/警告）
- **智能分析建议**: 自动提供优化建议
- **多格式输出**: 支持文本和 JSON 格式

## 快速开始

### 1. 配置 OSMind 路径

```bash
witty config set skills.osmind-monitor.env.OSMIND_HOME ~/.witty/skills/osmind-monitor/osmind
```

### 2. 运行性能检查

```bash
# 默认 30 秒检查
witty skill osmind-monitor check

# 详细检查（60 秒）
witty skill osmind-monitor check --duration 60

# JSON 输出
witty skill osmind-monitor check --format json

# 交互式配置
witty skill osmind-monitor check --interactive
```

## 命令

- `witty skill osmind-monitor check` - 综合性能检查
- `witty skill osmind-monitor collect` - 采集原始指标
- `witty skill osmind-monitor analyze` - 分析已有指标
- `witty skill osmind-monitor watch` - 持续监控模式
- `witty skill osmind-monitor test` - 运行测试
- `witty skill osmind-monitor config` - 配置管理

## 依赖

- Python 3.8+
- psutil 库

## 详细文档

参见 [SKILL.md](SKILL.md)
