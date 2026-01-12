package net.roseboy.classfinal.config;

/**
 * ClassFinal 配置文件模型
 * 
 * 支持从 YAML/JSON 文件加载配置
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class ClassFinalConfig {
    
    private InputConfig input;
    private EncryptionConfig encryption;
    private OutputConfig output;
    private AdvancedConfig advanced;
    
    public static class InputConfig {
        /** 要加密的文件路径 */
        private String file;
        
        /** 要加密的包列表 */
        private String[] packages;
        
        /** 排除的类名列表 */
        private String[] exclude;
        
        /** lib 目录下要加密的 jar 列表 */
        private String[] libjars;
        
        // Getters and Setters
        public String getFile() {
            return file;
        }
        
        public void setFile(String file) {
            this.file = file;
        }
        
        public String[] getPackages() {
            return packages;
        }
        
        public void setPackages(String[] packages) {
            this.packages = packages;
        }
        
        public String[] getExclude() {
            return exclude;
        }
        
        public void setExclude(String[] exclude) {
            this.exclude = exclude;
        }
        
        public String[] getLibjars() {
            return libjars;
        }
        
        public void setLibjars(String[] libjars) {
            this.libjars = libjars;
        }
    }
    
    public static class EncryptionConfig {
        /** 加密密码（支持环境变量 ${VAR_NAME}） */
        private String password;
        
        /** 密码文件路径 */
        private String passwordFile;
        
        /** 加密模式: password | nopassword | machine-binding */
        private String mode = "password";
        
        /** 机器码（用于机器绑定模式） */
        private String machineCode;
        
        /** 密码文件读取后是否自动删除 */
        private boolean deletePasswordFile = false;
        
        // Getters and Setters
        public String getPassword() {
            return password;
        }
        
        public void setPassword(String password) {
            this.password = password;
        }
        
        public String getPasswordFile() {
            return passwordFile;
        }
        
        public void setPasswordFile(String passwordFile) {
            this.passwordFile = passwordFile;
        }
        
        public String getMode() {
            return mode;
        }
        
        public void setMode(String mode) {
            this.mode = mode;
        }
        
        public String getMachineCode() {
            return machineCode;
        }
        
        public void setMachineCode(String machineCode) {
            this.machineCode = machineCode;
        }
        
        public boolean isDeletePasswordFile() {
            return deletePasswordFile;
        }
        
        public void setDeletePasswordFile(boolean deletePasswordFile) {
            this.deletePasswordFile = deletePasswordFile;
        }
    }
    
    public static class OutputConfig {
        /** 输出文件路径 */
        private String file;
        
        /** 是否覆盖已存在的文件 */
        private boolean overwrite = false;
        
        // Getters and Setters
        public String getFile() {
            return file;
        }
        
        public void setFile(String file) {
            this.file = file;
        }
        
        public boolean isOverwrite() {
            return overwrite;
        }
        
        public void setOverwrite(boolean overwrite) {
            this.overwrite = overwrite;
        }
    }
    
    public static class AdvancedConfig {
        /** 日志级别: DEBUG | INFO | WARN | ERROR */
        private String logLevel = "INFO";
        
        /** 是否跳过确认提示 */
        private boolean skipConfirmation = false;
        
        /** 并行加密线程数 */
        private int threads = 1;
        
        /** 是否启用增量加密 */
        private boolean incremental = false;
        
        /** 增量加密缓存文件路径 */
        private String cacheFile;
        
        // Getters and Setters
        public String getLogLevel() {
            return logLevel;
        }
        
        public void setLogLevel(String logLevel) {
            this.logLevel = logLevel;
        }
        
        public boolean isSkipConfirmation() {
            return skipConfirmation;
        }
        
        public void setSkipConfirmation(boolean skipConfirmation) {
            this.skipConfirmation = skipConfirmation;
        }
        
        public int getThreads() {
            return threads;
        }
        
        public void setThreads(int threads) {
            this.threads = threads;
        }
        
        public boolean isIncremental() {
            return incremental;
        }
        
        public void setIncremental(boolean incremental) {
            this.incremental = incremental;
        }
        
        public String getCacheFile() {
            return cacheFile;
        }
        
        public void setCacheFile(String cacheFile) {
            this.cacheFile = cacheFile;
        }
    }
    
    // Main Getters and Setters
    public InputConfig getInput() {
        return input;
    }
    
    public void setInput(InputConfig input) {
        this.input = input;
    }
    
    public EncryptionConfig getEncryption() {
        return encryption;
    }
    
    public void setEncryption(EncryptionConfig encryption) {
        this.encryption = encryption;
    }
    
    public OutputConfig getOutput() {
        return output;
    }
    
    public void setOutput(OutputConfig output) {
        this.output = output;
    }
    
    public AdvancedConfig getAdvanced() {
        return advanced;
    }
    
    public void setAdvanced(AdvancedConfig advanced) {
        this.advanced = advanced;
    }
    
    /**
     * 验证配置有效性
     * 
     * @throws IllegalArgumentException 如果配置无效
     */
    public void validate() {
        if (input == null || input.getFile() == null || input.getFile().isEmpty()) {
            throw new IllegalArgumentException("input.file is required");
        }
        
        if (input.getPackages() == null || input.getPackages().length == 0) {
            throw new IllegalArgumentException("input.packages is required");
        }
        
        if (encryption == null) {
            throw new IllegalArgumentException("encryption config is required");
        }
        
        // 验证加密模式
        if (!"password".equals(encryption.getMode()) 
            && !"nopassword".equals(encryption.getMode())
            && !"machine-binding".equals(encryption.getMode())) {
            throw new IllegalArgumentException(
                "encryption.mode must be one of: password, nopassword, machine-binding");
        }
        
        // 密码模式验证
        if ("password".equals(encryption.getMode())) {
            if (encryption.getPassword() == null && encryption.getPasswordFile() == null) {
                throw new IllegalArgumentException(
                    "encryption.password or encryption.passwordFile is required for password mode");
            }
        }
        
        // 机器绑定模式验证
        if ("machine-binding".equals(encryption.getMode())) {
            if (encryption.getMachineCode() == null || encryption.getMachineCode().isEmpty()) {
                throw new IllegalArgumentException(
                    "encryption.machineCode is required for machine-binding mode");
            }
        }
    }
}
