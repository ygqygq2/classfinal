# ClassFinal 完整测试覆盖文档

## 概述

本文档详细说明 ClassFinal 项目的完整集成测试套件，共包含 **19 个测试场景**，覆盖所有核心功能。

## 测试场景列表

### 基础加密流程 (Steps 1-7)

#### Step 1: 构建 ClassFinal

- **目的**: 构建 ClassFinal 工具本身
- **验证**: classfinal.jar 成功生成

#### Step 2: 构建测试应用

- **目的**: 构建用于测试的 Java 应用
- **验证**: 测试应用 JAR 成功生成

#### Step 3: 运行原始应用

- **目的**: 验证原始应用可正常运行
- **验证**: 应用输出正确

#### Step 4: 加密应用

- **目的**: 使用 ClassFinal 加密测试应用
- **参数**: `-file app.jar -packages io.github.ygqygq2.test -pwd test123`
- **验证**: 生成 app-encrypted.jar

#### Step 5: 测试无密码运行失败

- **目的**: 验证加密应用需要密码
- **验证**: 应用运行失败，提示需要密码

#### Step 6: 测试正确密码运行

- **目的**: 验证正确密码可以运行
- **参数**: `-javaagent:app-encrypted.jar='-pwd test123'` 或 `-javaagent:app-encrypted.jar=-pwd=test123`
- **验证**: 应用成功运行

#### Step 7: 测试错误密码被拒绝

- **目的**: 验证错误密码无法运行
- **参数**: `-javaagent:app-encrypted.jar='-pwd wrong123'` 或 `-javaagent:app-encrypted.jar=-pwd=wrong123`
- **验证**: 应用运行失败

### 多包加密 (Steps 8-11)

#### Step 8-11: 多包加密测试

- **目的**: 测试同时加密多个包
- **参数**: `-packages io.github.ygqygq2.test,io.github.ygqygq2.util`
- **验证**:
  - 多个包的类都被加密
  - 加密后应用可正常运行

### 高级功能测试 (Steps 12-19)

#### Step 12: 排除类名功能

- **目的**: 测试 `-exclude` 参数
- **参数**: `-exclude io.github.ygqygq2.test.ExcludeMe`
- **验证**:
  - 指定的类未被加密
  - 其他类正常加密

#### Step 13: 无密码模式

- **目的**: 测试无密码加密模式
- **参数**: `-nopwd`
- **验证**:
  - 使用 `-nopwd` 参数可运行
  - 无需指定密码

#### Step 14: Maven 插件集成

- **目的**: 测试 classfinal-maven-plugin
- **配置**: 在 pom.xml 中配置插件
- **验证**:
  - Maven 构建时自动加密
  - 生成 \*-encrypted.jar 文件

#### Step 15: lib 依赖加密

- **目的**: 测试外部依赖库加密
- **参数**: `-libjars lib/gson-2.10.1.jar`
- **验证**:
  - lib 目录中的 JAR 被加密
  - 加密后的依赖可正常加载
  - 应用使用加密的 gson 库运行正常

#### Step 16: 配置文件加密

- **目的**: 测试配置文件加密保护
- **场景**: 加密 database.properties 配置文件
- **验证**:
  - 配置文件内容被加密
  - 无法直接读取明文密码
  - 应用可正常读取配置

#### Step 17: 机器码绑定

- **目的**: 测试机器码绑定功能
- **步骤**:
  1. 生成机器码: `java -jar classfinal.jar -C`
  2. 绑定加密: `-code <machine-code>`
- **验证**:
  - 机器码成功生成
  - 加密时正确绑定机器码
  - 加密后的 JAR 文件存在
- **注意**: Docker 容器环境下，每个容器的机器码不同，因此只验证加密过程，不验证运行（运行验证需要在物理机或同一容器内完成）

#### Step 18: WAR 包加密

- **目的**: 测试 WAR 包加密
- **参数**: `-file app.war -packages io.github.ygqygq2.test`
- **验证**:
  - WAR 包中的 class 文件被加密
  - WEB-INF/classes 下的类无法直接读取

#### Step 19: 反编译保护验证

- **目的**: 验证反编译保护有效性
- **工具**: CFR 反编译器 (v0.152)
- **步骤**:
  1. 反编译原始 JAR (成功)
  2. 反编译加密 JAR (失败或乱码)
- **验证**:
  - 原始代码可清晰反编译
  - 加密后代码不可读或反编译失败

## 测试架构

### Docker Compose 服务

共 32 个 Docker 服务:

1. **构建服务** (2 个)

   - `build-classfinal`: 构建 ClassFinal 工具
   - `build-test-app`: 构建测试应用

2. **准备服务** (8 个)

   - `prepare-exclude-test`: 排除类名测试准备
   - `prepare-nopwd-test`: 无密码模式测试准备
   - `prepare-libjars-test`: lib 依赖测试准备
   - `prepare-config-encryption`: 配置文件加密测试准备
   - `prepare-machine-code`: 机器码生成
   - `prepare-war-test`: WAR 包测试准备
   - `prepare-decompile-test`: 反编译测试准备

3. **加密服务** (11 个)

   - `encrypt`: 基础加密
   - `encrypt-multipackage`: 多包加密
   - `encrypt-with-exclude`: 排除类名加密
   - `encrypt-nopwd`: 无密码加密
   - `encrypt-with-libjars`: lib 依赖加密
   - `encrypt-config-files`: 配置文件加密
   - `encrypt-with-machine-code`: 机器码绑定加密
   - `encrypt-war`: WAR 包加密

