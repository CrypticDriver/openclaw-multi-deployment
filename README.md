# OpenClaw Multi-Deployment on AWS

**在单个 VPC 中批量部署多个 OpenClaw 实例的企业级解决方案**

## 🚀 Quick Start (One-Click Deploy)

**Total time:** 15 minutes | **Cost:** ~$103/month

```bash
# Clone repository
git clone https://github.com/CrypticDriver/openclaw-multi-deployment.git
cd openclaw-multi-deployment

# One-command deployment
./scripts/quick-start.sh \
  --key-pair your-keypair-name \
  --email your-email@example.com
```

**What you get:**
- ✅ Complete VPC infrastructure
- ✅ Application Load Balancer
- ✅ First OpenClaw instance running
- ✅ Web UI access URL

**See [ONE_CLICK_DEPLOY.md](ONE_CLICK_DEPLOY.md) for detailed instructions**

---

## 🎯 项目特点

### 相比原版的改进

| 特性 | 原版 | 本方案 |
|------|------|--------|
| 部署方式 | 单实例 CloudFormation | 批量部署 + 集中管理 |
| VPC 成本 | 每实例 $22/月 | 共享 VPC $22/月（节省 90%+） |
| 负载均衡 | 无 | ALB 统一入口 |
| 扩缩容 | 手动 | Auto Scaling 自动 |
| 实例管理 | 分散 | 集中式控制面板 |
| 配置管理 | 本地文件 | SSM Parameter Store |
| 监控告警 | 基础 | CloudWatch + SNS 告警 |

### 核心优势

1. **成本优化**
   - 共享 VPC Endpoints：$22/月（vs 原版每实例 $22）
   - 10 个实例节省：$198/月
   - 100 个实例节省：$2,178/月

2. **易于扩展**
   - 一条命令部署 N 个实例
   - Auto Scaling 自动调整容量
   - 支持蓝绿部署和滚动更新

3. **企业级管理**
   - 统一的 ALB 入口（单个域名）
   - 集中式配置管理
   - 全量审计日志
   - 自动健康检查和故障转移

4. **高可用性**
   - 多 AZ 部署
   - 自动故障恢复
   - 零停机更新

## 🏗️ 架构设计

```
                    ┌─────────────────────────┐
                    │   Internet Gateway      │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Application LB (ALB)   │
                    │  - SSL Termination      │
                    │  - Path-based Routing   │
                    └────────────┬────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
   ┌────▼─────┐           ┌─────▼─────┐          ┌──────▼────┐
   │OpenClaw 1│           │OpenClaw 2 │          │OpenClaw N │
   │(EC2/ASG) │           │(EC2/ASG)  │   ...    │(EC2/ASG)  │
   └────┬─────┘           └─────┬─────┘          └──────┬────┘
        │                       │                        │
        └───────────────────────┼────────────────────────┘
                                │
                    ┌───────────▼────────────┐
                    │    VPC Endpoints       │
                    │  - Bedrock             │
                    │  - SSM                 │
                    │  - CloudWatch          │
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │   Amazon Bedrock       │
                    │   (Nova/Claude/etc)    │
                    └────────────────────────┘
```

## 📦 项目结构

```
openclaw-multi-deployment/
├── README.md                          # 本文件
├── ARCHITECTURE.md                    # 详细架构设计
├── cloudformation/
│   ├── 01-vpc-foundation.yaml        # VPC 基础设施
│   ├── 02-shared-resources.yaml      # 共享资源（ALB、Endpoints）
│   ├── 03-openclaw-instance.yaml     # OpenClaw 实例模板
│   └── 04-management-dashboard.yaml  # 管理控制台
├── scripts/
│   ├── deploy-foundation.sh          # 部署基础设施
│   ├── deploy-instance.sh            # 部署单个实例
│   ├── deploy-batch.sh               # 批量部署
│   ├── scale-instances.sh            # 扩缩容管理
│   └── health-check.sh               # 健康检查
├── config/
│   ├── instance-template.json        # 实例配置模板
│   └── bedrock-models.json           # Bedrock 模型配置
├── monitoring/
│   ├── cloudwatch-dashboard.json     # CloudWatch 仪表盘
│   └── alarms.yaml                   # 告警规则
└── docs/
    ├── DEPLOYMENT.md                 # 部署指南
    ├── MANAGEMENT.md                 # 管理指南
    ├── TROUBLESHOOTING.md            # 故障排查
    └── COST_OPTIMIZATION.md          # 成本优化
```

## 🚀 快速开始

### 前置条件

- AWS CLI 已配置
- 具有管理员权限的 AWS 账号
- SSH Key Pair（用于 EC2 访问）
- 已启用 Bedrock 模型访问

### 1. 克隆仓库

```bash
git clone https://github.com/YOUR_USERNAME/openclaw-multi-deployment.git
cd openclaw-multi-deployment
```

### 2. 部署基础设施（一次性）

```bash
# 部署 VPC 和共享资源
./scripts/deploy-foundation.sh \
  --region us-west-2 \
  --key-pair your-keypair-name \
  --stack-name openclaw-foundation
```

**等待 10-15 分钟**，基础设施创建完成。

### 3. 部署 OpenClaw 实例

#### 单个实例

```bash
./scripts/deploy-instance.sh \
  --name openclaw-prod-1 \
  --model global.amazon.nova-2-lite-v1:0 \
  --instance-type t4g.medium
```

#### 批量部署（5 个实例）

```bash
./scripts/deploy-batch.sh \
  --count 5 \
  --prefix openclaw-prod \
  --model global.amazon.nova-2-lite-v1:0 \
  --instance-type t4g.medium
```

