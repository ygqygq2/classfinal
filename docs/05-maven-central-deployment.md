# Maven Central 发布指南

## 第一步：申请 Maven Central 账号和 Token

### 1. 注册 Sonatype JIRA 账号

Maven Central 现在使用 Sonatype Central Portal，需要先注册账号：

1. 访问 https://central.sonatype.com/
2. 点击右上角 "Sign In" → "Sign Up"
3. 填写注册信息并验证邮箱

### 2. 验证命名空间所有权

由于您的项目使用 `io.github.ygqygq2` 作为 groupId，需要验证 GitHub 账号所有权：

1. 登录 https://central.sonatype.com/
2. 进入 "Namespaces" 页面
3. 点击 "Add Namespace"
4. 输入命名空间：`io.github.ygqygq2`
5. 按照提示验证 GitHub 账号：
   - 系统会要求您在 GitHub 创建一个验证仓库，如：`ygqygq2/OSSRH-xxxxx`
   - 或在现有仓库添加验证文件
   - 验证通过后即可使用该命名空间

### 3. 生成 User Token

1. 登录 https://central.sonatype.com/
2. 点击右上角用户头像 → "View Account"
3. 进入 "Generate User Token" 页面
4. 点击 "Generate User Token" 按钮
5. 保存生成的 Username 和 Password（Token）

**重要：Token 只会显示一次，请妥善保存！**

示例格式：

```
Username: AbCdEfGh
Password: 1234567890abcdefghijklmnopqrstuvwxyz
```

### 4. 生成 GPG 密钥

Maven Central 要求所有发布的 artifacts 必须使用 GPG 签名。

#### 安装 GPG

```bash
# Ubuntu/Debian
sudo apt-get install gnupg

# macOS
brew install gnupg

# 验证安装
gpg --version
```

#### 生成密钥对

```bash
# 生成密钥
gpg --gen-key

# 按提示输入：
# - 真实姓名（Real name）
# - 电子邮件地址（Email address）
# - 注释（Comment，可选）
# - 密码短语（Passphrase）- 请记住此密码！
```

#### 导出密钥

```bash
# 查看密钥列表
gpg --list-keys

# 输出示例：
# pub   rsa3072 2024-01-01 [SC] [expires: 2026-01-01]
#       ABCDEF1234567890ABCDEF1234567890ABCDEF12
# uid           [ultimate] Your Name <your.email@example.com>
# sub   rsa3072 2024-01-01 [E] [expires: 2026-01-01]

# 导出私钥（ABCDEF12... 替换为你的密钥ID）
gpg --armor --export-secret-keys ABCDEF1234567890 > private-key.asc

# 上传公钥到密钥服务器
gpg --keyserver keyserver.ubuntu.com --send-keys ABCDEF1234567890
gpg --keyserver keys.openpgp.org --send-keys ABCDEF1234567890
gpg --keyserver pgp.mit.edu --send-keys ABCDEF1234567890
```

## 第二步：配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

1. 进入仓库页面：https://github.com/ygqygq2/classfinal
2. 点击 "Settings" → "Secrets and variables" → "Actions"
3. 点击 "New repository secret" 添加以下密钥：

### 必需的 Secrets

| Secret 名称       | 说明                            | 示例/获取方式                    |
| ----------------- | ------------------------------- | -------------------------------- |
| `OSSRH_USERNAME`  | Sonatype User Token 的 Username | 从 Central Portal 生成           |
| `OSSRH_PASSWORD`  | Sonatype User Token 的 Password | 从 Central Portal 生成           |
| `GPG_PRIVATE_KEY` | GPG 私钥内容                    | `cat private-key.asc` 的完整输出 |
| `GPG_PASSPHRASE`  | GPG 密钥密码                    | 创建 GPG 密钥时设置的密码        |

### 添加步骤

```bash
# 1. 复制 GPG 私钥内容
cat private-key.asc

# 2. 在 GitHub Secrets 中：
#    Name: GPG_PRIVATE_KEY
#    Value: 粘贴完整的私钥内容（包括 -----BEGIN PGP PRIVATE KEY BLOCK----- 等）

# 3. 添加其他 Secrets
#    OSSRH_USERNAME: 你的 User Token Username
#    OSSRH_PASSWORD: 你的 User Token Password
#    GPG_PASSPHRASE: GPG 密钥密码
```

## 第三步：配置项目 POM

确保 `pom.xml` 包含必要的元数据（已在项目中配置）：

