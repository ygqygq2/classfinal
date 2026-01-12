package net.roseboy.classfinal.util;

import java.io.*;
import java.util.*;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.jar.Manifest;

/**
 * JAR 加密验证工具
 * 
 * 用于验证 JAR 是否已加密，显示加密信息
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class EncryptionVerifier {
    
    /**
     * 验证结果
     */
    public static class VerifyResult {
        private boolean encrypted;
        private String encryptionMethod;
        private boolean passwordProtected;
        private boolean machineBinding;
        private int totalClasses;
        private int encryptedClasses;
        private List<String> encryptedPackages;
        
        public VerifyResult() {
            this.encryptedPackages = new ArrayList<>();
        }
        
        public boolean isEncrypted() {
            return encrypted;
        }
        
        public void setEncrypted(boolean encrypted) {
            this.encrypted = encrypted;
        }
        
        public String getEncryptionMethod() {
            return encryptionMethod;
        }
        
        public void setEncryptionMethod(String encryptionMethod) {
            this.encryptionMethod = encryptionMethod;
        }
        
        public boolean isPasswordProtected() {
            return passwordProtected;
        }
        
        public void setPasswordProtected(boolean passwordProtected) {
            this.passwordProtected = passwordProtected;
        }
        
        public boolean isMachineBinding() {
            return machineBinding;
        }
        
        public void setMachineBinding(boolean machineBinding) {
            this.machineBinding = machineBinding;
        }
        
        public int getTotalClasses() {
            return totalClasses;
        }
        
        public void setTotalClasses(int totalClasses) {
            this.totalClasses = totalClasses;
        }
        
        public int getEncryptedClasses() {
            return encryptedClasses;
        }
        
        public void setEncryptedClasses(int encryptedClasses) {
            this.encryptedClasses = encryptedClasses;
        }
        
        public List<String> getEncryptedPackages() {
            return encryptedPackages;
        }
        
        public void setEncryptedPackages(List<String> encryptedPackages) {
            this.encryptedPackages = encryptedPackages;
        }
        
        public double getEncryptionRate() {
            if (totalClasses == 0) return 0.0;
            return (double) encryptedClasses / totalClasses * 100;
        }
    }
    
    /**
     * 验证 JAR 文件是否已加密
     * 
     * @param jarPath JAR 文件路径
     * @return 验证结果
     * @throws IOException 读取失败
     */
    public static VerifyResult verify(String jarPath) throws IOException {
        VerifyResult result = new VerifyResult();
        
        try (JarFile jarFile = new JarFile(jarPath)) {
            // 检查 MANIFEST.MF
            Manifest manifest = jarFile.getManifest();
            if (manifest != null) {
                String premainClass = manifest.getMainAttributes().getValue("Premain-Class");
                if (premainClass != null && premainClass.contains("classfinal")) {
                    result.setEncrypted(true);
                    result.setEncryptionMethod("AES");
                }
            }
            
            // 扫描 class 文件
            Set<String> packages = new HashSet<>();
            int totalClasses = 0;
            int encryptedClasses = 0;
            
            Enumeration<JarEntry> entries = jarFile.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                String name = entry.getName();
                
                if (name.endsWith(".class")) {
                    totalClasses++;
                    
                    // 检查是否是加密的类（通过文件大小和特征判断）
                    if (isEncryptedClass(jarFile, entry)) {
                        encryptedClasses++;
                        
                        // 提取包名
                        String packageName = extractPackageName(name);
                        if (packageName != null) {
                            packages.add(packageName);
                        }
                    }
                }
            }
            
            result.setTotalClasses(totalClasses);
            result.setEncryptedClasses(encryptedClasses);
            result.setEncryptedPackages(new ArrayList<>(packages));
            
            // 如果有加密的类，标记为已加密
            if (encryptedClasses > 0) {
                result.setEncrypted(true);
            }
            
            // 检查是否需要密码（通过检查特定的配置文件）
            JarEntry configEntry = jarFile.getJarEntry("classfinal.properties");
            if (configEntry != null) {
                try (InputStream is = jarFile.getInputStream(configEntry)) {
                    Properties props = new Properties();
                    props.load(is);
                    
                    String pwdMode = props.getProperty("pwd.mode");
                    result.setPasswordProtected(!"nopwd".equals(pwdMode));
                    result.setMachineBinding("machine".equals(pwdMode));
                }
            }
        }
        
        return result;
    }
    
    /**
     * 检查类文件是否已加密
     * 
     * 简单实现：检查类文件是否包含特定标记
     */
    private static boolean isEncryptedClass(JarFile jarFile, JarEntry entry) throws IOException {
        try (InputStream is = jarFile.getInputStream(entry)) {
            byte[] bytes = new byte[Math.min(1024, (int) entry.getSize())];
            int read = is.read(bytes);
            
            if (read > 0) {
                // 检查是否包含 ClassFinal 特征标记
                // 正常 class 文件以 CAFEBABE 开头
                // 加密后的文件会有不同的特征
                String content = new String(bytes, 0, read);
                return content.contains("classfinal") || !content.startsWith("ÊþºÞ");
            }
        }
        return false;
    }
    
    /**
     * 从类文件路径提取包名
     */
    private static String extractPackageName(String className) {
        if (className.contains("/")) {
            int lastSlash = className.lastIndexOf('/');
            String packagePath = className.substring(0, lastSlash);
            
            // 只返回顶级包
            int firstSlash = packagePath.indexOf('/');
            if (firstSlash > 0) {
                return packagePath.substring(0, firstSlash).replace('/', '.');
            }
            return packagePath.replace('/', '.');
        }
        return null;
    }
    
    /**
     * 打印验证结果
     */
    public static void printResult(VerifyResult result) {
        System.out.println("=========================================");
        System.out.println("  JAR 加密验证结果");
        System.out.println("=========================================");
        System.out.println();
        
        if (result.isEncrypted()) {
            System.out.println("✓ 状态: 已加密");
            System.out.println("✓ 加密方法: " + result.getEncryptionMethod());
            System.out.println("✓ 密码保护: " + (result.isPasswordProtected() ? "是" : "否"));
            System.out.println("✓ 机器绑定: " + (result.isMachineBinding() ? "是" : "否"));
            System.out.println();
            System.out.println("加密统计:");
            System.out.println("  总类数: " + result.getTotalClasses());
            System.out.println("  已加密: " + result.getEncryptedClasses());
            System.out.println("  加密率: " + String.format("%.1f%%", result.getEncryptionRate()));
            
            if (!result.getEncryptedPackages().isEmpty()) {
                System.out.println();
                System.out.println("已加密的包:");
                for (String pkg : result.getEncryptedPackages()) {
                    System.out.println("  - " + pkg);
                }
            }
        } else {
            System.out.println("✗ 状态: 未加密");
            System.out.println();
            System.out.println("统计:");
            System.out.println("  总类数: " + result.getTotalClasses());
        }
        
        System.out.println();
        System.out.println("=========================================");
    }
}
