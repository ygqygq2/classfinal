# CI 和本地测试兼容性检查清单

## 概述

本文档确保所有CI和本地测试脚本、代码配置保持一致，避免"改了这忘了那"的问题。

## ✅ 已完成的统一修改

### 1. 环境变量名称统一

所有配置已从 `OSSRH_*` 改为 `SONATYPE_*`：

- ✅ `.github/workflows/ci.yml` - 使用 SONATYPE_USERNAME/PASSWORD
- ✅ `.github/workflows/deploy.yml` - 使用 SONATYPE_USERNAME/PASSWORD  
- ✅ `docker-compose.yml` - 使用 SONATYPE_USERNAME/PASSWORD
- ✅ `integration-test/run-local-tests.sh` - 检查和使用 SONATYPE_*
- ✅ `integration-test/run-ci-tests.sh` - 纯 Docker 测试，不依赖凭证
- ✅ `~/.bashrc` - 本地环境变量已更名

### 2. 测试应用 POM 配置统一

所有6个测试应用都已统一使用动态 `java.version` 配置：

| 测试应用 | POM 文件路径 | 状态 |
|---------|-------------|------|
| test-app | `integration-test/test-app/pom.xml` | ✅ 已更新 |
| basic | `integration-test/test-apps/basic/pom.xml` | ✅ 已更新 |
| config-file | `integration-test/test-apps/config-file/pom.xml` | ✅ 已更新 |
| libjars | `integration-test/test-apps/libjars/pom.xml` | ✅ 已更新 |
| maven-plugin | `integration-test/test-apps/maven-plugin/pom.xml` | ✅ 已更新 |
| war | `integration-test/test-apps/war/pom.xml` | ✅ 已更新 |

**统一配置内容：**

```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  <!-- 动态编译版本：默认 JDK 8，可通过 -Djava.version=11 指定 -->
  <java.version>8</java.version>
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

### 3. Docker 镜像名称统一

- ✅ 所有 ClassFinal 镜像：`ghcr.io/ygqygq2/classfinal/classfinal:2.0.0`
- ✅ 所有 JDK 17 运行时：`eclipse-temurin:17-jre`（替换不存在的 openjdk:17-jre-slim）

### 4. CI 测试 JAR 文件命名统一

- ✅ artifactId: `classfinal-test-app`（不是 classfinal-test-basic）
- ✅ 编译后 JAR: `classfinal-test-app-*.jar`
- ✅ 加密后 JAR: `classfinal-test-app-*-encrypted.jar`
- ✅ JAR 匹配时排除源码包：`grep -v sources`

## 测试策略对比

### CI 测试（GitHub Actions）

#### Docker Compose 测试（单次运行）
- **文件**: `.github/workflows/ci.yml` - `integration-test` job
- **脚本**: `integration-test/run-ci-tests.sh`
- **JDK 版本**: JDK 17（固定）
- **运行次数**: 1次
- **测试内容**: 
  - 基础加密测试
  - 密码验证测试
  - 配置文件加密
  - lib 依赖加密
  - Maven 插件测试
  - WAR 包加密
- **编译方式**: Docker 镜像内部编译（默认 JDK 8）

#### Maven 矩阵测试（多版本）
- **文件**: `.github/workflows/ci.yml` - `integration-test-maven` job
- **JDK 版本**: [8, 11, 17] 矩阵
- **运行次数**: 3次（每个 JDK 版本1次）
- **测试内容**:
  - 编译测试应用：`mvn clean package -Djava.version=${{ matrix.java }}`
  - 加密编译后的字节码
  - 验证加密应用运行
  - 测试密码验证（正确/错误密码）
- **编译方式**: Maven 动态编译（-Djava.version 参数）

### 本地测试

- **文件**: `integration-test/run-local-tests.sh`
- **依赖**: 
  - Docker & docker-compose
  - SONATYPE_USERNAME（可选）
  - SONATYPE_PASSWORD（可选）
- **镜像加速**: 使用国内镜像源
- **测试范围**: 完整集成测试（所有场景）
- **编译方式**: Docker Compose（默认 JDK 8）

## 关键配置文件清单

### 需要保持一致的配置

| 配置项 | CI | 本地测试 | Docker Compose |
|-------|-----|---------|---------------|
| 环境变量前缀 | SONATYPE_* | SONATYPE_* | SONATYPE_* |
| ClassFinal 镜像 | ghcr.io/... | ghcr.io/... | ghcr.io/... |
| JDK 17 镜像 | eclipse-temurin | eclipse-temurin | eclipse-temurin |
| artifactId | classfinal-test-app | classfinal-test-app | classfinal-test-app |
| 测试应用 java.version | 8（默认）可覆盖 | 8（默认） | 8（默认） |
| maven-compiler-plugin | 3.11.0 | 3.11.0 | 3.11.0 |

## 使用方法

### CI 环境（自动运行）
```bash
# Docker Compose 测试 - 由 GitHub Actions 自动调用
bash integration-test/run-ci-tests.sh

# Maven 多版本测试 - 在 GitHub Actions 矩阵中运行
mvn clean install -DskipTests -Dgpg.skip=true -Dmaven.javadoc.skip=true
cd integration-test/test-apps/basic
mvn clean package -Djava.version=8  # 或 11, 17
```

### 本地环境
```bash
# 设置环境变量（可选）
export SONATYPE_USERNAME=your_username
export SONATYPE_PASSWORD=your_password

# 运行本地测试
bash integration-test/run-local-tests.sh
```

### 手动测试不同 JDK 版本
```bash
# 编译为 JDK 8 字节码（默认）
cd integration-test/test-apps/basic
mvn clean package

# 编译为 JDK 11 字节码
mvn clean package -Djava.version=11

# 编译为 JDK 17 字节码
mvn clean package -Djava.version=17
```

## 验证清单

新增或修改配置时，请检查以下项目：

- [ ] 所有测试应用 POM 使用统一的 java.version 配置
- [ ] CI workflow 和本地脚本使用相同的环境变量名
- [ ] Docker 镜像名称在所有配置文件中一致
- [ ] JAR 文件命名在所有脚本中一致
- [ ] 新增测试应用已添加到 CI 矩阵测试中
- [ ] 文档更新反映配置变化

## 常见问题

### Q1: 为什么要动态 java.version？
A: 允许 ClassFinal（JDK 8 编译）测试不同 JDK 版本编译的应用，验证多版本字节码兼容性。

### Q2: CI 和本地测试有何区别？
A: 
- CI 使用国外镜像源，本地可用国内加速
- CI 运行 Maven 矩阵测试（3个JDK版本），本地只测 JDK 8
- CI 自动化，本地需要手动触发

### Q3: SONATYPE_* vs OSSRH_* 有何区别？
A: 
- SONATYPE_* 是 Maven Central Portal 新系统的标准命名
- OSSRH_* 是旧的 Nexus OSSRH 系统命名
- 项目已全部迁移到 SONATYPE_* 命名

### Q4: 为什么有两个测试 job？
A:
- integration-test: Docker Compose 完整功能测试（1次）
- integration-test-maven: Maven 多版本编译测试（3次）
- 前者验证功能，后者验证多版本兼容性

## 最后更新

- **日期**: 2026-01-10
- **修改内容**: 
  - 统一所有测试应用使用动态 java.version
  - 环境变量从 OSSRH_* 改为 SONATYPE_*
  - 修复 JAR 文件命名（classfinal-test-app）
  - Docker 镜像统一（ghcr.io + eclipse-temurin）
