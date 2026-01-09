# ClassFinal

[![Maven Central](https://img.shields.io/badge/Maven%20Central-2.0.0-blue.svg)](https://search.maven.org/artifact/io.github.ygqygq2/classfinal)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-1.8+-orange.svg)](https://www.oracle.com/java/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://github.com/ygqygq2/classfinal/pkgs/container/classfinal%2Fclassfinal)

> Java class 文件安全加密工具 - 防止反编译，保护源码安全

## 介绍

ClassFinal 是一款 Java class 文件加密工具，支持直接加密 jar 包或 war 包，无需修改任何项目代码，完全兼容 Spring 框架。

- 🔒 **AES 加密**: 使用 AES 算法加密字节码
- 🚀 **零侵入**: 无需修改项目代码
- 🌱 **Spring 兼容**: 完全兼容 Spring Boot/Framework
- 🐳 **容器化**: 提供 Docker 镜像，开箱即用
- 🔑 **灵活解密**: 支持密码、环境变量、机器码绑定等多种方式

**项目链接**:
- GitHub: https://github.com/ygqygq2/classfinal
- 原项目: https://gitee.com/roseboy/classfinal

## 文档

- 📖 [架构设计文档](docs/01-architecture-design.md) - 详细的架构设计和技术原理
- �� [Docker 使用指南](docs/02-docker-usage.md) - Docker 容器化部署和使用
- 🛠️ [开发指南](docs/03-development-guide.md) - 开发环境配置和贡献指南
- 🧪 [集成测试文档](docs/04-integration-testing.md) - 集成测试环境和测试流程
- 📝 [更新日志](CHANGELOG.md) - 版本更新记录

## 快速开始

### 下载

**Maven 依赖**:
```xml
<dependency>
    <groupId>io.github.ygqygq2</groupId>
    <artifactId>classfinal-core</artifactId>
    <version>2.0.0</version>
</dependency>
```

**独立 JAR**:  
[GitHub Releases](https://github.com/ygqygq2/classfinal/releases)

**Docker 镜像**:
```bash
docker pull ghcr.io/ygqygq2/classfinal/classfinal:2.0.0
```

### 加密 JAR

```bash
java -jar classfinal-fatjar.jar \
  -file yourproject.jar \
  -packages com.yourpackage \
  -pwd yourpassword \
  -Y
```

**参数说明**:
- `-file`: 要加密的 jar/war 路径
- `-packages`: 要加密的包名（多个用逗号分隔）
- `-pwd`: 加密密码（使用 `#` 表示无密码模式）
- `-libjars`: lib 目录下要加密的 jar（可选）
- `-exclude`: 排除的类名（可选）
- `-code`: 机器码绑定（可选）
- `-Y`: 跳过确认提示

**结果**: 生成 `yourproject-encrypted.jar`

### 运行加密后的应用

```bash
java -javaagent:yourproject-encrypted.jar='-pwd yourpassword' \
  -jar yourproject-encrypted.jar
```

或使用环境变量:
```bash
java -javaagent:yourproject-encrypted.jar='-pwdname MY_PASSWORD' \
  -jar yourproject-encrypted.jar
```

### Docker 方式

**加密**:
```bash
docker run --rm \
  -v $(pwd):/data \
  -e INPUT_FILE=/data/app.jar \
  -e PACKAGES=com.example \
  -e PASSWORD=yourpassword \
  ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 encrypt
```

**运行**:
```bash
docker run --rm \
  -v $(pwd):/data \
  -e TARGET_JAR=/data/app-encrypted.jar \
  -e PASSWORD=yourpassword \
  ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 agent
```

详见 [Docker 使用指南](docs/02-docker-usage.md)

## Maven 插件

在 `pom.xml` 中添加插件配置：

```xml
<plugin>
    <groupId>io.github.ygqygq2</groupId>
    <artifactId>classfinal-maven-plugin</artifactId>
    <version>2.0.0</version>
    <configuration>
        <password>yourpassword</password>
        <packages>com.example</packages>
        <excludes>com.example.test</excludes>
        <libjars>a.jar,b.jar</libjars>
    </configuration>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>classFinal</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

运行 `mvn package` 后自动生成加密后的 jar。

## 高级功能

### 无密码模式

适用于不希望暴露密码的场景，加密时使用 `-pwd #`:

```bash
java -jar classfinal-fatjar.jar -file app.jar -packages com.example -pwd # -Y
```

运行时添加 `-nopwd` 参数:
```bash
java -javaagent:app-encrypted.jar='-nopwd' -jar app-encrypted.jar
```

### 机器码绑定

1. 在目标机器生成机器码:
```bash
java -jar classfinal-fatjar.jar -C
```

2. 加密时绑定机器码:
```bash
java -jar classfinal-fatjar.jar \
  -file app.jar \
  -packages com.example \
  -pwd yourpassword \
  -code your-machine-code \
  -Y
```

加密后的应用只能在该机器上运行。

### Tomcat 部署

修改 Tomcat 启动脚本:

**Linux (catalina.sh)**:
```bash
CATALINA_OPTS="$CATALINA_OPTS -javaagent:/path/to/classfinal-fatjar.jar='-pwd yourpassword'"
export CATALINA_OPTS
```

**Windows (catalina.bat)**:
```bat
set JAVA_OPTS="-javaagent:C:\path\to\classfinal-fatjar.jar='-pwd yourpassword'"
```

## 安全建议

- 🔐 **保护密码**: 使用环境变量而非命令行参数传递密码
- 🚫 **禁用附加**: 添加 JVM 参数 `-XX:+DisableAttachMechanism`
- 💾 **备份**: 妥善保管加密密码，忘记密码将无法恢复
- 🔒 **机器绑定**: 重要应用建议使用机器码绑定

## 技术原理

1. **加密阶段**: 
   - 清空方法体（保留签名和注解）
   - 使用 AES 加密原始字节码
   - 将加密数据存储在 JAR 内部

2. **运行阶段**:
   - JavaAgent 在类加载时拦截
   - 实时解密方法体字节码
   - 注入完整方法到 JVM
   - 完全内存操作，不落盘

详见 [架构设计文档](docs/01-architecture-design.md)

## 兼容性

### 框架
- ✅ Spring Boot / Spring Framework
- ✅ MyBatis / Hibernate / JPA
- ✅ Tomcat / Jetty / Undertow
- ✅ Swagger / OpenAPI

### JDK
- ✅ JDK 8, 11, 17, 21
- ⚠️ GraalVM Native Image（不支持）

### 容器
- ✅ Docker / Kubernetes
- ✅ Docker Compose
- ✅ Podman / OpenShift

## 常见问题

**Q: 会影响性能吗？**  
A: 仅首次类加载时解密，后续无性能影响。

**Q: 能完全防止反编译吗？**  
A: 增加反编译难度，但内存 dump 仍可能获取解密后的代码。

**Q: 密码忘记了怎么办？**  
A: 无法恢复，请务必备份密码。

**Q: 支持哪些加密算法？**  
A: 当前使用 AES-256，可扩展支持其他算法。

更多问题见 [Issues](https://github.com/ygqygq2/classfinal/issues)

## 版本历史

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细更新记录。

## 贡献

欢迎提交 Issue 和 Pull Request！

详见 [开发指南](docs/03-development-guide.md)

## 协议

本项目采用 [Apache License 2.0](LICENSE) 开源协议。

## 致谢

- 原作者 [@roseboy](https://gitee.com/roseboy) 创建了这个优秀的项目
- 所有贡献者的支持和反馈

---

**维护者**: [@ygqygq2](https://github.com/ygqygy2)  
**Star ⭐ 支持**: 如果这个项目对你有帮助，请给个 Star！
