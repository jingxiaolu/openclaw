# Witty Skill 使用指南

本文档介绍了如何在 Witty/OpenClaw 中使用 ANUMA Optimization 和 OSMind Monitor 两个 Skill。

---

## 📊 OSMind Monitor Skill - 系统性能监控

### 功能概述

系统性能监控和瓶颈分析工具，基于 OSMind 的 metrics-analysis。提供：

- **并行指标采集**: CPU、内存、磁盘、网络、微结构指标
- **自动瓶颈检测**: 识别性能问题并分类（严重/警告）
- **智能分析建议**: 自动提供优化建议
- **多格式输出**: 支持文本和 JSON 格式

### 自然语言触发关键词

#### 性能检查类
```
"检查系统性能"
"分析系统瓶颈"
"系统监控"
"性能分析"
"为什么我的电脑这么卡"
"CPU 使用率怎么样"
"内存占用情况"
```

#### 持续监控类
```
"监控系统"
"实时查看性能"
"像 top 一样监控"
```

#### 诊断场景
```
"诊断性能问题"
"健康检查"
"系统指标"
"收集性能数据"
```

### 使用示例

#### 示例 1: 快速性能检查
**你**: "witty，帮我检查一下系统性能，看看有没有瓶颈"

**Witty 执行**:
```bash
witty skill osmind-monitor check --duration 30
```

**输出示例**:
```
============================================================
系统指标分析报告
============================================================

总问题数: 2
严重问题: 1
警告: 1

------------------------------------------------------------
发现的问题:
------------------------------------------------------------
  [!!!] CPU使用率过高: 95.3%
  [!] 内存使用率较高: 85.2%

------------------------------------------------------------
建议:
------------------------------------------------------------
  1. 考虑优化CPU密集型任务，使用更好的并行化策略
  2. 检查是否有异常进程占用大量CPU资源
  3. 检查内存泄漏或内存使用过高的进程
============================================================
```

#### 示例 2: 详细分析
**你**: "我的电脑最近很慢，帮我详细分析一下"

**Witty 执行**:
```bash
witty skill osmind-monitor check --duration 60 --interval 0.5
```

#### 示例 3: 持续监控
**你**: "持续监控我的系统性能"

**Witty 执行**:
```bash
witty skill osmind-monitor watch --interval 5
```

### CLI 命令参考

```bash
# 综合性能检查
witty skill osmind-monitor check

# 自定义参数
witty skill osmind-monitor check --duration 60 --interval 2

# JSON 输出
witty skill osmind-monitor check --format json --output report.json

# 交互式配置
witty skill osmind-monitor check --interactive

# 持续监控
witty skill osmind-monitor watch --interval 5

# 采集原始数据
witty skill osmind-monitor collect --duration 120 --output raw-metrics.json

# 分析已有数据
witty skill osmind-monitor analyze --input metrics.json

# 运行测试
witty skill osmind-monitor test

# 查看配置
witty skill osmind-monitor config show
```

### 采集指标

- **CPU**: 使用率、核心负载、上下文切换、中断、频率、进程/线程数
- **内存**: 总量、使用率、交换空间、页面交换
- **磁盘**: I/O 读写、分区使用、I/O 延迟
- **网络**: 流量、错误率、连接数
- **微架构**: CPU 时间分配、性能统计

### 瓶颈检测阈值

```python
{
  'cpu': {
    'high_usage': 80,      # 警告
    'critical_usage': 95,  # 严重
  },
  'memory': {
    'high_usage': 80,      # 警告
    'critical_usage': 90,  # 严重
    'swap_usage_warning': 20
  },
  'disk': {
    'high_usage': 90       # 警告
  },
  'network': {
    'high_error_rate': 0.01  # 警告
  }
}
```

---

## 🚀 ANUMA Optimization Skill - NPU 推理优化

### 功能概述

NPU 推理负载 NUMA 亲和性优化工具，通过 5 阶段工作流优化 vLLM-Ascend 等推理性能：

1. **关键进程/线程识别** - 识别关键推理进程
2. **系统信息采集** - 收集 NPU/CPU 拓扑、亲和性、内存分布
3. **瓶颈分析** - 分析拓扑对齐、缓存竞争、NUMA 通信
4. **策略生成** - 生成可执行的 `taskset`/`numactl` 绑核脚本
5. **实施验证** - 应用绑定并验证结果

### 自然语言触发关键词

#### 推理优化类
```
"优化 NPU 推理"
"vLLM 性能优化"
"绑核优化"
"NUMA 优化"
"推理加速"
"降低推理延迟"
```

#### 具体场景
```
"我的 vLLM 推理很慢"
"NPU 负载不均衡"
"长尾延迟问题"
"算子下发太慢"
```

