**更新日志**

# 2.0.0

## 新功能

- Docker 容器化支持（多阶段构建、环境变量配置）
- 环境变量非交互式配置（Main.java）
- 动态版本管理（MANIFEST.MF / 环境变量 / "dev"）
- 集成测试环境（Docker Compose）

### 重构

- GroupId 更改为 `io.github.ygqygq2`
- 镜像仓库迁移到 GitHub Container Registry
- 文档重组到 `docs/` 目录
- 统一容器路径为 `/app/app.jar`

### 修复

- Docker 构建缓存问题
- JavaAgent 密码读取逻辑
- 环境变量传递问题

### 文档

- 新增架构设计文档
- 新增 Docker 使用指南
- 新增开发指南
- 新增集成测试文档

---

# 1.2.1

**发布日期**: 2020-05-18  
**原作者**: roseboy

### 功能

- JAR/WAR 包加密
- JavaAgent 运行时解密
- Spring 框架兼容
- Maven 插件支持
- 无密码模式
- 机器码绑定
- Web 管理控制台
