# ClassFinal 2.0.1 新功能文档

## 配置文件支持

### 功能简介

2.0.1 版本新增配置文件支持,允许通过 YAML 文件管理加密参数,避免在命令行暴露敏感信息。

### 使用方法

#### 1. 生成配置文件模板

```bash
java -jar classfinal-2.0.1.jar --init-config classfinal.yml
```

#### 2. 编辑配置文件

```yaml
# ClassFinal 配置文件
input:
  file: app.jar
  packages:
    - com.example
    - com.demo
  exclude:
    - com.example.test
  libjars:
    - lib-a.jar

encryption:
  password: ${CLASSFINAL_PASSWORD}  # 从环境变量读取
  mode: password                     # password | machine
  # passwordFile: /tmp/password.txt  # 或从文件读取
  # deletePasswordFile: true         # 读取后自动删除

output:
  file: app-encrypted.jar
  overwrite: false

advanced:
  logLevel: INFO                     # DEBUG | INFO | WARN | ERROR
  skipConfirmation: false
  threads: 1
  incremental: false
  cacheFile: .classfinal-cache
```

#### 3. 使用配置文件加密

```bash
# 设置环境变量
export CLASSFINAL_PASSWORD="your-secure-password"

# 使用配置文件
java -jar classfinal-2.0.1.jar --config classfinal.yml
```

### 环境变量支持

配置文件中可以使用 `${VAR_NAME}` 引用环境变量:

```yaml
encryption:
  password: ${CLASSFINAL_PASSWORD}
  machineCode: ${MACHINE_CODE}
```

如果环境变量不存在,占位符保持原样。

---

## 密码管理

### 从文件读取密码

#### 命令行方式

```bash
# 创建密码文件
echo "your-secure-password" > /tmp/password.txt

# 使用密码文件(读取后自动删除)
java -jar classfinal-2.0.1.jar \
  -file app.jar \
  --password-file /tmp/password.txt
```

#### 配置文件方式

```yaml
encryption:
  passwordFile: /tmp/password.txt
  deletePasswordFile: true  # 读取后自动删除
```

### 从环境变量读取

```bash
# 设置环境变量
export CLASSFINAL_PASSWORD="your-secure-password"

# 在配置文件中引用
# encryption:
#   password: ${CLASSFINAL_PASSWORD}
```

### 密码强度检查

系统会自动检查密码强度并给出警告:

- **弱密码** (少于 6 位或纯数字/字母): 不建议使用
- **中等密码** (8+ 位,字母+数字): 可以使用
- **强密码** (10+ 位,大小写+数字+特殊字符): 推荐使用

```bash
# 示例输出
警告: 密码强度: 弱 (建议使用 10 位以上,包含大小写字母、数字和特殊字符)
```

---

## JAR 加密验证

### 功能简介

验证 JAR 文件是否已加密,显示加密统计信息。

### 使用方法

```bash
java -jar classfinal-2.0.1.jar --verify app-encrypted.jar
```

### 输出示例

```
=========================================
  JAR 加密验证结果
=========================================

✓ 状态: 已加密
✓ 加密方法: AES
✓ 密码保护: 是
✓ 机器绑定: 否

加密统计:
  总类数: 1523
  已加密: 1280
  加密率: 84.0%

已加密的包:
  - com.example
  - com.demo

=========================================
```

---

## 新增命令行参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--config <file>` | 从配置文件加载参数 | `--config classfinal.yml` |
| `--init-config <file>` | 生成配置文件模板 | `--init-config classfinal.yml` |
| `--verify <jar>` | 验证 JAR 是否已加密 | `--verify app.jar` |
| `--password <pwd>` | 加密密码(同 -pwd) | `--password mypass` |
| `--password-file <file>` | 从文件读取密码 | `--password-file /tmp/pwd.txt` |

---

## 最佳实践

### 密码安全

1. **生产环境**: 使用环境变量或密码文件,避免命令行暴露
2. **密码强度**: 至少 10 位,包含大小写字母、数字、特殊字符
3. **密码轮换**: 定期更换加密密码
4. **文件权限**: 密码文件设置 600 权限(`chmod 600 password.txt`)

