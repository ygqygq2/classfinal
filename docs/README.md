# ClassFinal 文档中心

欢迎查阅 ClassFinal 项目文档！

## 📚 文档列表

### [01. 架构设计文档](01-architecture-design.md)

深入了解 ClassFinal 的核心架构、加密原理、技术栈和设计理念。

**主要内容**:

- 项目概述和模块划分
- 加密/解密原理详解
- Docker 容器化架构
- 环境变量配置
- 版本管理策略
- 安全设计和已知限制
- CI/CD 工作流
- 性能和兼容性考量

**适合人群**: 架构师、技术决策者、深度使用者

---

### [02. Docker 使用指南](02-docker-usage.md)

使用 Docker 快速部署和运行 ClassFinal，支持多种运行模式。

**主要内容**:

- Docker 镜像获取
- 加密模式使用
- JavaAgent 模式运行加密应用
- Web 控制台部署
- 环境变量配置详解
- Docker Compose 编排
- 常见问题解决

**适合人群**: 运维工程师、DevOps、容器化部署用户

---

### [03. 开发指南](03-development-guide.md)

参与 ClassFinal 项目开发的完整指南，从环境配置到代码贡献。

**主要内容**:

- 开发环境配置
- 项目结构说明
- 构建和测试流程
- 代码规范和 Git 提交规范
- 开发工作流
- 调试技巧
- 性能优化建议
- 发布流程
- 贡献指南

**适合人群**: 开发者、贡献者、维护者

---

### [04. 集成测试文档](04-integration-testing.md)

ClassFinal 的集成测试环境和测试流程说明。

**主要内容**:

- 测试环境架构
- Docker Compose 测试编排
- 测试场景说明
- 测试步骤详解
- 测试结果验证
- 故障排查

**适合人群**: 测试工程师、QA、CI/CD 配置人员

---

### [05. Maven Central 部署指南](05-maven-central-deployment.md)

如何将 ClassFinal 发布到 Maven Central 仓库。

**主要内容**:

- OSSRH 账号注册
- GPG 密钥配置
- pom.xml 配置
- 发布流程
- GitHub Actions 自动化
- 常见问题解决

**适合人群**: 项目维护者、发布管理员

---

### [06. 部署总结文档](06-deployment-summary.md)

Maven Central 部署配置的总结和核对清单。

**主要内容**:

- 配置核对清单
- GitHub Secrets 配置
- 工作流说明
- 发布步骤
- 验证方法

**适合人群**: 项目维护者、CI/CD 配置人员

---

### [07. 集成测试指南](07-integration-testing-guide.md)

详细的集成测试执行指南和最佳实践。

**主要内容**:

- 本地测试 vs CI 测试
- 测试脚本使用
- 中国镜像配置
- 测试结果分析
- 故障排查指南

**适合人群**: 开发者、测试工程师、贡献者

---

### [08. 完整测试覆盖文档](08-complete-test-coverage.md)

ClassFinal 完整的测试覆盖说明，包含所有 19 个测试场景。

**主要内容**:

- 19 个测试场景详解
- 测试架构(32 个 Docker 服务)
- 测试覆盖矩阵
- 运行指南
- 验证方法
- 性能指标
- 持续改进计划

**适合人群**: QA 工程师、测试负责人、项目审核者

---

## 🚀 快速开始

### 首次使用者

1. 阅读 [README.md](../README.md) 了解项目基本信息
2. 查看 [02-docker-usage.md](02-docker-usage.md) 快速上手 Docker 部署
3. 参考项目 README 中的"使用说明"章节进行基本操作

### 开发者

1. 阅读 [01-architecture-design.md](01-architecture-design.md) 理解项目架构
2. 按照 [03-development-guide.md](03-development-guide.md) 配置开发环境
3. 查看 [04-integration-testing.md](04-integration-testing.md) 运行测试

### 运维人员

1. 学习 [02-docker-usage.md](02-docker-usage.md) 掌握容器化部署
2. 了解 [01-architecture-design.md](01-architecture-design.md) 中的环境变量配置
3. 参考集成测试文档验证部署效果

## 📋 版本说明

- **最后更新**: 2026-01-15
- **维护者**: ygqygq2
- **测试覆盖**: 24 个场景，30+ 个 Docker 服务

## 🔗 相关链接

- **项目主页**: https://github.com/ygqygq2/classfinal
- **问题反馈**: https://github.com/ygqygq2/classfinal/issues
- **原始项目**: https://gitee.com/roseboy/classfinal

## 📝 文档贡献

发现文档错误或有改进建议？欢迎提交 Issue 或 Pull Request！

### 文档编写规范

- 使用 Markdown 格式
- 文件名格式: `序号-名称.md`（如 `01-architecture-design.md`）
- 保持文档结构清晰，使用合适的标题层级
- 代码示例使用代码块并指定语言
- 重要信息使用引用或高亮
- 定期更新文档内容与代码同步

## ❓ 常见问题

### Q: 文档如何查看？

A: 直接在 GitHub 上浏览，或克隆项目后使用 Markdown 阅读器查看。

### Q: 文档更新频率？

A: 随项目版本更新，重大功能变更时会同步更新文档。

### Q: 如何贡献文档？

A: 参考 [03-development-guide.md](03-development-guide.md) 中的贡献指南。

---

**感谢使用 ClassFinal！** 🎉
