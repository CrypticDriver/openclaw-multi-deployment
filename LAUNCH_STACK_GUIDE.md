# 🚀 One-Click Deployment Guide

## Launch Stack Button（真正的一键部署）

**无需命令行！无需脚本！直接在浏览器完成！**

---

## Step 1: Click Launch Button

点击下面的按钮，在 AWS CloudFormation 控制台打开：

### US West (Oregon) - us-west-2

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?stackName=openclaw-complete&templateURL=https://raw.githubusercontent.com/CrypticDriver/openclaw-multi-deployment/master/cloudformation/00-master-all-in-one.yaml)

### US East (N. Virginia) - us-east-1

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?stackName=openclaw-complete&templateURL=https://raw.githubusercontent.com/CrypticDriver/openclaw-multi-deployment/master/cloudformation/00-master-all-in-one.yaml)

### EU (Ireland) - eu-west-1

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/create/review?stackName=openclaw-complete&templateURL=https://raw.githubusercontent.com/CrypticDriver/openclaw-multi-deployment/master/cloudformation/00-master-all-in-one.yaml)

### AP Northeast (Tokyo) - ap-northeast-1

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-northeast-1#/stacks/create/review?stackName=openclaw-complete&templateURL=https://raw.githubusercontent.com/CrypticDriver/openclaw-multi-deployment/master/cloudformation/00-master-all-in-one.yaml)

---

## Step 2: Fill Parameters

在 CloudFormation 控制台，只需填写以下参数：

### 必填项（只有 1 个）

| Parameter | Description | Example |
|-----------|-------------|---------|
| **KeyPairName** | EC2 Key Pair 名称 | `my-keypair` |

**不知道 Key Pair 名称？**
1. 在 CloudFormation 控制台，点击 KeyPairName 下拉框
2. 选择一个已有的 Key Pair
3. 如果没有，去 EC2 控制台创建一个

### 可选项（使用默认值即可）

| Parameter | Default | Description |
|-----------|---------|-------------|
| InstanceName | `openclaw-1` | 第一个实例名称 |
| InstanceType | `t4g.medium` | EC2 实例类型 |
| BedrockModel | `nova-2-lite` | Bedrock 模型 |
| NotificationEmail | (空) | 告警邮箱（可选） |
| MinSize | `1` | 最小实例数 |
| DesiredCapacity | `1` | 期望实例数 |
| MaxSize | `3` | 最大实例数 |

**推荐：** 第一次部署全部使用默认值！

---

## Step 3: Create Stack

1. 滚动到页面底部
2. ✅ 勾选 "I acknowledge that AWS CloudFormation might create IAM resources"
3. 点击 **"Create stack"** 按钮
4. 等待 15-20 分钟

**进度查看：**
- 在 "Events" 标签页查看部署进度
- 看到 "CREATE_COMPLETE" 表示成功

---

## Step 4: Get Access URLs

部署完成后，点击 **"Outputs"** 标签页：

| Output Key | Description |
|------------|-------------|
| **DashboardURL** | 🎛️ 管理面板 URL（最重要） |
| **AccessURL** | 第一个实例的访问 URL |
| **GetTokenCommand** | 获取 token 的命令 |

### 4.1 打开管理面板

复制 `DashboardURL`，在浏览器打开，例如：
```
https://abc123xyz.execute-api.us-west-2.amazonaws.com
```

**你会看到：**
```
┌─────────────────────────────────────┐
│  🐕 OpenClaw Multi-Deployment       │
│                                     │
│  总实例数: 1   健康实例: 1   总容量: 1│
│                                     │
│  ┌──────────────┐                  │
│  │ openclaw-1   │                  │
│  │ ✓ 健康       │                  │
│  │ CPU: 15%     │                  │
│  │ 实例: 1/1    │                  │
│  │ [打开 Web UI]│                  │
│  └──────────────┘                  │
└─────────────────────────────────────┘
```

### 4.2 访问 OpenClaw 实例

**方式 1：** 在管理面板点击 "打开 Web UI" 按钮（推荐）