```bash
# 推荐做法
echo "MyP@ssw0rd2026!" > /tmp/password.txt
chmod 600 /tmp/password.txt
java -jar classfinal-2.0.1.jar -file app.jar --password-file /tmp/password.txt
```

### 配置文件管理

1. **版本控制**: 不要提交包含明文密码的配置文件到 Git
2. **模板化**: 提交模板文件,使用环境变量占位符
3. **权限控制**: 配置文件设置适当权限

```bash
# .gitignore
classfinal.yml
*.secret.yml

# 提交模板
classfinal.yml.template
```

### CI/CD 集成

```bash
# GitHub Actions 示例
- name: Encrypt JAR
  env:
    CLASSFINAL_PASSWORD: ${{ secrets.ENCRYPTION_PASSWORD }}
  run: |
    java -jar classfinal-2.0.1.jar --config classfinal.yml
```

### 验证流程

```bash
# 1. 加密
java -jar classfinal-2.0.1.jar --config classfinal.yml

# 2. 验证
java -jar classfinal-2.0.1.jar --verify app-encrypted.jar

# 3. 测试运行
java -jar app-encrypted.jar --classfinal.password=your-password
```

---

## 常见问题

### Q1: 配置文件支持哪些格式?

A: 当前支持 YAML (`.yml`, `.yaml`),JSON 支持将在后续版本添加。

### Q2: 环境变量不存在会怎样?

A: 如果 `${VAR_NAME}` 对应的环境变量不存在,占位符保持原样,可能导致加密失败。

### Q3: 密码文件是否必须删除?

A: 不是必须,但推荐在读取后删除以提高安全性。可通过 `deletePasswordFile: true` 配置。

### Q4: 如何验证旧版本加密的 JAR?

A: `--verify` 功能兼容旧版本,可以验证任何 ClassFinal 加密的 JAR。

### Q5: 配置文件和命令行参数能混用吗?

A: 配置文件优先级最高,如果使用 `--config`,其他命令行参数将被忽略。

---

## 升级指南

### 从 2.0.0 升级

1. **下载新版本**: `classfinal-2.0.1.jar`
2. **生成配置文件**: `--init-config classfinal.yml`
3. **迁移参数**: 将原命令行参数迁移到配置文件
4. **测试**: 使用 `--verify` 验证加密结果

### 兼容性

- ✅ 2.0.1 加密的 JAR 可以在 2.0.0 上运行
- ✅ 2.0.0 加密的 JAR 可以在 2.0.1 上验证
- ✅ 所有命令行参数向后兼容

---

## 示例场景

### 场景 1: 简单加密

```bash
# 生成配置
java -jar classfinal-2.0.1.jar --init-config classfinal.yml

# 编辑配置(设置密码、包名等)
vim classfinal.yml

# 执行加密
java -jar classfinal-2.0.1.jar --config classfinal.yml
```

### 场景 2: CI/CD 自动化

```yaml
# classfinal.yml
input:
  file: target/app.jar
  packages:
    - com.company

encryption:
  password: ${CI_ENCRYPTION_PASSWORD}

output:
  file: target/app-encrypted.jar
  overwrite: true

advanced:
  skipConfirmation: true
```

```bash
# CI 脚本
export CI_ENCRYPTION_PASSWORD="${SECRET_PASSWORD}"
java -jar classfinal-2.0.1.jar --config classfinal.yml
java -jar classfinal-2.0.1.jar --verify target/app-encrypted.jar
```

### 场景 3: 临时密码文件

```bash
# 动态生成密码
openssl rand -base64 32 > /tmp/temp-password.txt

# 加密(自动删除密码文件)
java -jar classfinal-2.0.1.jar \
  -file app.jar \
  -packages com.example \
  --password-file /tmp/temp-password.txt

# 保存密码到密钥管理系统
cat /tmp/temp-password.txt  # (已被自动删除,需提前保存)
```

---

## 测试验证

### 单元测试

新功能都有对应的单元测试覆盖:

- **ConfigLoaderTest**: 配置文件加载、解析、环境变量替换、模板生成
- **PasswordUtilTest**: 密码读取、文件删除、异常处理
- **EncryptionVerifierTest**: 加密验证、反编译检测

