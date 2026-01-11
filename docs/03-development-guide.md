# ClassFinal 开发指南

## 开发环境配置

### 必需工具

- **JDK**: 1.8 或更高版本
- **Maven**: 3.6+
- **Git**: 2.0+
- **Docker**: 20.10+ （可选，用于容器测试）
- **Docker Compose**: v2.0+ （可选）

### IDE 推荐

- **IntelliJ IDEA**: 推荐使用 Ultimate 版本
- **Eclipse**: 需安装 Maven 插件
- **VS Code**: 需安装 Java Extension Pack

### 克隆项目

```bash
git clone git@github.com:ygqygq2/classfinal.git
cd classfinal
```

## 项目结构

```
classfinal/
├── classfinal-core/              # 核心模块
│   ├── src/main/java/
│   │   └── net/roseboy/classfinal/
│   │       ├── AgentTransformer.java    # 字节码转换器
│   │       ├── CoreAgent.java           # Agent 核心逻辑
│   │       ├── JarEncryptor.java        # JAR 加密
│   │       ├── JarDecryptor.java        # JAR 解密
│   │       └── util/                    # 工具类
│   └── pom.xml
│
├── classfinal-fatjar/            # 独立可执行模块
│   ├── src/main/java/
│   │   └── net/roseboy/classfinal/
│   │       ├── Agent.java               # Agent 入口
│   │       └── Main.java                # 主入口
│   └── pom.xml
│
├── classfinal-maven-plugin/      # Maven 插件
│   ├── src/main/java/
│   │   └── net/roseboy/classfinal/plugin/
│   │       └── ClassFinalPlugin.java
│   └── pom.xml
│
├── classfinal-web/               # Web 控制台
│   ├── src/main/java/
│   │   └── net/roseboy/classfinal/
│   │       ├── Application.java
│   │       └── web/
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   ├── static/
│   │   └── templates/
│   └── pom.xml
│
├── integration-test/             # 集成测试
│   ├── test-app/                 # 测试应用
│   │   ├── src/
│   │   ├── pom.xml
│   │   └── Dockerfile
│   └── docker/
│       └── entrypoint.sh         # 容器启动脚本
│
├── docs/                         # 文档目录
├── Dockerfile                    # ClassFinal 主镜像
├── docker-compose.yml            # 集成测试编排
├── pom.xml                       # 父 POM
└── README.md                     # 项目说明
```

## 构建项目

### 本地构建

```bash
# 完整构建（包括所有模块）
mvn clean install

# 跳过测试
mvn clean install -DskipTests

# 只构建核心模块
cd classfinal-core
mvn clean install
```

### Docker 构建

```bash
# 构建 ClassFinal 镜像
docker build -t ghcr.io/ygqygq2/classfinal/classfinal:dev .

# 使用国内镜像源（加快构建速度）
docker build --build-arg USE_CHINA_MIRROR=true -t ghcr.io/ygqygq2/classfinal/classfinal:dev .

# 构建测试应用
docker build -f integration-test/test-app/Dockerfile -t ghcr.io/ygqygq2/classfinal/test-app:dev .

# 使用 docker-compose 构建所有镜像
docker-compose build
```

## 运行测试

### 单元测试

```bash
# 运行所有单元测试
mvn test

# 运行特定模块的测试
cd classfinal-core
mvn test
```

### 集成测试

```bash
# 构建镜像
docker-compose build classfinal test-app

# 运行完整测试套件
docker-compose up prepare-test-app encrypt-app test-encrypted-with-password

# 查看测试日志
docker-compose logs -f test-encrypted-with-password

# 清理测试环境
docker-compose down -v
```

### 手动测试

```bash
# 1. 准备测试 JAR
cd integration-test/test-app
mvn clean package

# 2. 加密测试
java -jar ../../classfinal-fatjar/target/classfinal-*.jar \
  -file target/classfinal-test-app-*.jar \
  -packages io.github.ygqygq2.test \
  -pwd test123 \
  -Y

# 3. 运行加密后的 JAR（使用 JavaAgent）
java -javaagent:target/classfinal-test-app-*-encrypted.jar='-pwd test123' \
  -jar target/classfinal-test-app-*-encrypted.jar
```

## 代码规范

### Java 代码风格

- 遵循 Google Java Style Guide
- 使用 4 空格缩进
- 类名使用大驼峰（PascalCase）
- 方法名和变量名使用小驼峰（camelCase）
- 常量使用全大写下划线分隔（UPPER_SNAKE_CASE）

### 注释规范

```java
/**
 * 类说明（简要描述类的功能）
 *
 * @author 作者名
 */
public class Example {

    /**
     * 方法说明（描述方法的功能、参数和返回值）
     *
     * @param param1 参数1说明
     * @param param2 参数2说明
     * @return 返回值说明
     * @throws IOException 可能抛出的异常说明
     */
    public String exampleMethod(String param1, int param2) throws IOException {
        // 实现代码
    }
}
```

### Git 提交规范

使用语义化提交消息：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型**:

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构（既不是新功能也不是修复 bug）
- `test`: 测试相关
- `chore`: 构建工具或辅助工具的变动

**示例**:

```bash
git commit -m "feat(core): 支持环境变量配置加密参数"
git commit -m "fix(docker): 修复 entrypoint.sh 的密码传递问题"
git commit -m "docs: 更新 Docker 使用文档"
```

## 开发工作流

### 功能开发流程

1. **创建特性分支**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **开发和测试**

   - 编写代码
   - 添加单元测试
   - 本地测试验证

3. **提交代码**

   ```bash
   git add .
   git commit -m "feat: 描述你的功能"
   ```

4. **推送分支**

   ```bash
   git push origin feature/your-feature-name
   ```

