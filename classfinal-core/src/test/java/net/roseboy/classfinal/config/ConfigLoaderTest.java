package net.roseboy.classfinal.config;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ConfigLoader 单元测试
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class ConfigLoaderTest {
    
    private String testConfigFile;
    
    @BeforeEach
    public void setUp() {
        testConfigFile = "/tmp/test-config-" + System.currentTimeMillis() + ".yml";
    }
    
    @AfterEach
    public void tearDown() {
        if (testConfigFile != null) {
            new File(testConfigFile).delete();
        }
    }
    
    @Test
    public void testLoadBasicYaml() throws IOException {
        // 创建基本的 YAML 配置
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "  packages:\n" +
                "    - com.example\n" +
                "    - com.demo\n" +
                "encryption:\n" +
                "  password: test123\n" +
                "  mode: password\n" +
                "output:\n" +
                "  file: app-encrypted.jar\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        assertNotNull(config);
        assertNotNull(config.getInput());
        assertEquals("app.jar", config.getInput().getFile());
        assertNotNull(config.getInput().getPackages());
        assertEquals(2, config.getInput().getPackages().length);
        assertEquals("com.example", config.getInput().getPackages()[0]);
        
        assertNotNull(config.getEncryption());
        assertEquals("test123", config.getEncryption().getPassword());
        assertEquals("password", config.getEncryption().getMode());
        
        assertNotNull(config.getOutput());
        assertEquals("app-encrypted.jar", config.getOutput().getFile());
    }
    
    @Test
    public void testLoadYamlWithComments() throws IOException {
        // 测试带注释的 YAML
        String yaml = "# 这是注释\n" +
                "input:\n" +
                "  file: app.jar  # 输入文件\n" +
                "\n" +  // 空行
                "encryption:\n" +
                "  password: test123\n" +
                "  # 加密模式\n" +
                "  mode: password\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        assertNotNull(config);
        assertEquals("app.jar", config.getInput().getFile());
        assertEquals("test123", config.getEncryption().getPassword());
    }
    
    @Test
    public void testEnvironmentVariableReplacement() throws IOException {
        // 设置环境变量（使用已存在的环境变量 PATH）
        String envValue = System.getenv("PATH");
        assertNotNull("PATH 环境变量应该存在", envValue);
        
        // 使用环境变量占位符
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "encryption:\n" +
                "  password: ${PATH}\n" +  // 使用 PATH 环境变量
                "  mode: password\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        // 密码应该被替换为环境变量的值
        assertEquals(envValue, config.getEncryption().getPassword());
    }
    
    @Test
    public void testEnvironmentVariableNotExist() throws IOException {
        // 使用不存在的环境变量
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "encryption:\n" +
                "  password: ${NON_EXISTENT_VAR_12345}\n" +
                "  mode: password\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        // 不存在的环境变量应该保持原样
        assertEquals("${NON_EXISTENT_VAR_12345}", config.getEncryption().getPassword());
    }
    
    @Test
    public void testLoadYamlWithQuotes() throws IOException {
        // 测试带引号的值
        String yaml = "input:\n" +
                "  file: \"app.jar\"\n" +
                "encryption:\n" +
                "  password: 'test123'\n" +
                "  mode: \"password\"\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        // 引号应该被移除
        assertEquals("app.jar", config.getInput().getFile());
        assertEquals("test123", config.getEncryption().getPassword());
        assertEquals("password", config.getEncryption().getMode());
    }
    
    @Test
    public void testLoadYamlWithExclude() throws IOException {
        // 测试 exclude 列表
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "  exclude:\n" +
                "    - com.example.test\n" +
                "    - com.example.debug\n" +
                "encryption:\n" +
                "  password: test123\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        assertNotNull(config.getInput().getExclude());
        assertEquals(2, config.getInput().getExclude().length);
        assertEquals("com.example.test", config.getInput().getExclude()[0]);
        assertEquals("com.example.debug", config.getInput().getExclude()[1]);
    }
    
    @Test
    public void testLoadYamlWithAdvancedConfig() throws IOException {
        // 测试高级配置
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "encryption:\n" +
                "  password: test123\n" +
                "output:\n" +
                "  file: out.jar\n" +
                "  overwrite: true\n" +
                "advanced:\n" +
                "  logLevel: DEBUG\n" +
                "  skipConfirmation: true\n" +
                "  threads: 4\n" +
                "  incremental: true\n" +
                "  cacheFile: .classfinal-cache\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        assertNotNull(config.getAdvanced());
        assertEquals("DEBUG", config.getAdvanced().getLogLevel());
        assertTrue(config.getAdvanced().isSkipConfirmation());
        assertEquals(4, config.getAdvanced().getThreads());
        assertTrue(config.getAdvanced().isIncremental());
        assertEquals(".classfinal-cache", config.getAdvanced().getCacheFile());
        
        assertNotNull(config.getOutput());
        assertTrue(config.getOutput().isOverwrite());
    }
    
    @Test
    public void testLoadYamlWithPasswordFile() throws IOException {
        // 测试密码文件配置
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "encryption:\n" +
                "  passwordFile: /tmp/password.txt\n" +
                "  deletePasswordFile: true\n" +
                "  mode: password\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        assertEquals("/tmp/password.txt", config.getEncryption().getPasswordFile());
        assertTrue(config.getEncryption().isDeletePasswordFile());
    }
    
    @Test
    public void testLoadNonExistentFile() {
        assertThrows(FileNotFoundException.class, () -> {
            ConfigLoader.load("/tmp/non-existent-config-file-12345.yml");
        });
    }
    
    @Test
    public void testLoadUnsupportedFormat() throws IOException {
        String txtFile = "/tmp/test-config.txt";
        Files.write(Paths.get(txtFile), "test".getBytes());
        
        try {
            assertThrows(IllegalArgumentException.class, () -> {
                try {
                    ConfigLoader.load(txtFile);
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            });
        } finally {
            new File(txtFile).delete();
        }
    }
    
    @Test
    public void testGenerateTemplate() throws IOException {
        String templateFile = "/tmp/test-template-" + System.currentTimeMillis() + ".yml";
        
        try {
            ConfigLoader.generateTemplate(templateFile);
            
            // 验证模板文件已创建
            File file = new File(templateFile);
            assertTrue(file.exists());
            assertTrue(file.length() > 0);
            
            // 验证模板内容
            String content = new String(Files.readAllBytes(Paths.get(templateFile)), StandardCharsets.UTF_8);
            assertTrue(content.contains("input:"));
            assertTrue(content.contains("encryption:"));
            assertTrue(content.contains("output:"));
            assertTrue(content.contains("advanced:"));
            assertTrue(content.contains("${CLASSFINAL_PASSWORD}"));
        } finally {
            new File(templateFile).delete();
        }
    }
    
    @Test
    public void testValidation() throws IOException {
        // 测试配置验证（通过 validate 方法）
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "  packages:\n" +
                "    - com.example\n" +
                "encryption:\n" +
                "  password: test123\n" +
                "output:\n" +
                "  file: app-encrypted.jar\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        // 应该能正常验证（不抛异常）
        try {
            config.validate();
        } catch (IllegalArgumentException e) {
            fail("配置验证失败: " + e.getMessage());
        }
    }
    
    @Test
    public void testDefaultValues() throws IOException {
        // 测试默认值（只提供最小必要配置）
        String yaml = "input:\n" +
                "  file: app.jar\n" +
                "encryption:\n" +
                "  password: test123\n";
        
        Files.write(Paths.get(testConfigFile), yaml.getBytes(StandardCharsets.UTF_8));
        
        ClassFinalConfig config = ConfigLoader.load(testConfigFile);
        
        // 检查默认值
        assertNotNull(config.getEncryption());
        assertEquals("password", config.getEncryption().getMode());
        
        assertNotNull(config.getAdvanced());
        assertEquals("INFO", config.getAdvanced().getLogLevel());
        assertEquals(1, config.getAdvanced().getThreads());
    }
}
