# ClassFinal 架构设计文档

## 项目概述

ClassFinal 是一个 Java 类文件加密工具，通过 AES 加密算法保护 Java 应用的字节码，防止反编译。

- **原始项目**: [roseboy/classfinal](https://github.com/roseboy/classfinal)
- **维护分支**: [ygqygq2/classfinal](https://github.com/ygqygq2/classfinal)
- **维护者**: ygqygq2
- **版本**: 2.0.0
- **JDK 版本**: 1.8+
- **许可证**: Apache License 2.0

## 核心架构

### 模块划分

```
classfinal/
├── classfinal-core/           # 核心加密解密引擎
│   ├── AgentTransformer.java  # 字节码转换器
│   ├── CoreAgent.java         # JavaAgent 核心
│   ├── JarEncryptor.java      # JAR 加密器
│   ├── JarDecryptor.java      # JAR 解密器
│   └── util/                  # 工具类
│
├── classfinal-fatjar/         # 独立可执行 JAR
│   ├── Agent.java             # Agent 入口
│   └── Main.java              # 主程序入口
│
├── classfinal-maven-plugin/   # Maven 插件
│   └── ClassFinalPlugin.java # Maven 集成
│
├── classfinal-web/            # Web 控制台
│   ├── Application.java       # Spring Boot 应用
│   └── web/                   # Web 控制器
│
└── integration-test/          # 集成测试
    ├── test-app/              # 测试应用
    └── docker/                # Docker 测试环境
```

### 技术栈

- **核心依赖**: Javassist 3.30.2-GA（字节码操作）
- **加密算法**: AES-256
- **构建工具**: Apache Maven 3.8+
- **容器化**: Docker + Docker Compose
- **镜像仓库**: GitHub Container Registry (ghcr.io)

## 加密原理

### 加密流程

```
原始 JAR/WAR
    ↓
1. 扫描指定包名的 class 文件
    ↓
2. 提取方法体字节码
    ↓
3. 使用 AES + 密码加密方法体
    ↓
4. 清空原始方法体（保留方法签名、注解）
    ↓
5. 将加密数据存储在 JAR 内部
    ↓
6. 注入解密 Agent 代码
    ↓
加密后的 JAR/WAR
```

### 解密原理

```
启动 JVM with -javaagent:encrypted.jar
    ↓
1. Premain 方法执行
    ↓
2. 读取密码（环境变量/参数/控制台/GUI）
    ↓
3. 验证密码 Hash
    ↓
4. 注册 ClassFileTransformer
    ↓
5. ClassLoader 加载类时拦截
    ↓
6. 实时解密方法体字节码
    ↓
7. 注入解密后的方法体
    ↓
8. 返回完整的类字节码给 JVM
    ↓
内存中运行（不落盘）
```

### 密码管理

密码读取优先级（从高到低）：

1. **命令行参数**: `-pwd <password>`
2. **环境变量**: `-pwdname <env_var_name>`（指定环境变量名）
3. **密码文件**: `classfinal.txt` 或 `<jarname>.classfinal.txt`（读取后自动清空）
4. **控制台输入**: `console.readPassword()`
5. **GUI 输入**: Swing 输入框（支持 GUI 环境时）

密码验证：

- 加密时生成密码 MD5 + SALT 存储在 JAR 内部
- 运行时验证用户输入的密码 Hash 是否匹配

## Docker 架构

### 多阶段构建

```dockerfile
# 阶段 1: 构建
FROM maven:3.8-openjdk-8 AS builder
- 配置 Maven 镜像源（可选国内镜像）
- 复制源码
- mvn clean install

# 阶段 2: 运行时
FROM eclipse-temurin:8-jre-alpine
- 复制构建产物 (/app/app.jar)
- 复制启动脚本 (entrypoint.sh)
- 设置 ENTRYPOINT 和 CMD
```

### 容器运行模式

entrypoint.sh 支持多种模式：

1. **encrypt 模式**: 加密 JAR 文件
   - 环境变量: `INPUT_FILE`, `PACKAGES`, `PASSWORD`, `CODE`, `LIBJARS`, `EXCLUDE`, `CLASSPATH`, `CFGFILES`
2. **run 模式**: 运行未加密应用
   - 直接执行 `/app/app.jar`
3. **agent 模式**: 通过 JavaAgent 运行加密应用
   - 环境变量: `TARGET_JAR`, `PASSWORD`
   - 命令: `java -javaagent:/app/app.jar='-pwdname PASSWORD' -jar $TARGET_JAR`
4. **自定义模式**: 执行任意命令
   - 用于调试和特殊场景

### 集成测试架构

```yaml
services:
  prepare-test-app: # 复制测试应用到共享卷
    ↓
  encrypt-app: # 加密测试应用
    ↓
  test-encrypted-no-password: # 验证加密生效（应该失败）
  test-encrypted-with-password: # 验证 JavaAgent 解密（应该成功）
```

共享卷数据流：

```
test-app 镜像内的 /app/app.jar
    ↓ (prepare-test-app 复制)
共享卷 /data/app.jar (原始应用)
    ↓ (encrypt-app 加密)
共享卷 /data/app-encrypted.jar (加密应用)
    ↓ (test 服务使用)
验证加密效果
```

## 环境变量配置

### 构建时

| 变量               | 说明                      | 默认值 |
| ------------------ | ------------------------- | ------ |
| `USE_CHINA_MIRROR` | 是否使用国内 Maven 镜像源 | `true` |

### 运行时（加密模式）

| 变量         | 说明                           | 示例                   |
| ------------ | ------------------------------ | ---------------------- |
| `INPUT_FILE` | 要加密的 JAR/WAR 路径          | `/data/app.jar`        |
| `PACKAGES`   | 包名前缀（逗号分隔）           | `com.example,org.test` |
| `PASSWORD`   | 加密密码                       | `yourpassword`         |
| `CODE`       | 机器码绑定（可选）             | -                      |
| `LIBJARS`    | lib 目录下要加密的 JAR（可选） | -                      |
| `EXCLUDE`    | 排除的类名（可选）             | -                      |
| `CLASSPATH`  | 附加 classpath（可选）         | -                      |
| `CFGFILES`   | 配置文件（可选）               | -                      |

### 运行时（Agent 模式）

| 变量         | 说明             | 示例                      |
| ------------ | ---------------- | ------------------------- |
| `TARGET_JAR` | 要运行的加密 JAR | `/data/app-encrypted.jar` |
| `PASSWORD`   | 解密密码         | `yourpassword`            |

## 版本管理

### 动态版本

版本号从以下来源获取（优先级从高到低）：

1. **MANIFEST.MF**: `Implementation-Version`（Maven 自动写入）
2. **环境变量**: `CLASSFINAL_VERSION`
3. **默认值**: `"dev"`

配置：

```xml
<!-- classfinal-core/pom.xml -->
<plugin>
    <artifactId>maven-jar-plugin</artifactId>
    <configuration>
        <archive>
            <manifestEntries>
                <Implementation-Version>${project.version}</Implementation-Version>
            </manifestEntries>
        </archive>
    </configuration>
</plugin>
```

### Git 标签与版本

- 发布版本使用 Git tag: `v2.0.0`, `v2.1.0`, etc.
- CI/CD 自动从 tag 提取版本号设置 `CLASSFINAL_VERSION`
- 开发版本默认显示 `vdev`

## 安全设计

### 密码安全

1. **不明文存储**: 只存储 MD5(password + SALT)
2. **环境变量传递**: 避免命令行参数泄露到进程列表
3. **文件自动清空**: 密码文件读取后立即清空

### 运行时保护

1. **内存解密**: 字节码在内存中解密，不写入磁盘
2. **禁用 Attach**: 建议启动参数 `-XX:+DisableAttachMechanism`
3. **机器码绑定**: 可选绑定特定硬件（CODE 参数）

### 已知限制

1. **方法签名可见**: 保留方法签名和注解（兼容 Spring、Swagger 等框架）
2. **内存 dump 风险**: 内存中的解密字节码可能被 dump
3. **调试器风险**: 可通过调试器附加获取解密后的代码

## CI/CD 架构

### GitHub Actions 工作流

```yaml
构建触发 (push/pull_request)
    ↓
1. 检出代码
    ↓
2. 设置 JDK 8
    ↓
3. Maven 构建 (不使用国内镜像)
    ↓
4. Docker 构建 (多平台: linux/amd64, linux/arm64)
    ↓
5. 集成测试 (docker-compose)
    ↓
6. 推送镜像到 GHCR (tag 时)
    ↓
7. 发布 Release (tag 时)
```

### 镜像命名规范

- **ClassFinal 工具**: `ghcr.io/ygqygq2/classfinal/classfinal:2.0.0`
- **测试应用**: `ghcr.io/ygqygq2/classfinal/test-app:1.0.0`
- **Web 控制台**: `ghcr.io/ygqygq2/classfinal/web:2.0.0`

标签策略：

- `latest`: 最新稳定版本
- `x.y.z`: 具体版本号
- `dev`: 开发版本（主分支最新）

## Maven 插件使用

### 配置示例

```xml
<plugin>
    <groupId>io.github.ygqygq2</groupId>
    <artifactId>classfinal-maven-plugin</artifactId>
    <version>2.0.0</version>
    <configuration>
        <password>yourpassword</password>
        <packages>com.example</packages>
        <excludes>com.example.test</excludes>
        <code>machine-code</code>
        <libjars>lib1.jar,lib2.jar</libjars>
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

### 插件生命周期

```
mvn package
    ↓
package 阶段
    ↓
classFinal goal 执行
    ↓
1. 查找 target/*.jar
    ↓
2. 加密指定包
    ↓
3. 生成 *-encrypted.jar
    ↓
构建完成
```

## 性能考量

### 构建性能

- **国内镜像源**: 使用阿里云镜像可提升 5-10 倍下载速度
- **Maven 缓存**: Docker 多阶段构建复用 `.m2` 缓存
- **分层构建**: 依赖层与代码层分离，加快重复构建

### 运行时性能

- **首次加载慢**: 解密过程在类加载时进行，首次启动稍慢
- **后续无影响**: 类加载后缓存在 JVM 中，性能无差异
- **内存开销**: 轻微增加（Agent + 解密逻辑）

## 兼容性

### JDK 版本

- **编译**: JDK 1.8
- **运行**: JDK 1.8+
- **测试**: OpenJDK 8, Oracle JDK 8, Eclipse Temurin 8

### 框架兼容性

- ✅ Spring Boot / Spring Framework
- ✅ Swagger / OpenAPI
- ✅ MyBatis / Hibernate
- ✅ Tomcat / Jetty / Undertow
- ⚠️ GraalVM Native Image（不支持）
- ⚠️ Android（未测试）

### 容器平台

- ✅ Docker
- ✅ Kubernetes
- ✅ Docker Compose
- ✅ Podman
- ✅ OpenShift

## 扩展性

### 自定义加密算法

可通过修改 `EncryptUtils.java` 替换加密算法：

```java
public class EncryptUtils {
    // 替换为自定义算法
    public static byte[] encrypt(byte[] data, char[] password) {
        // 自定义实现
    }

    public static byte[] decrypt(byte[] data, char[] password) {
        // 自定义实现
    }
}
```

### 自定义转换器

实现 `ClassFileTransformer` 接口扩展功能：

```java
public class CustomTransformer implements ClassFileTransformer {
    @Override
    public byte[] transform(ClassLoader loader, String className,
                          Class<?> classBeingRedefined,
                          ProtectionDomain protectionDomain,
                          byte[] classfileBuffer) {
        // 自定义字节码转换逻辑
    }
}
```

## 故障排查

### 常见问题

1. **密码错误**: 检查环境变量、参数是否正确
2. **类加载失败**: 检查包名配置是否匹配
3. **Spring Bean 注入失败**: 确保注解未被加密（保留在方法签名中）
4. **MANIFEST 重复警告**: Maven Shade 插件配置问题，不影响功能

### 调试模式

启用调试日志：

```bash
java -javaagent:app.jar='-debug' -jar app.jar
```

查看加密详情：

```bash
unzip -p app-encrypted.jar META-INF/CLASSFINAL-INF/passhash
```

## 未来规划

### 短期（v2.x）

- [ ] 支持多密码（不同包使用不同密码）
- [ ] 性能优化（并行加密）
- [ ] 更多测试用例
- [ ] 完善文档和示例

### 长期（v3.x）

- [ ] 支持更多加密算法（SM4 等国密算法）
- [ ] Web UI 增强
- [ ] Gradle 插件
- [ ] IDE 插件（IDEA/Eclipse）
- [ ] 云端加密服务

## 贡献指南

详见 [03-development-guide.md](03-development-guide.md)

## 参考资料

- [Java Instrumentation API](https://docs.oracle.com/javase/8/docs/api/java/lang/instrument/package-summary.html)
- [Javassist Tutorial](https://www.javassist.org/tutorial/tutorial.html)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