- [x] `<name>`, `<description>`, `<url>`
- [x] `<licenses>` - Apache 2.0
- [x] `<developers>` - 开发者信息
- [x] `<scm>` - Git 仓库信息
- [x] Distribution Management - SNAPSHOT 和 Release 仓库
- [x] GPG 签名插件配置
- [x] Nexus Staging 插件配置

## 第四步：发布流程

### 开发版本（SNAPSHOT）

平时开发使用 SNAPSHOT 版本：

```bash
# 确保版本号以 -SNAPSHOT 结尾
# 例如：<version>2.0.1-SNAPSHOT</version>

# 本地测试部署
mvn clean deploy -DskipTests

# GitHub Actions 自动部署
# 推送到 master 分支时自动触发
git push origin master
```

### 正式版本（Release）

发布正式版本到 Maven Central：

```bash
# 1. 更新版本号（去除 SNAPSHOT）
# 编辑 pom.xml: 2.0.1-SNAPSHOT → 2.0.1

# 2. 提交并打标签
git add .
git commit -m "Release version 2.0.1"
git tag -a v2.0.1 -m "Release version 2.0.1"

# 3. 推送标签（触发 GitHub Actions 发布）
git push origin v2.0.1

# 4. GitHub Actions 会自动：
#    - 构建项目
#    - GPG 签名
#    - 部署到 Maven Central
#    - 自动发布（无需手动在 Sonatype 确认）

# 5. 更新为下一个 SNAPSHOT 版本
# 编辑 pom.xml: 2.0.1 → 2.0.2-SNAPSHOT
git add .
git commit -m "Prepare for next development iteration"
git push origin master
```

## 第五步：验证发布

### 检查 SNAPSHOT 版本

- SNAPSHOT 仓库：https://s01.oss.sonatype.org/content/repositories/snapshots/
- 访问路径：`io/github/ygqygq2/classfinal-core/`

### 检查 Release 版本

发布后等待约 15-30 分钟，检查：

1. **Central Portal**：https://central.sonatype.com/
   - 搜索：`io.github.ygqygq2`
2. **Maven Central Search**：https://search.maven.org/

   - 搜索：`g:io.github.ygqygq2 AND a:classfinal-core`

3. **Maven Repository**：https://mvnrepository.com/
   - 搜索：`classfinal`

## 使用发布的库

### SNAPSHOT 版本（开发）

```xml
<repositories>
  <repository>
    <id>sonatype-snapshots</id>
    <url>https://s01.oss.sonatype.org/content/repositories/snapshots/</url>
    <snapshots>
      <enabled>true</enabled>
    </snapshots>
  </repository>
</repositories>

<dependency>
  <groupId>io.github.ygqygq2</groupId>
  <artifactId>classfinal-core</artifactId>
  <version>2.0.1-SNAPSHOT</version>
</dependency>
```

### Release 版本（生产）

```xml
<dependency>
  <groupId>io.github.ygqygq2</groupId>
  <artifactId>classfinal-core</artifactId>
  <version>2.0.1</version>
</dependency>
```

## 常见问题

### 1. 发布失败：401 Unauthorized

- 检查 `OSSRH_USERNAME` 和 `OSSRH_PASSWORD` 是否正确
- 确认 User Token 未过期

### 2. GPG 签名失败

- 确认 `GPG_PRIVATE_KEY` 包含完整内容
- 确认 `GPG_PASSPHRASE` 正确
- 检查 GPG 密钥是否已上传到公钥服务器

### 3. 命名空间验证失败

- 确保已在 Central Portal 验证 GitHub 账号
- 确认 groupId 与验证的命名空间一致

### 4. 发布后在 Maven Central 找不到

- Release 版本需要 15-30 分钟同步到 Central
- 完整同步到所有镜像可能需要 2-4 小时
- 检查 Central Portal 是否显示 "Published"

### 5. SNAPSHOT 版本覆盖

- SNAPSHOT 版本可以多次发布覆盖
- 使用时指定 `<updatePolicy>always</updatePolicy>` 获取最新版本

## 安全建议

1. **绝不要**将 GPG 私钥或密码提交到代码仓库
2. **绝不要**将 Sonatype Token 提交到代码仓库
3. **使用**GitHub Secrets 存储所有敏感信息
4. **定期轮换** User Token（建议每年更新）
5. **备份** GPG 密钥对（安全存储在本地）

## 参考资料

- [Maven Central Publishing Guide](https://central.sonatype.org/publish/publish-guide/)
- [Sonatype Central Portal](https://central.sonatype.com/)
- [GPG 签名指南](https://central.sonatype.org/publish/requirements/gpg/)
- [GitHub Actions 配置示例](https://github.com/actions/setup-java#publishing-using-apache-maven)
