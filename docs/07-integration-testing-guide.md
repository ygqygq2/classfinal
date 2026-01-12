# ClassFinal 集成测试指南

## 测试架构

项目采用 **统一的 Docker Compose 测试架构**，包含 **24 个完整测试场景**，同时支持本地开发和 CI 环境。

## 测试脚本说明

### 1. 本地集成测试脚本

**文件**: `integration-test/run-local-tests.sh`

**特点**:

- ✅ 使用本地环境变量（`SONATYPE_USERNAME`, `SONATYPE_PASSWORD`）
- ✅ 使用国内镜像源加速构建（`USE_CHINA_MIRROR=true`）
- ✅ 详细的彩色日志输出
- ✅ 完整的 24 个测试场景（包含 2.0.1 新功能）

**使用方法**:

```bash
# 确保环境变量已设置（在 ~/.bashrc 中）
source ~/.bashrc

# 运行本地测试
bash integration-test/run-local-tests.sh
```

### 2. CI 集成测试脚本

**文件**: `integration-test/run-ci-tests.sh`

**特点**:

- ✅ 不使用国内镜像源（CI 在国外）
- ✅ 适配 GitHub Actions 环境
- ✅ 自动清理测试环境
- ✅ 与本地脚本相同的完整测试覆盖

**GitHub Actions 自动调用**:

- 在 `.github/workflows/ci.yml` 中自动运行
- 每次推送到 `main` 分支或创建 PR 时触发

## 测试场景列表

### 步骤 1-21: 核心功能测试

1. **构建 ClassFinal** - 编译主项目
2. **构建测试应用** - 准备测试用 JAR
3. **测试原始应用** - 验证未加密应用运行
4. **准备测试应用** - 复制到共享卷
5. **加密测试应用** - 基础加密功能
6. **测试无密码运行** - 验证密码保护
7. **测试正确密码** - 验证密码验证
8. **测试错误密码** - 验证密码拒绝
9. **准备多包测试** - 多包加密准备
10. **执行多包加密** - 多个包同时加密
11. **测试多包加密应用** - 验证多包运行
12. **测试排除类名** - exclude 参数功能
13. **测试无密码模式** - -pwd '#' 模式
14. **安装 Maven 插件** - 插件本地安装
15. **Maven 插件集成测试** - 完整 Maven 工作流
16. **lib 依赖加密** - -libjars 参数测试
17. **配置文件加密** - Spring 配置加密
18. **机器码绑定** - -code 参数测试
19. **WAR 包加密** - WAR 文件支持
20. **反编译保护验证** - 反编译检测
21. **Maven 本地安装** - Maven install 测试

### 步骤 22-24: 2.0.1 新功能测试

22. **配置文件参数测试 (--config)**
    - 创建 YAML 配置文件
    - 使用 `--config` 参数加密
    - 验证加密应用运行

23. **密码文件参数测试 (--password-file)**
    - 创建密码文件
    - 使用 `--password-file` 参数加密
    - 验证使用相同密码运行

24. **加密验证测试 (--verify)**
    - 加密并启用 `--verify` 自动验证
    - 检查验证通过状态
    - 确认加密文件可用

## CI/CD 工作流

GitHub Actions 包含 3 个主要作业：

### 1. integration-test

- **名称**: Integration Tests (Docker Compose)
- **运行**: 所有 19 个集成测试场景
- **环境**: Ubuntu latest + Docker Compose
- **触发**: 每次 push 或 PR

### 2. unit-test  

- **名称**: Unit Tests (Maven)
- **矩阵测试**: JDK 8, 11, 17
- **运行**: Maven 单元测试
- **目的**: 确保多 JDK 版本兼容性

### 3. build-and-verify

- **名称**: Build and Verify
- **依赖**: integration-test + unit-test
- **运行**: 完整构建和打包
- **产物**: 上传所有 JAR 文件

## 测试内容

### 完整的 19 个测试场景
## 测试内容

### 完整的 19 个测试场景

