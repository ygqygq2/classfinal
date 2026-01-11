# JDK 版本兼容性指南

## 概述

ClassFinal 支持 JDK 8 到 JDK 21+，但不同使用场景需要注意不同的配置。

## 支持的 JDK 版本

- ✅ **JDK 8** - 最低支持版本
- ✅ **JDK 11** - LTS 版本
- ✅ **JDK 17** - 推荐 LTS 版本
- ✅ **JDK 21** - 最新 LTS 版本
- ✅ **JDK 23+** - 最新版本

## 使用场景

### 1. ClassFinal 工具本身

ClassFinal 编译目标为 **JDK 8**，确保最大兼容性：

```xml
<maven.compiler.source>1.8</maven.compiler.source>
<maven.compiler.target>1.8</maven.compiler.target>
```

**运行环境要求**：
- 最低：JDK 8+
- 推荐：JDK 11 或 JDK 17

### 2. 您的应用程序（动态适配）

测试应用使用**动态编译版本**，根据您使用的 JDK 自动适配。

#### 2.1 默认行为（推荐）

不指定版本时，使用当前 JDK 版本编译：

```bash
# 使用 JDK 11
export JAVA_HOME=/path/to/jdk-11
mvn clean package

# 使用 JDK 17  
export JAVA_HOME=/path/to/jdk-17
mvn clean package
```

#### 2.2 显式指定版本

通过 Maven 属性指定编译版本：

```bash
# 在 JDK 17 环境编译成 JDK 11 字节码
mvn clean package -Djava.version=11

# 在 JDK 21 环境编译成 JDK 17 字节码
mvn clean package -Djava.version=17
```

#### 2.3 POM 配置

在您的 `pom.xml` 中：

```xml
<properties>
    <!-- 方式 1: 使用系统 JDK 版本（推荐） -->
    <java.version>${java.version}</java.version>
    
    <!-- 方式 2: 固定版本 -->
    <!-- <java.version>11</java.version> -->
</properties>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
            <configuration>
                <release>${java.version}</release>
            </configuration>
        </plugin>
    </plugins>
</build>
```

## Docker 环境

### 官方镜像选择

不同 JDK 版本使用不同的官方镜像：

```dockerfile
# JDK 8
FROM openjdk:8-jre-slim

# JDK 11  
FROM openjdk:11-jre-slim

# JDK 17+（推荐 Eclipse Temurin）
FROM eclipse-temurin:17-jre
FROM eclipse-temurin:21-jre

# 或使用 Amazon Corretto
FROM amazoncorretto:17
FROM amazoncorretto:21
```

**注意**：从 JDK 17 开始，官方不再提供 `openjdk:17-jre-slim`，请使用：
- `eclipse-temurin` （推荐）
- `amazoncorretto`
- `microsoft/openjdk`

## 常见问题

### Q1: 我的应用用 JDK 17 编译，ClassFinal 能处理吗？

✅ 可以。ClassFinal 工具虽然用 JDK 8 编译，但能正确处理 JDK 8-21 所有版本的字节码。

### Q2: 如何选择 JDK 版本？

**个人推荐**：
- **新项目**：JDK 17（当前主流 LTS）
- **老项目**：保持现有版本，无需降级
- **库/工具**：JDK 8（最大兼容性）

### Q3: Maven 报错 "invalid target release"

确保您的 **Maven Compiler Plugin 版本 >= 3.6**，并且编译版本不高于当前 JDK：

```bash
# 错误示例：在 JDK 11 环境编译 JDK 17 字节码
mvn clean package -Djava.version=17  # ❌ 会失败

# 正确做法：使用 JDK 17 环境
export JAVA_HOME=/path/to/jdk-17
mvn clean package -Djava.version=17  # ✅ 成功
```

### Q4: CI/CD 环境如何配置？

**GitHub Actions 示例**：

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        java: [8, 11, 17, 21]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up JDK ${{ matrix.java }}
        uses: actions/setup-java@v4
        with:
          java-version: ${{ matrix.java }}
          distribution: 'temurin'
      
      - name: Build with JDK ${{ matrix.java }}
        run: mvn clean package -Djava.version=${{ matrix.java }}
```

## 版本选择建议

| 场景 | 推荐 JDK | 理由 |
|------|----------|------|
| 开源库/工具 | 8 | 最大用户覆盖 |
| 企业应用（新） | 17 | 当前主流 LTS，性能好 |
| 企业应用（维护） | 11 | 稳定的 LTS，广泛使用 |
| 云原生应用 | 17/21 | 新特性，更好的容器支持 |
| 学习/实验 | 21+ | 体验最新特性 |

## 参考资料

- [Oracle JDK 发布路线图](https://www.oracle.com/java/technologies/java-se-support-roadmap.html)
- [Eclipse Temurin](https://adoptium.net/)
- [Maven Compiler Plugin](https://maven.apache.org/plugins/maven-compiler-plugin/)