#### 技术关键词
```
"核心亲和性"
"CPU 绑定"
"内存亲和性"
"NUMA 绑定"
"inference optimization"
```

### 使用示例

#### 示例 1: 完整优化流程
**你**: "帮我优化一下 vLLM 的推理性能"

**Witty 执行**:
```bash
# 发现 vLLM 进程
npu-smi info
ps -ef | grep vllm

# 运行完整优化流程
witty skill anuma-optimization optimize --pids 12345,12346 --analyze --bind
```

**输出示例**:
```
============================================================
ANUMA Optimization - Inference Core Affinity
============================================================

Phase 1-2: Collecting system information...
✓ NPU topology collected
✓ CPU topology collected
✓ Process mapping collected

Phase 3: Analyzing bottlenecks...
⚠ Found 2 critical issues:
  [!!!] Topology Misalignment: Operator dispatch thread (TID: 12346) 
        not on NPU-local NUMA
        Current: NUMA 2, NPU 0 is on NUMA 0
  [!] Cache Contention: Worker threads sharing NUMA 0 with system services

Phase 4: Generating binding strategy...
✓ Strategy saved to: ./bindcore.sh

Phase 5: Applying binding strategy...
✓ taskset -cp 144-155 12345
✓ taskset -cp 144-155 12346
✓ migratepages 12345 0-3 0

Verification:
✓ All bindings applied successfully
✓ P99 latency improved from 45ms to 28ms (37.8% improvement)
```

#### 示例 2: 分析长尾延迟
**你**: "我的 NPU 推理有长尾延迟，帮我分析一下"

**Witty 执行**:
```bash
witty skill anuma-optimization collect --pids 12345
witty skill anuma-optimization analyze --input ./system-info.md
witty skill anuma-optimization generate-strategy --input ./analysis.md
```

#### 示例 3: 绑核优化
**你**: "我想绑核优化推理服务"

**Witty 询问**: "请提供 vLLM 的 PID"

**你**: "PID 是 12345"

**Witty 执行完整工作流**:
```bash
witty skill anuma-optimization optimize --pids 12345 --analyze --bind
```

### CLI 命令参考

```bash
# 完整优化流程
witty skill anuma-optimization optimize --pids 12345,12346 --analyze --bind

# 分步执行
witty skill anuma-optimization collect --pids 12345 --format markdown
witty skill anuma-optimization analyze --input ./system-info.md
witty skill anuma-optimization generate-strategy --input ./analysis.md --output ./bindcore.sh
witty skill anuma-optimization apply --script ./bindcore.sh

# 验证绑定
witty skill anuma-optimization verify --pids 12345,12346

# 交互式（仅采集）
witty skill anuma-optimization collect --tids 12346,12347,12348 --interactive
```

### 5 阶段工作流

#### Phase 1: 关键进程/线程识别
```bash
# 查找推理进程
npu-smi info
ps -ef | grep -E "(vllm|python)" | grep -v grep

# 列出进程线程
ps -T -p <pid> -o pid,tid,comm
```

#### Phase 2: 系统信息采集
- NPU 拓扑结构
- CPU 拓扑和 NUMA 分布
- 当前 PID-NPU 映射关系
- CPU 亲和性状态
- 进程内存分布（NUMA-aware）
- LLC（Last Level Cache）使用情况

#### Phase 3: 瓶颈分析
- **拓扑不对齐**: 算子下发线程与 NPU 不在同一 NUMA 节点
- **L3 缓存竞争**: 关键线程与其他缓存密集型线程共享 NUMA
- **跨 NUMA 通信**: 高通信频率的线程物理距离过远
- **绑核过度集中**: 太多线程绑定到相同 CPU
- **单 NUMA 内存压力过大**

#### Phase 4: 生成绑核策略
```bash
# 示例策略输出
taskset -cp 144-155 12345
taskset -cp 144-155 12346
migratepages 12345 0-3 0
migratepages 12346 0-3 1
```

#### Phase 5: 实施与验证
```bash
# 应用绑定
bash bindcore.sh

# 验证
taskset -p <pid>
cat /proc/<pid>/status | grep -E "Cpus_allowed|Mems_allowed"
```

### 最佳实践

1. **测试环境先行**: 在生产环境应用前先在测试环境验证
2. **维持负载**: 确保推理服务在采集时有真实负载
3. **明确线程角色**: 区分算子下发线程、Worker 线程等
4. **监控后效果**: 应用绑定后观察性能改善或回退
5. **对称分布**: Worker 进程应对称分布在 NUMA 节点
6. **隔离关键线程**: 算子下发线程应放在 NPU-local NUMA

---

## 🔗 组合使用场景

### 场景 1: 先监控发现问题，再深度优化

