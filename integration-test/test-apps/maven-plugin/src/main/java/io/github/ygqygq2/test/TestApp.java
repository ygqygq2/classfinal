package io.github.ygqygq2.test;

import com.google.gson.Gson;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

/**
 * 简单的测试应用程序，用于验证 ClassFinal 加密是否正常工作
 * Simple test application to verify ClassFinal encryption works correctly
 */
public class TestApp {
    
    // 密钥常量 - 测试中文注释
    private static final String SECRET_KEY = "这是一个密钥12345";
    // 欢迎消息 - 包含中文字符
    private static final String WELCOME_MESSAGE = "欢迎使用 ClassFinal 测试应用";
    
    public static void main(String[] args) {
        System.out.println("=== ClassFinal 集成测试应用 ===");
        System.out.println("=== ClassFinal Integration Test App ===");
        
        // 测试基本功能
        testBasicOperation();
        
        // 测试类加载和反射
        testReflection();
        
        // 测试依赖jar包 (gson)
        testDependency();
        
        // 测试中文支持
        testChineseSupport();
        
        // 测试配置文件中文
        testConfigWithChinese();
        
        System.out.println("=== 所有测试通过 ===");
        System.out.println("=== All Tests Passed ===");
        System.exit(0);
    }
    
    /**
     * 测试基本操作
     */
    private static void testBasicOperation() {
        System.out.println("\n[测试 1] 基本操作测试");
        System.out.println("[Test 1] Basic Operation Test");
        Calculator calc = new Calculator();
        int result = calc.add(5, 3);
        if (result != 8) {
            throw new RuntimeException("基本操作失败: 期望 8, 得到 " + result);
        }
        System.out.println("✓ 基本操作测试通过");
        System.out.println("✓ Basic operation test passed");
    }
    
    /**
     * 测试反射功能
     */
    private static void testReflection() {
        System.out.println("\n[测试 2] 反射测试");
        System.out.println("[Test 2] Reflection Test");
        try {
            SecretService service = new SecretService();
            String secret = service.getSecret();
            if (!SECRET_KEY.equals(secret)) {
                throw new RuntimeException("反射测试失败: 密钥不匹配");
            }
            System.out.println("✓ 反射测试通过");
            System.out.println("✓ Reflection test passed");
        } catch (Exception e) {
            throw new RuntimeException("反射测试失败", e);
        }
    }
    
    /**
     * 测试依赖库 (Gson)
     */
    private static void testDependency() {
        System.out.println("\n[测试 3] 依赖 (Gson) 测试");
        System.out.println("[Test 3] Dependency (Gson) Test");
        Gson gson = new Gson();
        Map<String, Object> data = new HashMap<>();
        data.put("name", "ClassFinal");
        data.put("中文名称", "类文件加密工具");
        data.put("version", "2.0.0");
        data.put("encrypted", true);
        data.put("描述", "Java类文件加密工具");
        
        String json = gson.toJson(data);
        if (!json.contains("ClassFinal") || !json.contains("类文件加密工具")) {
            throw new RuntimeException("依赖测试失败: gson 不能正常处理中文");
        }
        System.out.println("✓ 依赖测试通过: " + json);
        System.out.println("✓ Dependency test passed");
    }
    
    /**
     * 测试中文字符串支持
     */
    private static void testChineseSupport() {
        System.out.println("\n[测试 4] 中文支持测试");
        System.out.println("[Test 4] Chinese Character Support Test");
        
        // 测试中文字符串常量
        ChineseTextProcessor processor = new ChineseTextProcessor();
        String result = processor.processText("你好，世界！");
        if (!result.equals("处理完成: 你好，世界！")) {
            throw new RuntimeException("中文处理失败: " + result);
        }
        
        // 测试中文方法调用
        String greeting = processor.获取问候语();
        if (!greeting.equals(WELCOME_MESSAGE)) {
            throw new RuntimeException("中文方法名调用失败");
        }
        
        System.out.println("✓ 中文支持测试通过");
        System.out.println("✓ Chinese support test passed");
    }
    
    /**
     * 测试配置文件中的中文
     */
    private static void testConfigWithChinese() {
        System.out.println("\n[测试 5] 配置文件中文测试");
        System.out.println("[Test 5] Config File Chinese Test");
        
        try {
            Properties props = new Properties();
            InputStream input = TestApp.class.getClassLoader()
                .getResourceAsStream("config.properties");
            if (input == null) {
                throw new RuntimeException("配置文件未找到");
            }
            props.load(new InputStreamReader(input, StandardCharsets.UTF_8));
            
            String appName = props.getProperty("app.name.chinese");
            String description = props.getProperty("app.description");
            
            if (!"类文件加密测试".equals(appName)) {
                throw new RuntimeException("配置文件中文读取失败: app.name.chinese = " + appName);
            }
            
            if (!description.contains("支持中文")) {
                throw new RuntimeException("配置文件中文描述读取失败");
            }
            
            System.out.println("✓ 配置文件中文测试通过");
            System.out.println("✓ Config file Chinese test passed");
            System.out.println("  应用名称: " + appName);
            System.out.println("  描述: " + description);
        } catch (Exception e) {
            throw new RuntimeException("配置文件测试失败", e);
        }
    }
    
    /**
     * 计算器类 - 用于基本操作测试
     */
    static class Calculator {
        // 加法运算
        public int add(int a, int b) {
            return a + b;
        }
        
        // 乘法运算
        public int multiply(int a, int b) {
            return a * b;
        }
    }
    
    /**
     * 密钥服务类 - 用于反射测试
     */
    static class SecretService {
        // 获取密钥
        public String getSecret() {
            return SECRET_KEY;
        }
        
        // 验证密钥
        public boolean validateSecret(String input) {
            return SECRET_KEY.equals(input);
        }
    }
    
    /**
     * 中文文本处理器 - 测试中文字符串和中文方法名
     */
    static class ChineseTextProcessor {
        private static final String PREFIX = "处理完成: ";
        
        /**
         * 处理文本
         * @param text 输入文本
         * @return 处理后的文本
         */
        public String processText(String text) {
            return PREFIX + text;
        }
        
        /**
         * 获取问候语 - 中文方法名测试
         * @return 问候消息
         */
        public String 获取问候语() {
            return WELCOME_MESSAGE;
        }
        
        /**
         * 验证是否包含中文
         */
        public boolean 包含中文(String text) {
            return text.matches(".*[\\u4e00-\\u9fa5]+.*");
        }
    }
}
