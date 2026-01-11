# ClassFinal Web UI

基于 Spring Boot 的 Web 图形界面，提供友好的 ClassFinal 加密工具操作体验。

## 快速启动

### 使用 Docker Compose（推荐）

```bash
# 在 classfinal-web 目录下
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止
docker-compose down
```

访问：http://localhost:59999

### 本地运行

```bash
# 先构建并安装父项目依赖
cd ..
mvn clean install -DskipTests -Dgpg.skip=true

# 运行 Web UI
cd classfinal-web
mvn spring-boot:run
```

## 功能特性

- 📦 Web 界面上传 JAR/WAR 包
- ⚙️ 可视化配置加密参数
- 🔐 分步引导加密流程
- 📥 加密完成后下载结果

## 端口

- Web UI: 59999

## 环境变量

- `USE_CHINA_MIRROR`: 是否使用国内 Maven 镜像源（默认 true）
- `JAVA_OPTS`: JVM 参数（默认 -Xmx512m）

## 技术栈

- Spring Boot 2.0.3
- Freemarker 模板引擎
- ClassFinal Core 2.0.0-SNAPSHOT
