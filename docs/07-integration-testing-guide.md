# ClassFinal 集成测试指南

## 测试脚本说明

项目提供了两个集成测试脚本，分别用于本地开发和 CI 环境：

### 1. 本地集成测试脚本

**文件**: `integration-test/run-local-tests.sh`

**特点**:

- ✅ 使用本地环境变量（`OSSRH_USERNAME`, `OSSRH_PASSWORD`）
- ✅ 使用国内镜像源加速构建（`USE_CHINA_MIRROR=true`）
- ✅ 详细的彩色日志输出
- ✅ 完整的测试覆盖

**使用方法**:

```bash
# 确保环境变量已设置（在 ~/.bashrc 中）
source ~/.bashrc

# 运行本地测试
bash integration-test/run-local-tests.sh
```

**测试内容**:

1. 构建 ClassFinal
2. 构建测试应用
3. 测试原始应用（未加密）
4. 加密测试应用
5. 测试无密码运行（应该失败）
6. 测试正确密码运行
7. 测试错误密码（应该被拒绝）
8. 多包加密测试
9. 多包加密应用运行测试

### 2. CI 集成测试脚本

**文件**: `integration-test/run-ci-tests.sh`

**特点**:

- ✅ 不使用国内镜像源（CI 在国外）
- ✅ 适配 GitHub Actions 环境
- ✅ 自动清理测试环境
- ✅ 与本地脚本相同的测试覆盖

**GitHub Actions 自动调用**:

- 在 `.github/workflows/ci.yml` 中自动运行
- 每次推送到 `main` 分支或创建 PR 时触发

## 环境准备

### 本地开发环境

1. **安装依赖**:

```bash
# Docker 和 docker-compose 已安装（检查）
docker --version
docker-compose --version
```

2. **配置环境变量** (已完成):

```bash
# 在 ~/.bashrc 中已添加
export OSSRH_USERNAME="4JHXaY"
export OSSRH_PASSWORD="dD5uKt1ifYlTh2t4Tu1ZOnuDKSS5uRuWU"
```

3. **加载环境变量**:

```bash
source ~/.bashrc
```

### CI 环境

GitHub Actions 环境变量自动从 Secrets 读取：

- `OSSRH_USERNAME`
- `OSSRH_PASSWORD`
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`

## 测试覆盖范围

### ✅ 已实现的测试

| 测试场景   | 说明                           | 预期结果        |
| ---------- | ------------------------------ | --------------- |
| 构建测试   | 验证 ClassFinal 和测试应用构建 | 成功            |
| 原始应用   | 测试未加密的应用运行           | 正常运行        |
| 加密功能   | 测试加密过程                   | 成功加密        |
| 无密码运行 | 尝试不提供密码运行加密应用     | 被拒绝/要求密码 |
| 正确密码   | 使用正确密码运行               | 成功运行        |
| 错误密码   | 使用错误密码运行               | 被拒绝          |
| 多包加密   | 加密多个包                     | 成功加密        |
| 多包运行   | 运行多包加密的应用             | 成功运行        |

### 📝 建议添加的测试（可选）

- [ ] Maven Plugin 集成测试
- [ ] Spring Boot 应用测试
- [ ] 大型应用性能测试
- [ ] 并发加密测试
- [ ] 不同 JDK 版本兼容性（8/11/17）

## 故障排查

### 常见问题

1. **Docker 权限问题**

```bash
# 如果遇到权限错误，将用户添加到 docker 组
sudo usermod -aG docker $USER
# 重新登录或运行
newgrp docker
```

2. **端口冲突**

```bash
# 清理所有容器和卷
docker-compose down -v
docker system prune -f
```

3. **镜像源慢**

```bash
# 本地测试会自动使用国内镜像源
# 如果仍然很慢，检查 Docker 配置
cat /etc/docker/daemon.json
```

4. **环境变量未加载**

```bash
# 确认环境变量
echo $OSSRH_USERNAME
echo "Password length: ${#OSSRH_PASSWORD}"

# 重新加载
source ~/.bashrc
```

## 开发工作流

### 提交前本地测试

```bash
# 1. 运行本地集成测试
bash integration-test/run-local-tests.sh

# 2. 如果测试通过，提交代码
git add .
git commit -m "feat: your changes"

# 3. 推送到 GitHub（触发 CI）
git push origin main
```

### CI 测试流程

1. 推送代码到 GitHub
2. GitHub Actions 自动触发
3. 运行 `run-ci-tests.sh`
4. 查看测试结果: https://github.com/ygqygq2/classfinal/actions

## 性能优化

### 本地测试加速

```bash
# 使用 Docker 缓存
# Maven 依赖会缓存在 Docker volume 中

# 查看缓存卷
docker volume ls | grep classfinal

# 如需重新构建（清除缓存）
docker-compose build --no-cache
```

### CI 测试加速

GitHub Actions 已配置缓存:

- Maven 依赖缓存
- Docker layer 缓存

## 测试脚本对比

| 特性     | 本地脚本       | CI 脚本               |
| -------- | -------------- | --------------------- |
| 镜像源   | 国内（阿里云） | 国外（Maven Central） |
| 环境变量 | ~/.bashrc      | GitHub Secrets        |
| 日志     | 详细彩色输出   | 结构化输出            |
| 清理     | 自动 trap      | 显式清理              |
| 失败处理 | 详细提示       | CI 友好               |

## 相关文档

- [Docker 使用指南](02-docker-usage.md)
- [开发指南](03-development-guide.md)
- [Maven Central 部署](05-maven-central-deployment.md)
