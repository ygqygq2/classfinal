# Docker 使用说明

## 快速开始

### 1. 构建镜像

```bash
# 本地开发（使用国内镜像源加速）
docker-compose build

# CI 环境（不使用国内镜像源）
USE_CHINA_MIRROR=false docker-compose build
```

### 2. 运行模式

ClassFinal 镜像支持多种运行模式：

#### 加密模式

```bash
docker run --rm \
  -v $(pwd)/target:/data \
  -e INPUT_FILE=/data/app.jar \
  -e PACKAGES=com.example \
  -e PASSWORD=mypassword \
  ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 encrypt
```

#### JavaAgent 模式（运行加密的应用）

```bash
docker run --rm \
  -v $(pwd)/target:/data \
  -e TARGET_JAR=/data/app-encrypted.jar \
  -e PASSWORD=mypassword \
  ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 agent
```

#### 普通运行模式

```bash
docker run --rm ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 run --help
```

#### 自定义命令（调试模式）

```bash
# 进入容器 shell
docker run --rm -it ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 /bin/sh

# 执行自定义命令
docker run --rm ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 ls -la /app
```

### 3. 集成测试

```bash
# 运行完整的集成测试套件
docker-compose up --abort-on-container-exit

# 单独运行某个测试
docker-compose up test-original
docker-compose up test-encrypted-no-password
docker-compose up test-encrypted-with-password
```

## 环境变量

| 变量名             | 说明                     | 默认值                        | 示例                   |
| ------------------ | ------------------------ | ----------------------------- | ---------------------- |
| `USE_CHINA_MIRROR` | 构建时是否使用国内镜像源 | `true`                        | `false`                |
| `PASSWORD`         | 加密/解密密码            | -                             | `mypassword`           |
| `PACKAGES`         | 要加密的包名（逗号分隔） | -                             | `com.example,org.test` |
| `INPUT_FILE`       | 输入文件路径             | -                             | `/data/app.jar`        |
| `OUTPUT_FILE`      | 输出文件路径             | `${INPUT_FILE}-encrypted.jar` | `/data/app-enc.jar`    |
| `TARGET_JAR`       | JavaAgent 模式的目标 JAR | -                             | `/data/app.jar`        |

## 镜像特点

- **多阶段构建**：分离构建和运行环境，最终镜像更小
- **统一入口**：所有应用使用 `/app/app.jar` 统一路径
- **灵活配置**：通过环境变量控制行为
- **多种模式**：支持加密、运行、JavaAgent、自定义命令
- **国内加速**：本地开发自动使用阿里云 Maven 镜像源