5. **创建 Pull Request**

   - 在 GitHub 上创建 PR
   - 填写 PR 描述
   - 等待 CI 检查通过
   - 请求代码审查

6. **合并到主分支**
   - 审查通过后合并
   - 删除特性分支

### Bug 修复流程

1. **创建修复分支**

   ```bash
   git checkout -b fix/bug-description
   ```

2. **修复和测试**

   - 定位问题
   - 编写修复代码
   - 添加回归测试

3. **提交和推送**

   ```bash
   git commit -m "fix: 修复 xxx 问题"
   git push origin fix/bug-description
   ```

4. **创建 PR 并合并**

## 调试技巧

### 调试加密过程

```bash
# 启用详细日志
export CLASSFINAL_DEBUG=true

# 运行加密并查看详细输出
java -jar classfinal-2.0.0.jar -file app.jar -packages com.example -pwd test -Y
```

### 调试 JavaAgent

```java
// 在 CoreAgent.premain() 中添加调试日志
public static void premain(String args, Instrumentation inst) {
    System.out.println("DEBUG: Agent args = " + args);
    System.out.println("DEBUG: Instrumentation = " + inst);
    // ... 其他代码
}
```

### 查看加密文件内容

```bash
# 查看 MANIFEST.MF
unzip -p app-encrypted.jar META-INF/MANIFEST.MF

# 查看密码 Hash
unzip -p app-encrypted.jar META-INF/CLASSFINAL-INF/passhash | xxd

# 列出加密的类
unzip -l app-encrypted.jar | grep "\.class$"
```

### Docker 容器调试

```bash
# 进入运行中的容器
docker exec -it container-name /bin/sh

# 查看容器日志
docker logs -f container-name

# 查看容器环境变量
docker exec container-name env

# 复制容器内文件到本地
docker cp container-name:/data/app.jar ./app.jar
```

## 性能优化

### 加密性能优化

```java
// 使用并行流加速多文件处理
List<File> classFiles = findClassFiles(jarFile);
classFiles.parallelStream()
    .forEach(file -> encryptClass(file, password));
```

### 内存优化

```java
// 及时清理敏感数据
try {
    byte[] decryptedBytes = decrypt(encryptedBytes, password);
    // 使用 decryptedBytes
} finally {
    // 清零敏感数据
    Arrays.fill(decryptedBytes, (byte) 0);
    Arrays.fill(password, '\0');
}
```

## 常见问题解决

### Maven 构建失败

**问题**: 依赖下载失败

```
[ERROR] Failed to execute goal ... Could not resolve dependencies
```

**解决**:

```bash
# 清理本地仓库缓存
mvn dependency:purge-local-repository

# 使用国内镜像源
# 编辑 ~/.m2/settings.xml 添加阿里云镜像
```

### Docker 构建慢

**问题**: 构建时间过长

**解决**:

```bash
# 使用国内镜像源
docker build --build-arg USE_CHINA_MIRROR=true .

# 使用 BuildKit 加速
export DOCKER_BUILDKIT=1
docker build .
```

### 测试失败

**问题**: 集成测试运行失败

**解决**:

```bash
# 清理旧的容器和卷
docker-compose down -v

# 重新构建镜像
docker-compose build --no-cache

# 查看详细日志
docker-compose up --abort-on-container-exit
```

## 发布流程

### 准备发布

1. **更新版本号**

   ```bash
   # 修改所有 pom.xml 中的版本
   mvn versions:set -DnewVersion=2.1.0
   ```

2. **更新文档**

   - 更新 README.md
   - 更新 CHANGELOG.md
   - 更新版本相关文档

3. **运行完整测试**
   ```bash
   mvn clean verify
   docker-compose build
   docker-compose up --abort-on-container-exit
   ```

### 创建发布

1. **提交版本变更**

   ```bash
   git add .
   git commit -m "chore: 发布 v2.1.0"
   git push origin main
   ```

2. **创建标签**

   ```bash
   git tag -a v2.1.0 -m "Release v2.1.0"
   git push origin v2.1.0
   ```

3. **GitHub Actions 自动发布**
   - CI 自动构建并推送镜像到 GHCR
   - 自动创建 GitHub Release
   - 上传构建产物

### 发布到 Maven Central

1. **配置 GPG**

   ```bash
   gpg --gen-key
   gpg --list-keys
   gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>
   ```

2. **配置 settings.xml**

   ```xml
   <server>
       <id>ossrh</id>
       <username>your-jira-username</username>
       <password>your-jira-password</password>
   </server>
   ```

3. **部署**
   ```bash
   mvn clean deploy -P release
   ```

## 贡献代码

### 提交 Pull Request

1. Fork 项目到你的账号
2. 创建特性分支
3. 编写代码和测试
4. 提交 PR 并描述你的更改
5. 等待代码审查
6. 根据反馈修改
7. 合并到主分支

### 代码审查清单

- [ ] 代码遵循项目编码规范
- [ ] 添加了必要的注释
- [ ] 添加了单元测试
- [ ] 所有测试通过
- [ ] 更新了相关文档
- [ ] 提交消息符合规范
- [ ] 没有引入新的依赖（或已说明必要性）

## 联系方式

- **项目主页**: https://github.com/ygqygq2/classfinal
- **问题反馈**: https://github.com/ygqygq2/classfinal/issues
- **维护者**: ygqygq2

## 参考资料

- [Maven 官方文档](https://maven.apache.org/guides/)
- [Docker 官方文档](https://docs.docker.com/)
- [Java Instrumentation API](https://docs.oracle.com/javase/8/docs/api/java/lang/instrument/package-summary.html)
- [Javassist 用户指南](https://www.javassist.org/tutorial/tutorial.html)