```bash
# 第 1 步：系统监控发现 CPU 瓶颈
你: "检查系统性能"
Witty: [OSMind] 发现 CPU 使用率 95%，负载过高

# 第 2 步：查看具体进程
你: "查看哪些进程占用 CPU"
Witty: [OSMind] 显示 vLLM 进程占用 80% CPU

# 第 3 步：进行 NUMA 优化
你: "优化这些推理进程的 CPU 绑定"
Witty: [ANUMA] 执行绑核优化

# 第 4 步：验证优化效果
你: "再次检查系统性能"
Witty: [OSMind] CPU 降至 60%，延迟改善 37%
```

### 场景 2: 直接从推理优化开始

```bash
你: "我的 vLLM 服务响应很慢，帮我优化"
Witty: 
  1. [ANUMA] 发现 vLLM 进程 (PID: 12345)
  2. [ANUMA] 采集系统信息 + NPU 拓扑
  3. [ANUMA] 分析瓶颈（拓扑不对齐）
  4. [ANUMA] 生成绑核策略
  5. [ANUMA] 应用绑定
  6. [OSMind] 验证优化效果（P99 延迟从 45ms 降至 28ms）
```

### 场景 3: 持续监控 + 定期优化

```bash
# 每小时采集 5 分钟指标
crontab -e
0 * * * * witty skill osmind-monitor collect --duration 300 --output /var/log/metrics/$(date +\%Y\%m\%d-\%H).json

# 发现性能下降时
你: "分析一下昨晚的性能数据"
Witty: [OSMind] 分析历史数据，发现凌晨 3 点 CPU 突增

# 针对性优化
你: "优化那时的推理服务"
Witty: [ANUMA] 执行绑核优化
```

---

## 📝 最佳实践总结

### 自然语言交互技巧

1. **描述症状而非技术术语**
   - ✅ "我的推理服务响应很慢"
   - ✅ "系统 CPU 占用很高"
   - ❌ "运行 anuma-optimization skill"

2. **提供上下文**
   - ✅ "优化我的 vLLM 服务"（提及具体应用）
   - ✅ "检查 NPU 推理性能"（提及硬件）

3. **组合使用**
   - "先检查系统性能，然后优化推理服务"
   - "监控并分析我的 NPU 负载"

### Skill 选择指南

| 场景 | 推荐 Skill | 触发词 |
|------|-----------|--------|
| 系统整体性能检查 | OSMind Monitor | "系统好卡"、"性能分析" |
| 发现性能瓶颈 | OSMind Monitor | "瓶颈分析"、"健康检查" |
| vLLM/NPU 推理慢 | ANUMA Optimization | "vLLM 太慢"、"推理优化" |
| CPU 负载不均衡 | ANUMA Optimization | "绑核"、"NUMA 优化" |
| 长尾延迟问题 | ANUMA Optimization | "长尾延迟"、"延迟优化" |

### 配置说明

#### OSMind Monitor 配置
```json5
// ~/.witty/witty.json
{
  skills: {
    entries: {
      "osmind-monitor": {
        env: {
          OSMIND_HOME: "~/.witty/skills/osmind-monitor/osmind",
        },
      },
    },
  },
}
```

#### ANUMA Optimization 配置
```json5
// ~/.witty/witty.json
{
  skills: {
    entries: {
      "anuma-optimization": {
        env: {
          ANUMA_HOME: "~/.witty/skills/anuma-optimization/anuma",
        },
      },
    },
  },
}
```

---

## 🔧 故障排除

### OSMind 问题

**Q: ImportError: No module named 'psutil'**
```bash
pip3 install psutil
# 或重新安装依赖
pip3 install -r $OSMIND_HOME/metrics-analysis/requirements.txt
```

**Q: 某些指标无法采集**
- 部分指标需要 root 权限
- 尝试: `sudo witty skill osmind-monitor check`

### ANUMA 问题

**Q: npu-smi not found**
- 确保 NPU 驱动已安装
- 检查 `npu-smi` 是否在 PATH 中

**Q: 绑核失败 permission denied**
- 部分绑定操作需要 root 权限
- 尝试: `sudo witty skill anuma-optimization apply --script bindcore.sh`

**Q: 没有性能改善**
- 确保推理服务在采集时有真实负载
- 检查瓶颈分析是否准确识别了问题
- 考虑 LLC 缓存竞争等其他因素

---

## 📚 参考文档

- [OSMind Repository](https://github.com/jingxiaolu/OSMind)
- [ANUMA Repository](https://github.com/jingxiaolu/ANUMA)
- [psutil Documentation](https://psutil.readthedocs.io/)
- Linux `taskset` and `numactl` man pages

---

*最后更新: 2026-02-06*
