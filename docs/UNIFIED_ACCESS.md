# 统一访问方案

OpenClaw Multi-Deployment 支持多种统一访问方式，适合不同场景。

---

## 方案对比

| 方案 | 访问方式 | 优点 | 适用场景 |
|------|---------|------|---------|
| **路径路由** | `openclaw.com/user-1/` | 简单，已实现 | 个人/小团队 |
| **子域名** | `user-1.openclaw.com` | 优雅，独立域名 | SaaS 服务 |
| **管理面板** | `openclaw.com/dashboard` | 可视化管理 | 企业/运维 |

---

## 方案 1：路径路由（已实现）

### 架构

```
https://openclaw.yourdomain.com
    ├─ /openclaw-1/*  → 实例 1
    ├─ /openclaw-2/*  → 实例 2
    └─ /openclaw-3/*  → 实例 3
```

### 访问方式

```bash
# 用户 A
https://openclaw.yourdomain.com/openclaw-1/?token=xxx

# 用户 B
https://openclaw.yourdomain.com/openclaw-2/?token=yyy
```

### 配置

**已自动配置！** 每个实例部署时会自动在 ALB 创建路径规则。

查看当前路由：
```bash
aws elbv2 describe-rules \
  --listener-arn $(aws cloudformation describe-stacks \
    --stack-name openclaw-shared \
    --query 'Stacks[0].Outputs[?OutputKey==`HTTPListenerArn`].OutputValue' \
    --output text) \
  --region us-west-2
```

### 优点
- ✅ 无需额外配置
- ✅ 单个 SSL 证书
- ✅ 部署即可用

### 缺点
- ❌ URL 较长
- ❌ 不够优雅

---

## 方案 2：子域名路由（推荐 SaaS）

### 架构

```
客户 A: alice.openclaw.yourdomain.com → 实例 1
客户 B: bob.openclaw.yourdomain.com   → 实例 2
客户 C: charlie.openclaw.yourdomain.com → 实例 3
```

### 配置步骤

#### 1. 准备域名和证书

```bash
# 在 Route 53 创建 Hosted Zone
aws route53 create-hosted-zone \
  --name openclaw.yourdomain.com \
  --caller-reference $(date +%s)

# 申请通配符证书 (*.openclaw.yourdomain.com)
aws acm request-certificate \
  --domain-name "*.openclaw.yourdomain.com" \
  --validation-method DNS \
  --region us-west-2
```

#### 2. 为 ALB 配置 HTTPS

```bash
# 获取证书 ARN
CERT_ARN=$(aws acm list-certificates \
  --region us-west-2 \
  --query 'CertificateSummaryList[?DomainName==`*.openclaw.yourdomain.com`].CertificateArn' \
  --output text)

# 获取 ALB ARN
ALB_ARN=$(aws cloudformation describe-stacks \
  --stack-name openclaw-shared \
  --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
  --output text)

# 添加 HTTPS Listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=404}"
```

#### 3. 为每个实例添加子域名

```bash
# 使用脚本自动配置
./scripts/add-subdomain.sh \
  openclaw-1 \
  alice \
  Z1234567890ABC  # 你的 Hosted Zone ID
```

这会创建：
- ALB 规则：`alice.openclaw.yourdomain.com` → openclaw-1
- DNS 记录：`alice.openclaw.yourdomain.com` → ALB

#### 4. 访问

```bash
# 用户 A
https://alice.openclaw.yourdomain.com/?token=xxx

# 用户 B
https://bob.openclaw.yourdomain.com/?token=yyy
```

### 优点
- ✅ 优雅的 URL
- ✅ 每个用户独立域名
- ✅ 专业形象

### 缺点
- ❌ 需要域名
- ❌ 需要 SSL 证书

---

## 方案 3：管理面板（推荐企业）

### 架构

```
https://openclaw.yourdomain.com/
    ├─ /               # 管理面板 (dashboard)
    ├─ /openclaw-1/*  # 实例 1
    ├─ /openclaw-2/*  # 实例 2
    └─ /openclaw-3/*  # 实例 3
```