### 4. 访问实例

```bash
# 获取 ALB 地址
aws cloudformation describe-stacks \
  --stack-name openclaw-foundation \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text

# 访问特定实例
https://<ALB-URL>/openclaw-prod-1/?token=<token>
https://<ALB-URL>/openclaw-prod-2/?token=<token>
```

## 💰 成本分析

### 基础设施成本（共享，一次性）

| 服务 | 配置 | 月成本 |
|------|------|--------|
| VPC | 1 个 | $0 |
| ALB | 1 个 | $16.20 |
| VPC Endpoints | 3 个 | $21.60 |
| NAT Gateway | 1 个 | $32.40 |
| **小计** | | **$70.20/月** |

### 每个实例成本

| 服务 | 配置 | 月成本 |
|------|------|--------|
| EC2 | t4g.medium | $24.00 |
| EBS | 30GB gp3 | $2.40 |
| Bedrock | Nova 2 Lite | $5-8 |
| **小计** | | **$31-34/月** |

### 规模化成本对比

| 实例数 | 原版总成本 | 本方案总成本 | 节省 |
|--------|-----------|-------------|------|
| 1 | $81 | $104 | ❌ -$23 |
| 5 | $405 | $225 | ✅ $180 (44%) |
| 10 | $810 | $380 | ✅ $430 (53%) |
| 50 | $4,050 | $1,620 | ✅ $2,430 (60%) |
| 100 | $8,100 | $3,170 | ✅ $4,930 (61%) |

**结论：** 5 个实例以上开始显著节省成本！

## 📊 管理和监控

### 查看所有实例状态

```bash
./scripts/health-check.sh --all
```

输出示例：
```
Instance          Status    CPU    Memory   Uptime    Last Response
openclaw-prod-1   healthy   12%    45%      3d 5h     200ms
openclaw-prod-2   healthy   8%     38%      3d 5h     180ms
openclaw-prod-3   degraded  78%    92%      12h       2.5s  ⚠️
openclaw-prod-4   healthy   15%    52%      3d 5h     220ms
openclaw-prod-5   healthy   9%     41%      3d 5h     190ms
```

### 扩缩容

```bash
# 扩容到 10 个实例
./scripts/scale-instances.sh --desired-count 10

# 缩容到 3 个实例
./scripts/scale-instances.sh --desired-count 3
```

### CloudWatch Dashboard

访问：`https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=OpenClaw-Multi`

监控指标：
- 每实例 CPU/内存使用率
- Bedrock API 调用次数和延迟
- ALB 请求数和错误率
- 实例健康状态

## 🔧 高级功能

### 1. 蓝绿部署

```bash
# 创建新版本（绿）
./scripts/deploy-instance.sh --name openclaw-v2-1 --version v2

# 测试新版本
curl https://<ALB>/openclaw-v2-1/health

# 切换流量（通过 ALB 权重）
./scripts/traffic-shift.sh --from v1 --to v2 --percent 50

# 全量切换
./scripts/traffic-shift.sh --from v1 --to v2 --percent 100

# 下线旧版本
./scripts/terminate-instances.sh --prefix openclaw-v1
```

### 2. 自动扩缩容策略

```yaml
# config/autoscaling-policy.yaml
TargetTrackingScaling:
  CPUUtilization: 70%        # CPU > 70% 时扩容
  MemoryUtilization: 80%     # 内存 > 80% 时扩容
  RequestCountPerTarget: 100 # 每实例请求数 > 100 时扩容

ScaleIn:
  CooldownPeriod: 300        # 5 分钟冷却
  
ScaleOut:
  CooldownPeriod: 60         # 1 分钟快速扩容
```

### 3. 集中式配置管理

所有实例配置存储在 SSM Parameter Store：

```bash
# 更新全局模型配置
aws ssm put-parameter \
  --name /openclaw/global/default-model \
  --value "global.amazon.nova-2-lite-v1:0" \
  --type String \
  --overwrite

# 所有实例自动应用（30 秒内）
```

### 4. 多租户隔离

每个实例可以配置不同的：
- Bedrock 模型
- 消息渠道（WhatsApp/Telegram）
- 用户组
- 速率限制

适用场景：
- SaaS 服务（每客户一个实例）
- 部门隔离（财务/HR/IT）
- 开发/测试/生产环境

## 🛡️ 安全最佳实践

1. **网络隔离**
   - 实例在私有子网，无公网 IP
   - ALB 在公有子网，统一入口
   - VPC Endpoints 私有通信

2. **IAM 最小权限**
   - 每实例独立 IAM Role
   - 只能访问自己的 S3 bucket
   - Bedrock 访问通过 IAM 控制

3. **加密**
   - EBS 卷加密（KMS）
   - ALB SSL/TLS 终止
   - Secrets Manager 存储敏感信息

4. **审计**
   - CloudTrail 记录所有 API 调用
   - VPC Flow Logs 网络流量
   - CloudWatch Logs 应用日志

## 📚 文档

- [部署指南](docs/DEPLOYMENT.md) - 详细部署步骤
- [管理指南](docs/MANAGEMENT.md) - 日常运维操作
- [架构设计](ARCHITECTURE.md) - 深入架构分析
- [故障排查](docs/TROUBLESHOOTING.md) - 常见问题解决
- [成本优化](docs/COST_OPTIMIZATION.md) - 降低成本技巧

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License

## 🙏 致谢

基于 [aws-samples/sample-OpenClaw-on-AWS-with-Bedrock](https://github.com/aws-samples/sample-OpenClaw-on-AWS-with-Bedrock) 改进

---

**Built with ❤️ for scalable AI deployments**
