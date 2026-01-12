# 2.0.1 集成测试更新

## 概述

为支持 2.0.1 版本的新功能（配置文件、密码文件、加密验证），在集成测试中新增了 3 个测试步骤（步骤 22-24）。

## 新增测试步骤

### 步骤 22: 配置文件参数测试

**测试目标**: 验证 `--config` 参数功能

**测试流程**:
1. 创建 YAML 配置文件 (`classfinal.yml`)
2. 使用 `--config` 参数执行加密
3. 验证加密应用可以正常运行

**相关服务**:
- `prepare-config-param-test`: 准备配置文件
- `encrypt-with-config-param`: 使用配置文件加密
- `test-config-param-encrypted`: 测试运行加密应用

### 步骤 23: 密码文件参数测试

**测试目标**: 验证 `--password-file` 参数功能

**测试流程**:
1. 创建密码文件 (`password.txt`)
2. 使用 `--password-file` 参数加密
3. 验证使用相同密码可以运行加密应用

**相关服务**:
- `prepare-password-file-test`: 准备密码文件
- `encrypt-with-password-file`: 使用密码文件加密
- `test-password-file-encrypted`: 测试运行加密应用

### 步骤 24: 加密验证测试

**测试目标**: 验证 `--verify` 参数功能

**测试流程**:
1. 准备测试应用
2. 加密时启用 `--verify` 参数
3. 验证加密成功且文件可用

**相关服务**:
- `prepare-verify-test`: 准备测试应用
- `encrypt-and-verify`: 加密并验证

## 修改的文件

### 1. 集成测试脚本

**文件**: `integration-test/run-local-tests.sh`

**修改内容**:
- 新增步骤 22-24 的测试逻辑
- 更新测试完成消息，标注包含 2.0.1 新功能

### 2. Docker Compose 配置

**文件**: `docker-compose.yml`

**新增服务**:
- `test-mvn-install`: Maven 本地安装测试
- `prepare-config-param-test`: 配置文件测试准备
- `encrypt-with-config-param`: 配置文件加密
- `test-config-param-encrypted`: 配置文件加密应用测试
- `prepare-password-file-test`: 密码文件测试准备
- `encrypt-with-password-file`: 密码文件加密
- `test-password-file-encrypted`: 密码文件加密应用测试
- `prepare-verify-test`: 验证测试准备
- `encrypt-and-verify`: 加密验证测试

### 3. 测试资源文件

**新增文件**:
```
integration-test/test-apps/
├── config-param/
│   ├── classfinal-config.yml   # 测试配置文件
│   ├── prepare.sh              # 准备脚本
│   └── encrypt.sh              # 加密脚本
├── password-file/
│   ├── password.txt            # 密码文件
│   ├── prepare.sh              # 准备脚本
│   └── encrypt.sh              # 加密脚本
└── verify/
    ├── prepare.sh              # 准备脚本
    └── test-verify.sh          # 验证脚本
```

### 4. 文档更新

**文件**: `docs/11-new-features-2.0.1.md`

**新增章节**:
- 测试验证 - 单元测试
- 测试验证 - 集成测试
- 测试验证 - 手动验证步骤

**文件**: `docs/07-integration-testing-guide.md`

**更新内容**:
- 测试场景数量: 19 → 24
- 新增步骤 22-24 的详细说明

## 运行测试

### 本地运行

```bash
# 运行完整测试(24 步)
bash integration-test/run-local-tests.sh

# 只运行 2.0.1 新功能测试
docker-compose run --rm prepare-config-param-test
docker-compose run --rm encrypt-with-config-param
docker-compose up -d test-config-param-encrypted

docker-compose run --rm prepare-password-file-test
docker-compose run --rm encrypt-with-password-file
docker-compose up -d test-password-file-encrypted

docker-compose run --rm prepare-verify-test
docker-compose run --rm encrypt-and-verify
```

### CI 运行

GitHub Actions 会自动运行完整的 24 步测试。

## 测试覆盖

### 功能覆盖

- ✅ 配置文件加载与解析
- ✅ 环境变量替换
- ✅ 密码文件读取
- ✅ 密码文件自动删除（可选）
- ✅ 加密后自动验证
- ✅ 验证失败时的错误处理

### 场景覆盖

- ✅ 使用 YAML 配置文件加密
- ✅ 配置文件中使用环境变量
- ✅ 从文件读取密码
- ✅ 密码文件的安全处理
- ✅ 加密验证的返回码检查
- ✅ 加密应用的运行验证

## 注意事项

1. **Docker 镜像版本**: 确保使用 `classfinal:2.0.1` 镜像
2. **测试顺序**: 步骤 22-24 依赖前面步骤的基础镜像构建
3. **清理**: 测试完成后会自动清理容器和临时文件
4. **日志**: 测试过程中的详细日志会输出到控制台

## 后续计划

- [ ] 添加配置文件验证的负面测试（无效 YAML、缺少必填字段）
- [ ] 添加密码文件权限测试
- [ ] 添加更多环境变量替换场景
- [ ] 性能测试：大型 JAR 文件加密验证

---

**更新时间**: 2026-01-12  
**版本**: 2.0.1-SNAPSHOT
