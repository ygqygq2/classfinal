package net.roseboy.classfinal.config;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.Stack;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 配置文件加载器
 * 
 * 支持 YAML 和 JSON 格式
 * 支持环境变量占位符 ${VAR_NAME}
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class ConfigLoader {
    
    private static final Pattern ENV_PATTERN = Pattern.compile("\\$\\{([^}]+)\\}");
    
    /**
     * 从文件加载配置
     * 
     * @param configPath 配置文件路径
     * @return 配置对象
     * @throws IOException 读取文件失败
     */
    public static ClassFinalConfig load(String configPath) throws IOException {
        File configFile = new File(configPath);
        if (!configFile.exists()) {
            throw new FileNotFoundException("配置文件不存在: " + configPath);
        }
        
        String content = new String(Files.readAllBytes(Paths.get(configPath)), StandardCharsets.UTF_8);
        
        // 替换环境变量占位符
        content = replaceEnvVariables(content);
        
        // 根据文件扩展名选择解析器
        if (configPath.endsWith(".yml") || configPath.endsWith(".yaml")) {
            return parseYaml(content);
        } else if (configPath.endsWith(".json")) {
            return parseJson(content);
        } else {
            throw new IllegalArgumentException("不支持的配置文件格式，仅支持 .yml, .yaml, .json");
        }
    }
    
    /**
     * 替换配置内容中的环境变量占位符
     * 
     * @param content 原始内容
     * @return 替换后的内容
     */
    private static String replaceEnvVariables(String content) {
        Matcher matcher = ENV_PATTERN.matcher(content);
        StringBuffer sb = new StringBuffer();
        
        while (matcher.find()) {
            String varName = matcher.group(1);
            String varValue = System.getenv(varName);
            
            if (varValue == null) {
                // 环境变量不存在，保持原样
                matcher.appendReplacement(sb, Matcher.quoteReplacement(matcher.group(0)));
            } else {
                // 替换为环境变量值
                matcher.appendReplacement(sb, Matcher.quoteReplacement(varValue));
            }
        }
        matcher.appendTail(sb);
        
        return sb.toString();
    }
    
    /**
     * 解析 YAML 格式配置
     * 
     * 支持多级嵌套的 YAML 语法
     * 
     * @param content YAML 内容
     * @return 配置对象
     */
    private static ClassFinalConfig parseYaml(String content) {
        ClassFinalConfig config = new ClassFinalConfig();
        Map<String, String> flatMap = new HashMap<>();
        
        String[] lines = content.split("\n");
        Stack<String> sectionStack = new Stack<>();
        
        for (String rawLine : lines) {
            String trimmed = rawLine.trim();
            
            // 跳过注释和空行
            if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                continue;
            }
            
            // 计算缩进级别
            int indent = getIndentLevel(rawLine);
            
            // 根据缩进调整section stack
            while (!sectionStack.isEmpty() && sectionStack.size() > indent / 2 + 1) {
                sectionStack.pop();
            }
            
            // 处理列表项
            if (trimmed.startsWith("- ")) {
                String value = trimmed.substring(2).trim();
                value = removeQuotes(value);
                
                String currentPath = buildPath(sectionStack);
                String listKey = currentPath + "[]";
                String existing = flatMap.get(listKey);
                flatMap.put(listKey, existing == null ? value : existing + "," + value);
                continue;
            }
            
            // 处理键值对
            if (trimmed.contains(":")) {
                String[] parts = trimmed.split(":", 2);
                if (parts.length == 2) {
                    String key = parts[0].trim();
                    String value = parts[1].trim();
                    
                    // 调整 stack 到当前缩进级别
                    while (sectionStack.size() > indent / 2) {
                        sectionStack.pop();
                    }
                    
                    // 如果值为空，说明这是一个section
                    if (value.isEmpty()) {
                        sectionStack.push(key);
                    } else {
                        // 有值的键值对
                        value = removeQuotes(value);
                        
                        // 替换环境变量
                        value = replaceEnvVars(value);
                        
                        String fullKey = buildPath(sectionStack);
                        fullKey = fullKey.isEmpty() ? key : fullKey + "." + key;
                        flatMap.put(fullKey, value);
                    }
                }
            }
        }
        
        // 构建配置对象
        buildConfigFromMap(config, flatMap);
        
        return config;
    }
    
    /**
     * 计算行的缩进级别（空格数）
     */
    private static int getIndentLevel(String line) {
        int count = 0;
        for (char c : line.toCharArray()) {
            if (c == ' ') {
                count++;
            } else {
                break;
            }
        }
        return count;
    }
    
    /**
     * 移除字符串两端的引号
     */
    private static String removeQuotes(String value) {
        if ((value.startsWith("\"") && value.endsWith("\"")) ||
            (value.startsWith("'") && value.endsWith("'"))) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }
    
    /**
     * 从section stack构建路径
     */
    private static String buildPath(Stack<String> stack) {
        if (stack.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < stack.size(); i++) {
            if (i > 0) sb.append(".");
            sb.append(stack.get(i));
        }
        return sb.toString();
    }
    
    /**     * 替换环境变量占位符 ${VAR_NAME}
     * 
     * @param value 原始值
     * @return 替换后的值，如果环境变量不存在则保持原样
     */
    private static String replaceEnvVars(String value) {
        if (value == null || !value.contains("${")) {
            return value;
        }
        
        Matcher matcher = ENV_PATTERN.matcher(value);
        StringBuffer result = new StringBuffer();
        
        while (matcher.find()) {
            String envVar = matcher.group(1);
            String envValue = System.getenv(envVar);
            // 如果环境变量不存在，保持原占位符
            matcher.appendReplacement(result, 
                envValue != null ? Matcher.quoteReplacement(envValue) : Matcher.quoteReplacement(matcher.group(0)));
        }
        matcher.appendTail(result);
        
        return result.toString();
    }
    
    /**     * 解析 JSON 格式配置
     * 
     * 简单实现，仅支持基本的 JSON 语法
     * 
     * @param content JSON 内容
     * @return 配置对象
     */
    private static ClassFinalConfig parseJson(String content) {
        // TODO: 实现 JSON 解析（可选功能，优先支持 YAML）
        throw new UnsupportedOperationException("JSON 配置格式将在后续版本支持");
    }
    
    /**
     * 从扁平化的 Map 构建配置对象
     */
    private static void buildConfigFromMap(ClassFinalConfig config, Map<String, String> map) {
        // Input 配置
        ClassFinalConfig.InputConfig input = new ClassFinalConfig.InputConfig();
        input.setFile(map.get("input.file"));
        
        String packages = map.get("input.packages[]");
        if (packages != null) {
            input.setPackages(packages.split(","));
        }
        
        String exclude = map.get("input.exclude[]");
        if (exclude != null) {
            input.setExclude(exclude.split(","));
        }
        
        String libjars = map.get("input.libjars[]");
        if (libjars != null) {
            input.setLibjars(libjars.split(","));
        }
        
        config.setInput(input);
        
        // Encryption 配置
        ClassFinalConfig.EncryptionConfig encryption = new ClassFinalConfig.EncryptionConfig();
        encryption.setPassword(map.get("encryption.password"));
        encryption.setPasswordFile(map.get("encryption.passwordFile"));
        encryption.setMode(map.getOrDefault("encryption.mode", "password"));
        encryption.setMachineCode(map.get("encryption.machineCode"));
        
        String deletePasswordFile = map.get("encryption.deletePasswordFile");
        if (deletePasswordFile != null) {
            encryption.setDeletePasswordFile(Boolean.parseBoolean(deletePasswordFile));
        }
        
        config.setEncryption(encryption);
        
        // Output 配置
        ClassFinalConfig.OutputConfig output = new ClassFinalConfig.OutputConfig();
        output.setFile(map.get("output.file"));
        
        String overwrite = map.get("output.overwrite");
        if (overwrite != null) {
            output.setOverwrite(Boolean.parseBoolean(overwrite));
        }
        
        config.setOutput(output);
        
        // Advanced 配置
        ClassFinalConfig.AdvancedConfig advanced = new ClassFinalConfig.AdvancedConfig();
        advanced.setLogLevel(map.getOrDefault("advanced.logLevel", "INFO"));
        
        String skipConfirmation = map.get("advanced.skipConfirmation");
        if (skipConfirmation != null) {
            advanced.setSkipConfirmation(Boolean.parseBoolean(skipConfirmation));
        }
        
        String threads = map.get("advanced.threads");
        if (threads != null) {
            advanced.setThreads(Integer.parseInt(threads));
        }
        
        String incremental = map.get("advanced.incremental");
        if (incremental != null) {
            advanced.setIncremental(Boolean.parseBoolean(incremental));
        }
        
        advanced.setCacheFile(map.get("advanced.cacheFile"));
        
        config.setAdvanced(advanced);
    }
    
    /**
     * 生成配置文件模板
     * 
     * @param outputPath 输出路径
     * @throws IOException 写入失败
     */
    public static void generateTemplate(String outputPath) throws IOException {
        String template = "# ClassFinal 配置文件\n" +
                "# 使用此文件可以避免在命令行暴露敏感信息\n\n" +
                "input:\n" +
                "  file: app.jar\n" +
                "  packages:\n" +
                "    - com.example\n" +
                "  exclude:\n" +
                "    - com.example.test\n" +
                "  libjars:\n" +
                "    - lib-a.jar\n\n" +
                "encryption:\n" +
                "  password: ${CLASSFINAL_PASSWORD}\n" +
                "  mode: password\n\n" +
                "output:\n" +
                "  file: app-encrypted.jar\n" +
                "  overwrite: false\n\n" +
                "advanced:\n" +
                "  logLevel: INFO\n" +
                "  skipConfirmation: false\n" +
                "  threads: 1\n";
        
        Files.write(Paths.get(outputPath), template.getBytes(StandardCharsets.UTF_8));
    }
}
