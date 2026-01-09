# ClassFinal Maven Central 发布总结

## 已完成配置 ✅

### 1. Maven Central 配置

- ✅ 命名空间 `io.github.ygqygq2` 已验证
- ✅ OSSRH 凭证已配置到环境变量和 GitHub Secrets
- ✅ GPG 密钥已生成并上传到公钥服务器
- ✅ GitHub Secrets 已配置（4 个）

### 2. POM.xml 配置完善

- ✅ 添加项目 URL
- ✅ 配置 distributionManagement (SNAPSHOT + Release)
- ✅ 添加 maven-source-plugin
- ✅ 添加 maven-javadoc-plugin
- ✅ 添加 maven-gpg-plugin
- ✅ 添加 central-publishing-maven-plugin
- ✅ 配置 release profile

### 3. GitHub Actions 工作流

- ✅ 创建 `.github/workflows/deploy.yml`
- ✅ 支持 SNAPSHOT 自动部署（push to master）
- ✅ 支持 Release 自动部署（push tags v\*）
- ✅ 自动创建 GitHub Release

### 4. 集成测试增强

- ✅ 添加错误密码测试
- ✅ 添加多包加密测试
- ✅ 更新测试脚本支持新测试场景
- ✅ docker-compose.yml 配置完善

## 发布流程

### 开发版本（SNAPSHOT）

```bash
# 1. 确保版本号包含 -SNAPSHOT
# 当前: <version>2.0.0</version>
# 应改为: <version>2.0.1-SNAPSHOT</version>

# 2. 修改 pom.xml
sed -i 's/<version>2.0.0<\/version>/<version>2.0.1-SNAPSHOT<\/version>/g' pom.xml

# 3. 提交并推送
git add pom.xml
git commit -m "Prepare for 2.0.1-SNAPSHOT development"
git push origin master

# 4. GitHub Actions 自动部署到 SNAPSHOT 仓库
```

### 正式版本（Release）

```bash
# 1. 更新版本号（去除 SNAPSHOT）
sed -i 's/<version>2.0.1-SNAPSHOT<\/version>/<version>2.0.1<\/version>/g' pom.xml

# 2. 提交并打标签
git add pom.xml
git commit -m "Release version 2.0.1"
git tag -a v2.0.1 -m "Release version 2.0.1"

# 3. 推送标签（触发发布）
git push origin v2.0.1

# 4. GitHub Actions 自动发布到 Maven Central

# 5. 准备下一个开发版本
sed -i 's/<version>2.0.1<\/version>/<version>2.0.2-SNAPSHOT<\/version>/g' pom.xml
git add pom.xml
git commit -m "Prepare for next development iteration"
git push origin master
```

## 本地测试

### 测试完整的集成测试套件

```bash
# 运行所有测试
bash integration-test/run-tests.sh
```

### 测试本地部署（使用环境变量）

```bash
# 环境变量已配置在 ~/.bashrc
source ~/.bashrc

# 部署到本地仓库
mvn clean install -DskipTests

# 测试 GPG 签名
mvn clean verify -DskipTests -P release
```

## 验证发布

### SNAPSHOT 版本

- 仓库: https://s01.oss.sonatype.org/content/repositories/snapshots/
- 路径: `io/github/ygqygq2/classfinal-core/`

### Release 版本

- Maven Central: https://search.maven.org/search?q=g:io.github.ygqygq2
- Central Portal: https://central.sonatype.com/
- 等待时间: 15-30 分钟同步，2-4 小时完全同步

## 使用已发布的库

### SNAPSHOT 版本

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

### Release 版本

```xml
<dependency>
  <groupId>io.github.ygqygq2</groupId>
  <artifactId>classfinal-core</artifactId>
  <version>2.0.1</version>
</dependency>
```

## 下一步建议

1. **更新版本号到 SNAPSHOT**

   ```bash
   # 修改所有 pom.xml 的版本为 2.0.1-SNAPSHOT
   find . -name pom.xml -exec sed -i 's/<version>2.0.0<\/version>/<version>2.0.1-SNAPSHOT<\/version>/g' {} \;
   ```

2. **测试集成测试**

   ```bash
   bash integration-test/run-tests.sh
   ```

3. **提交并推送（触发 SNAPSHOT 部署）**

   ```bash
   git add .
   git commit -m "chore: update to 2.0.1-SNAPSHOT and add Maven Central deployment"
   git push origin master
   ```

4. **监控 GitHub Actions**

   - 查看: https://github.com/ygqygq2/classfinal/actions
   - 确认部署成功

5. **准备首次 Release**
   - 测试 SNAPSHOT 版本正常工作
   - 更新 CHANGELOG.md
   - 按照上述 Release 流程发布 v2.0.1

## 注意事项

⚠️ **版本管理**

- 开发时使用 SNAPSHOT 版本
- 发布时去除 SNAPSHOT
- 发布后立即更新到下一个 SNAPSHOT 版本

⚠️ **GPG 密码**

- 确保 GPG_PASSPHRASE 在 GitHub Secrets 中正确设置
- 本地测试时从环境变量读取

⚠️ **Maven Central 规则**

- Release 版本不可覆盖
- SNAPSHOT 版本可以多次上传
- 所有 artifact 必须 GPG 签名

## 参考文档

- [Maven Central 发布指南](docs/05-maven-central-deployment.md)
- [集成测试文档](docs/04-integration-testing.md)
- [GitHub Actions 配置](.github/workflows/deploy.yml)