1. **构建 ClassFinal** - 构建加密工具
2. **构建测试应用** - 构建测试用 JAR
3. **原始应用测试** - 验证未加密应用运行
4. **应用加密** - 测试基本加密功能
5. **无密码运行测试** - 验证需要密码
6. **正确密码测试** - 验证加密应用正常运行
7. **错误密码测试** - 验证密码验证有效
8. **多包加密准备** - 准备多包测试环境
9. **多包加密执行** - 测试多包加密功能
10. **多包应用运行** - 验证多包加密应用
11. **排除类名准备** - 准备排除测试
12. **排除类名加密** - 测试排除功能
13. **无密码模式** - 测试无密码加密
14. **Maven 插件安装** - 安装插件到本地仓库
15. **Maven 插件测试** - 测试 Maven 插件集成
16. **lib 依赖加密** - 测试外部依赖加密
17. **配置文件加密** - 测试配置文件保护
18. **机器码绑定** - 测试机器码绑定功能
19. **WAR 包加密** - 测试 WAR 包加密
20. **反编译保护** - 验证反编译保护有效性

详细说明请参考 [完整测试覆盖文档](08-complete-test-coverage.md)

## 环境准备

### 本地开发环境

1. **安装依赖**:

```bash
# Docker 和 docker-compose
docker --version
docker-compose --version
```

2. **配置环境变量** (可选):

```bash
# 在 ~/.bashrc 中添加（如需测试 Maven 部署）
export SONATYPE_USERNAME="your_username"
export SONATYPE_PASSWORD="your_password"
```

3. **加载环境变量**:

```bash
source ~/.bashrc
```

### CI 环境

GitHub Actions 环境变量从 Repository Secrets 读取：

- `SONATYPE_USERNAME`
- `SONATYPE_PASSWORD`
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`

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

| 特性           | 本地脚本            | CI 脚本               |
| -------------- | ------------------- | --------------------- |
| 镜像源         | 国内（阿里云）      | 国外（Maven Central） |
| 环境变量       | ~/.bashrc           | GitHub Secrets        |
| 日志           | 详细彩色输出        | 结构化输出            |
| 清理           | 自动 trap           | 显式清理              |
| 失败处理       | 详细提示            | CI 友好               |
| 测试覆盖       | 19 个场景           | 19 个场景             |
| Docker Compose | 必需                | 必需                  |

## 为什么统一使用 Docker Compose？

### 优势

1. **一致性**: 本地和 CI 环境完全一致
2. **完整性**: 19 个测试场景 vs 旧 Maven 方式 8 个场景
3. **可维护性**: 单一测试架构，避免重复维护
4. **隔离性**: 每个测试在独立容器中运行
5. **可重复性**: Docker 镜像确保测试可重复

### 测试覆盖对比

| 测试类型       | Docker Compose | 旧 Maven 直接测试 |
| -------------- | -------------- | ----------------- |
| 基础加密       | ✅              | ✅                 |
| 密码验证       | ✅              | ✅                 |
| 多包加密       | ✅              | ✅                 |
| 排除类名       | ✅              | ✅                 |
| 无密码模式     | ✅              | ✅                 |
| Maven 插件     | ✅              | ✅                 |
| lib 依赖加密   | ✅              | ❌                 |
| 配置文件加密   | ✅              | ❌                 |
| 机器码绑定     | ✅              | ❌                 |
| WAR 包加密     | ✅              | ❌                 |
| 反编译保护验证 | ✅              | ❌                 |
| **总计**       | **19 场景**    | **8 场景**        |

## 多 JDK 版本兼容性

通过 **Unit Tests** 作业确保兼容性：

```yaml
unit-test:
  strategy:
    matrix:
      java: ["8", "11", "17"]
```

- 在 3 个 JDK 版本上运行单元测试
- 验证编译和核心功能兼容性
- 比完整集成测试更快，更适合多版本矩阵测试

## 相关文档

- [Docker 使用指南](02-docker-usage.md)
- [开发指南](03-development-guide.md)
- [Maven Central 部署](05-maven-central-deployment.md)