**方式 2：** 手动获取 token 并访问
```bash
# 在 CloudShell 或本地终端运行 GetTokenCommand
aws ssm get-parameter \
  --region us-west-2 \
  --name /openclaw/openclaw-1/token \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text

# 然后访问
http://your-alb-url/openclaw-1/?token=YOUR_TOKEN
```

---

## Step 5: Connect Messaging

在 OpenClaw Web UI：

1. 点击左侧 "Channels"
2. 选择 WhatsApp / Telegram / Discord
3. 扫码或填写配置
4. 开始聊天！

---

## 🎉 Done! You're Ready!

**部署完成后你拥有：**

✅ 完整的 VPC 基础设施  
✅ 自动扩缩容的 OpenClaw 实例  
✅ 可视化管理面板  
✅ 随时可以部署更多实例  

---

## Deploy More Instances

部署第二个、第三个实例：

### 方式 1：使用管理面板（未来功能）

点击 Dashboard 的 "+" 按钮

### 方式 2：再次部署 Instance Stack

1. 在 CloudFormation 控制台
2. 点击 "Create stack"
3. 使用模板 URL:
   ```
   https://raw.githubusercontent.com/CrypticDriver/openclaw-multi-deployment/master/cloudformation/03-openclaw-instance.yaml
   ```
4. 填写参数（改个名字，如 `openclaw-2`）
5. Create stack

**5 分钟后，管理面板自动显示新实例！**

---

## Cost Breakdown

| Component | Monthly Cost |
|-----------|-------------|
| VPC Foundation (NAT Gateway) | $32 |
| ALB (Load Balancer) | $22 |
| VPC Endpoints | $22 |
| CloudWatch Logs | $5 |
| Dashboard (Lambda + API Gateway) | $0 |
| **Foundation Total** | **$81** |
|  |  |
| Each OpenClaw Instance (t4g.medium) | $24 |
| EBS Storage (30GB) | $2.40 |
| Bedrock (估算) | $5-8 |
| **Per Instance Total** | **~$31** |
|  |  |
| **1 Instance Grand Total** | **~$112/month** |
| **5 Instances Grand Total** | **~$236/month** |
| **10 Instances Grand Total** | **~$391/month** |

**vs 原版（每实例独立 VPC）：**
- 5 实例：节省 **$169/month (42%)**
- 10 实例：节省 **$419/month (52%)**

---

## Cleanup (Delete Everything)

不想用了？一键删除所有资源：

1. 在 CloudFormation 控制台
2. 选中 `openclaw-complete` stack
3. 点击 "Delete"
4. 等待 10 分钟

**所有资源自动删除，不再产生费用！**

---

## Troubleshooting

### Stack creation failed?

**常见问题：**

1. **Key Pair 不存在**
   - 去 EC2 → Key Pairs 创建一个

2. **Bedrock 未启用**
   - 去 Bedrock 控制台启用模型访问

3. **权限不足**
   - 确保你的 IAM 用户有 Admin 权限

4. **区域不支持 ARM**
   - 改用 `t3.medium` 而非 `t4g.medium`

### Can't access instances?

1. 检查 Security Group 是否允许你的 IP
2. 确认实例状态是 "Healthy"
3. 检查 CloudWatch Logs

### Need help?

- 查看 CloudFormation Events（详细错误信息）
- 查看 CloudWatch Logs
- Open GitHub Issue

---

## What's Next?

- [ ] 连接消息平台（WhatsApp/Telegram）
- [ ] 部署更多实例
- [ ] 配置自定义域名
- [ ] 设置 CloudWatch Alarms
- [ ] 配置 Auto Scaling 策略

---

**Ready to launch?** [Click here to deploy! →](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?stackName=openclaw-complete&templateURL=https://raw.githubusercontent.com/CrypticDriver/openclaw-multi-deployment/master/cloudformation/00-master-all-in-one.yaml)

**Total time:** 15-20 minutes  
**Difficulty:** Easy (just click buttons)  
**Cost:** ~$112/month for 1 instance