### 部署管理面板

```bash
# 1. 创建 S3 bucket 托管静态网站
aws s3 mb s3://openclaw-dashboard-${ACCOUNT_ID} --region us-west-2

# 2. 上传管理面板
cd dashboard
aws s3 sync . s3://openclaw-dashboard-${ACCOUNT_ID}/ --acl public-read

# 3. 配置 ALB 规则指向 S3
# (或部署到 EC2/Lambda)
```

### 功能

**已实现：**
- ✅ 列出所有实例
- ✅ 显示健康状态
- ✅ 一键打开 Web UI
- ✅ 实例管理

**待实现：**
- [ ] 自动获取 token
- [ ] 扩缩容控制
- [ ] 日志查看
- [ ] 成本监控

### 访问

打开浏览器访问：`https://openclaw.yourdomain.com/`

![Dashboard Preview](../docs/images/dashboard-preview.png)

### 优点
- ✅ 可视化管理
- ✅ 统一入口
- ✅ 易于使用

### 缺点
- ❌ 需要额外开发
- ❌ 需要认证系统

---

## 混合方案（推荐）

**组合使用 3 种方案：**

```
https://openclaw.yourdomain.com/
    ├─ /                    # 管理面板（内部运维）
    ├─ /alice/*            # 路径路由（备用）
    └─ alice.openclaw.yourdomain.com  # 子域名（对外）
```

**优点：**
- 管理面板：内部运维使用
- 子域名：给客户使用（优雅）
- 路径路由：备用方案

---

## 实战案例

### 场景：SaaS 服务（10 个客户）

```bash
# 1. 部署基础设施
./scripts/quick-start.sh --key-pair my-key

# 2. 批量部署 10 个实例
./scripts/deploy-batch.sh \
  --count 10 \
  --prefix openclaw-prod \
  --key-pair my-key

# 3. 为每个客户配置子域名
for i in {1..10}; do
  ./scripts/add-subdomain.sh \
    openclaw-prod-$i \
    customer-$i \
    Z1234567890ABC
done

# 4. 给客户发送访问链接
# customer-1.openclaw.yourdomain.com
# customer-2.openclaw.yourdomain.com
# ...
```

### 场景：企业内部（团队协作）

```bash
# 1. 部署单实例
./scripts/quick-start.sh --key-pair my-key --instance-name team-dev

# 2. 配置团队域名
./scripts/add-subdomain.sh team-dev dev Z1234567890ABC

# 3. 团队访问
https://dev.openclaw.yourdomain.com/?token=xxx
```

---

## API 访问

所有实例也支持 API 访问：

```bash
# 路径路由
curl -H "Authorization: Bearer $TOKEN" \
  https://openclaw.yourdomain.com/openclaw-1/api/sessions

# 子域名
curl -H "Authorization: Bearer $TOKEN" \
  https://alice.openclaw.yourdomain.com/api/sessions
```

---

## 安全建议

### 1. Token 管理

```bash
# 存储在 SSM Parameter Store (已实现)
aws ssm get-parameter \
  --name /openclaw/openclaw-1/token \
  --with-decryption

# 定期轮换
./scripts/rotate-token.sh openclaw-1
```

### 2. IP 白名单

```bash
# 修改 Security Group
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 443 \
  --cidr 1.2.3.4/32
```

### 3. WAF（Web Application Firewall）

```bash
# 创建 WAF 并关联到 ALB
aws wafv2 create-web-acl \
  --name openclaw-waf \
  --scope REGIONAL \
  --region us-west-2
```

---

## 总结

| 需求 | 最佳方案 |
|------|---------|
| **快速开始** | 路径路由（已实现） |
| **SaaS 服务** | 子域名 + 管理面板 |
| **企业内部** | 单实例 + 路径路由 |
| **大规模部署** | 子域名 + API |

**推荐：** 从路径路由开始，后续按需升级到子域名。

---

**下一步：** [部署管理面板](DASHBOARD.md) | [配置子域名](SUBDOMAIN_SETUP.md)