运行测试:

```bash
mvn test -pl classfinal-core
```

### 集成测试

集成测试覆盖完整的加密流程,位于 `integration-test/` 目录:

#### 测试步骤 22-24 (2.0.1 新功能)

```bash
# 步骤 22: 配置文件参数测试 (--config)
# - 创建 YAML 配置文件
# - 使用 --config 参数加密
# - 验证加密应用运行

# 步骤 23: 密码文件参数测试 (--password-file)
# - 创建密码文件
# - 使用 --password-file 参数加密
# - 验证使用相同密码运行

# 步骤 24: 加密验证测试 (--verify)
# - 加密并启用 --verify 自动验证
# - 检查验证通过状态
# - 确认加密文件可用
```

#### 运行完整集成测试

```bash
# 本地测试(包含 2.0.1 新功能)
bash integration-test/run-local-tests.sh

# 测试步骤说明:
# 步骤 1-21: 现有功能测试
# 步骤 22: --config 参数测试
# 步骤 23: --password-file 参数测试
# 步骤 24: --verify 验证测试
```

#### Docker Compose 服务

新增的测试服务:

- `prepare-config-param-test`: 准备配置文件测试
- `encrypt-with-config-param`: 使用配置文件加密
- `test-config-param-encrypted`: 测试配置文件加密应用
- `prepare-password-file-test`: 准备密码文件测试
- `encrypt-with-password-file`: 使用密码文件加密
- `test-password-file-encrypted`: 测试密码文件加密应用
- `prepare-verify-test`: 准备验证测试
- `encrypt-and-verify`: 加密并验证

#### 验证测试结果

成功的测试输出示例:

```
[INFO] ================================================
[INFO] ClassFinal 本地集成测试
[INFO] ================================================
...
[INFO] [步骤 22/24] 配置文件参数测试 (--config)
[INFO] 创建加密配置文件...
[INFO] 使用配置文件加密...
[SUCCESS] ✓ 配置文件参数测试通过 (--config)

[INFO] [步骤 23/24] 密码文件参数测试 (--password-file)
[INFO] 创建密码文件...
[INFO] 使用密码文件加密...
[SUCCESS] ✓ 密码文件参数测试通过 (--password-file)

[INFO] [步骤 24/24] 加密验证测试 (--verify)
[INFO] 准备验证测试应用...
[INFO] 加密并验证...
[SUCCESS] ✓ 加密验证测试通过 (--verify)

[INFO] ================================================
[INFO] 测试完成
[INFO] ================================================
[SUCCESS] ✓ 所有本地测试通过 (包含 2.0.1 新功能)!
[INFO] 总用时: 180秒
[INFO] 测试覆盖: 基础功能 + 高级特性 + 2.0.1 新功能
```

### 手动验证步骤

#### 1. 配置文件功能

```bash
# 生成模板
java -jar classfinal-2.0.1.jar --init-config test-config.yml

# 编辑配置
vi test-config.yml

# 使用配置加密
java -jar classfinal-2.0.1.jar --config test-config.yml

# 验证结果
ls -lh *-encrypted.jar
```

#### 2. 密码文件功能

```bash
# 创建密码文件
echo "test-password-2024" > /tmp/pwd.txt

# 使用密码文件加密
java -jar classfinal-2.0.1.jar \
  -file app.jar \
  --password-file /tmp/pwd.txt

# 验证密码文件已删除(如果启用自动删除)
ls /tmp/pwd.txt  # 应该不存在
```

#### 3. 加密验证功能

```bash
# 加密并验证
java -jar classfinal-2.0.1.jar \
  -file app.jar \
  -packages com.example \
  -pwd test123 \
  --verify

# 检查返回码
echo $?  # 应该返回 0
```

---

## 反馈与贡献

- GitHub Issues: https://github.com/ygqygq2/classfinal/issues
- 文档更新: 欢迎提交 PR
- 功能建议: 在 Issues 中讨论

---

**ClassFinal 2.0.1** - 更安全、更灵活的 Java 代码加密工具
