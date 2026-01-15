# ClassFinal Docker Compose 集成测试文档

## 快速开始

### 运行完整测试套件

```bash
# 运行所有测试
bash integration-test/run-tests.sh

# 或者逐步运行
docker-compose run --rm classfinal-builder        # 构建 ClassFinal
docker-compose run --rm test-app-builder          # 构建测试应用
docker-compose run --rm test-original-app         # 测试原始应用
docker-compose run --rm classfinal-encryptor      # 加密应用
docker-compose run --rm test-encrypted-with-password  # 测试加密应用
```

### 清理环境

```bash
docker-compose down -v
```

## 测试架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Compose 测试流程                   │
└─────────────────────────────────────────────────────────────┘

1. classfinal-builder
   ↓ 编译 ClassFinal 项目
   └── 生成 classfinal-fatjar.jar

2. test-app-builder
   ↓ 编译测试应用
   └── 生成 classfinal-test-app.jar

3. test-original-app
   ↓ 运行原始应用（baseline）
   └── 验证应用功能正常

4. classfinal-encryptor
   ↓ 使用 ClassFinal 加密测试应用
   └── 生成 classfinal-test-app-encrypted.jar

5. test-encrypted-no-password
   ↓ 尝试无密码运行加密应用
   └── 验证需要密码保护

6. test-encrypted-with-password
   ↓ 使用正确密码运行加密应用
   └── 验证解密和运行成功
```

## 服务说明

### classfinal-builder

- **镜像**: maven:3.8-openjdk-8
- **功能**: 编译 ClassFinal 主项目
- **输出**: `classfinal-fatjar/target/classfinal-fatjar-*.jar`

### test-app-builder

- **镜像**: maven:3.8-openjdk-8
- **功能**: 编译测试应用程序
- **输出**: `integration-test/classfinal-test-app-*.jar`

### classfinal-encryptor

- **镜像**: openjdk:8-jre-slim
- **功能**: 使用 ClassFinal 加密测试应用
- **参数**:
  - `-file`: 要加密的 jar 文件
  - `-packages`: io.github.ygqygq2.test
  - `-pwd`: test123
  - `-Y`: 自动确认

### test-encrypted-with-password

- **镜像**: openjdk:8-jre-slim
- **功能**: 使用 javaagent 和密码运行加密应用
- **命令**: `java -javaagent:classfinal-fatjar.jar -jar app-encrypted.jar`
- **密码**: test123（通过 stdin 输入）

## GitHub Actions 集成

CI/CD 管道自动运行:

- ✅ JDK 8/11/17 多版本单元测试
- ✅ Docker Compose 完整集成测试
- ✅ 构建产物上传
- ✅ Maven Central 发布（tag 触发）

查看 `.github/workflows/ci.yml` 了解详情。

## 故障排查

### Maven 依赖下载慢

```bash
# 使用国内镜像（可选）
# 修改 docker-compose.yml 添加阿里云镜像配置
```

### 端口冲突

```bash
# 清理所有容器
docker-compose down -v
docker system prune -f
```

### 查看容器日志

```bash
docker-compose logs classfinal-builder
docker-compose logs test-encrypted-with-password
```

### 手动进入容器调试

```bash
docker-compose run --rm --entrypoint bash classfinal-builder
```

## 本地开发

如果需要本地修改代码并测试:

```bash
# 1. 修改代码
vim classfinal-core/src/main/java/...

# 2. 重新构建并测试
docker-compose run --rm classfinal-builder
docker-compose run --rm classfinal-encryptor

# 3. 清理
docker-compose down
```

## 性能优化

使用 Maven 缓存卷加速构建:

```yaml
volumes:
  maven-cache:
    driver: local
```

缓存位置: Docker volume `classfinal_maven-cache`

清理缓存:

```bash
docker volume rm classfinal_maven-cache
```