4. **测试服务** (11 个)
   - `test-original`: 原始应用测试
   - `test-without-password`: 无密码运行测试
   - `test-with-correct-password`: 正确密码测试
   - `test-with-wrong-password`: 错误密码测试
   - `test-multipackage-encrypted`: 多包加密测试
   - `test-encrypted-with-exclude`: 排除类名测试
   - `test-encrypted-nopwd`: 无密码模式测试
   - `test-maven-plugin`: Maven 插件测试
   - `test-libjars-encrypted`: lib 依赖加密测试
   - `test-config-encrypted`: 配置文件加密测试
   - `test-machine-code-correct`: 机器码绑定测试
   - `test-war-encrypted`: WAR 包加密测试

### 测试脚本

#### 本地测试脚本

- **文件**: `integration-test/run-local-tests.sh`
- **特点**:
  - 使用中国镜像加速 (`USE_CHINA_MIRROR=true`)
  - 适合本地开发测试
  - 跳过 Maven 部署测试

#### CI 测试脚本

- **文件**: `integration-test/run-ci-tests.sh`
- **特点**:
  - 不使用镜像 (`USE_CHINA_MIRROR=false`)
  - 适合 GitHub Actions CI
  - 英文日志输出

## 测试覆盖矩阵

| 功能         | 参数                         | 测试步骤 | 状态 |
| ------------ | ---------------------------- | -------- | ---- |
| 基础加密     | `-file`, `-packages`, `-pwd` | 1-7      | ✅   |
| 多包加密     | `-packages` (多个)           | 8-11     | ✅   |
| 排除类名     | `-exclude`                   | 12       | ✅   |
| 无密码模式   | `-nopwd`                     | 13       | ✅   |
| Maven 插件   | pom.xml 配置                 | 14       | ✅   |
| lib 依赖加密 | `-libjars`                   | 15       | ✅   |
| 配置文件加密 | (资源文件)                   | 16       | ✅   |
| 机器码绑定   | `-C`, `-code`                | 17       | ✅   |
| WAR 包加密   | `-file *.war`                | 18       | ✅   |
| 反编译保护   | (验证)                       | 19       | ✅   |

## 运行测试

### 本地测试

```bash
cd /data/git/ygqygq2/classfinal
bash integration-test/run-local-tests.sh
```

### CI 测试

```bash
cd /data/git/ygqygq2/classfinal
bash integration-test/run-ci-tests.sh
```

### 单个场景测试

```bash
# 设置环境变量
export USE_CHINA_MIRROR=true

# 运行特定测试
docker-compose run --rm test-libjars-encrypted
docker-compose run --rm prepare-decompile-test
```

## 测试报告示例

```
========================================
Step 1: 构建 ClassFinal
========================================
✓ ClassFinal build successful

========================================
Step 2: 构建测试应用
========================================
✓ Test app build successful

...

========================================
Step 19: 反编译保护验证测试
========================================
=== 准备反编译保护测试 ===
测试原始 jar 反编译...
✓ 原始 jar 可以反编译
测试加密 jar 反编译...
=== 原始反编译内容 ===
public class Main {
    public static void main(String[] args) {
        ...
    }
}
=== 加密后反编译内容 ===
(无法反编译或内容不可读)
✓ 反编译保护有效
✓ Step 19: 反编译保护验证测试成功

========================================
✓ 所有 19 个测试场景全部通过！
========================================
```

## 技术细节

### 测试应用变体

为了测试不同场景，测试应用有多个变体:

1. **基础应用**: 单一 JAR，包含 Main 类
2. **多包应用**: 包含多个包的 JAR
3. **lib 依赖应用**: 使用 gson 等外部库
4. **配置文件应用**: 读取 database.properties
5. **WAR 应用**: Web 应用，包含 Servlet

### 验证方法

不同测试使用不同的验证方法:

- **基础功能**: 检查退出码和输出
- **加密验证**: 尝试直接读取 class 文件(应失败)
- **配置加密**: 使用 `unzip -p` 检查配置文件内容
- **反编译**: 使用 CFR 工具对比反编译结果
- **WAR 包**: 使用 `file` 命令检查 class 文件类型

## 性能指标

- **总测试时间**: 约 10-15 分钟(本地)
- **Docker 镜像大小**:
  - classfinal: ~500MB
  - test-app-builder: ~800MB
- **缓存优化**:
  - Maven 本地仓库缓存
  - Docker 层缓存

## 持续改进

### 计划中的测试

- ☐ 不同机器上的机器码绑定失败测试
- ☐ 大型应用性能测试
- ☐ 多线程并发加载测试
- ☐ Spring Boot 应用集成测试

### 已知限制

1. **机器码测试**: 当前只测试成功场景，未模拟不同机器失败场景
2. **WAR 部署**: 未实际部署到 Tomcat 等容器测试运行
3. **反编译工具**: 只测试了 CFR，可增加 JD-CLI、Procyon 等

## 贡献指南

添加新测试场景时:

1. 在 `docker-compose.yml` 中添加服务定义
2. 更新 `run-local-tests.sh` 和 `run-ci-tests.sh`
3. 添加对应的验证逻辑
4. 更新本文档的测试列表
5. 提交 PR 时包含测试结果截图

## 参考资料

- [ClassFinal README](../README.md)
- [Docker 使用指南](02-docker-usage.md)
- [集成测试指南](07-integration-testing-guide.md)
- [开发指南](03-development-guide.md)
