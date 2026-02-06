# ANUMA Optimization Skill

为 Witty/OpenClaw 提供的 NPU 推理负载 NUMA 亲和性优化 Skill。

## 功能

通过 5 阶段工作流优化 vLLM-Ascend 等 NPU 推理工作负载：

1. **进程发现** - 识别关键推理进程/线程
2. **系统采集** - 收集 NPU/CPU 拓扑、亲和性、内存分布
3. **瓶颈分析** - 分析拓扑对齐、缓存竞争、NUMA 通信等问题
4. **策略生成** - 生成可执行的 `taskset`/`numactl` 绑核脚本
5. **实施验证** - 应用绑定并验证结果

## 快速开始

### 1. 配置 ANUMA 路径

```bash
# 编辑 witty 配置
witty config set skills.anuma-optimization.env.ANUMA_HOME ~/.witty/skills/anuma-optimization/anuma
```

### 2. 配置打流命令

编辑 `anuma/config/load_command.yaml`，设置你的推理负载命令。

### 3. 运行优化

```bash
# 发现推理进程
npu-smi info
ps -ef | grep vllm

# 运行完整优化流程
witty skill anuma-optimization optimize --pids 12345,12346 --analyze --bind
```

## 命令

- `witty skill anuma-optimization collect` - 采集系统信息
- `witty skill anuma-optimization analyze` - 分析瓶颈
- `witty skill anuma-optimization generate-strategy` - 生成绑核策略
- `witty skill anuma-optimization apply` - 应用绑定
- `witty skill anuma-optimization verify` - 验证绑定
- `witty skill anuma-optimization optimize` - 完整工作流

## 依赖

- Linux 系统
- NPU 驱动（npu-smi）
- taskset, lscpu, ps

## 详细文档

参见 [SKILL.md](SKILL.md)
