**Changelog**

# 2.0.1-SNAPSHOT (开发中)

## 新功能 ✨

### 配置文件支持
- ✅ YAML 配置文件加载 (`--config classfinal.yml`)
- ✅ 配置文件模板生成 (`--init-config`)
- ✅ 环境变量占位符 `${VAR_NAME}`
- ⏳ JSON 格式支持（待实现）

### 密码管理增强
- ✅ 从文件读取密码 (`--password-file`)
- ✅ 读取后自动删除密码文件
- ✅ 密码强度检查和警告
- ✅ 密码验证（最小长度 6 位）
- ✅ 环境变量密码读取

### 加密验证工具
- ✅ JAR 加密状态检测 (`--verify`)
- ✅ 加密统计信息（类数、加密率）
- ✅ 加密包列表展示
- ✅ 密码保护和机器绑定检测

### 命令行改进
- ✅ 支持 `--long-option` 格式
- ✅ `--password` 参数（同 `-pwd`）
- ✅ 新增 `--verify`、`--config`、`--init-config` 等参数

## 测试 🧪
- ✅ ConfigLoader 单元测试（YAML 解析、环境变量、验证）
- ✅ PasswordUtil 单元测试（文件读取、强度检查、验证）
- ✅ EncryptionVerifier 单元测试（JAR 验证、统计）

## 文档 📚
- ✅ 新功能使用指南 (`docs/11-new-features-2.0.1.md`)
- ✅ 最佳实践和常见问题
- ✅ CI/CD 集成示例

## 待完成 🚧
- [ ] ConfigLoader JSON 格式支持
- [ ] 命令行帮助信息更新
- [ ] 集成测试覆盖新功能
- [ ] 性能优化和错误处理改进

# 2.0.0

## 新功能

- Docker 容器化支持（多阶段构建、环境变量配置）
- 环境变量非交互式配置（Main.java）
- 动态版本管理（MANIFEST.MF / 环境变量 / "dev"）
- 集成测试环境（Docker Compose）

## 重构

- GroupId 更改为 `io.github.ygqygq2`
- 镜像仓库迁移到 GitHub Container Registry
- 文档重组到 `docs/` 目录
- 统一容器路径为 `/app/app.jar`

## 修复

- Docker 构建缓存问题
- JavaAgent 密码读取逻辑
- 环境变量传递问题

## 文档

- 新增架构设计文档
- 新增 Docker 使用指南
- 新增开发指南
- 新增集成测试文档

# 1.2.1

**发布日期**: 2020-05-18  
**原作者**: roseboy

## 功能

- JAR/WAR 包加密
- JavaAgent 运行时解密
- Spring 框架兼容
- Maven 插件支持
- 无密码模式
- 机器码绑定
- Web 管理控制台
