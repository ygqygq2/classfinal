package net.roseboy.classfinal.util;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

/**
 * 密码管理工具
 * 
 * 支持从文件、环境变量等多种方式读取密码
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class PasswordUtil {
    
    /**
     * 从文件读取密码
     * 
     * @param passwordFile 密码文件路径
     * @param deleteAfterRead 读取后是否删除文件
     * @return 密码
     * @throws IOException 读取失败
     */
    public static String readPasswordFromFile(String passwordFile, boolean deleteAfterRead) 
            throws IOException {
        File file = new File(passwordFile);
        
        if (!file.exists()) {
            throw new IOException("密码文件不存在: " + passwordFile);
        }
        
        if (!file.canRead()) {
            throw new IOException("密码文件无读取权限: " + passwordFile);
        }
        
        // 读取密码（去除首尾空白）
        String password = new String(Files.readAllBytes(Paths.get(passwordFile)), 
                StandardCharsets.UTF_8).trim();
        
        // 删除文件
        if (deleteAfterRead) {
            boolean deleted = file.delete();
            if (!deleted) {
                System.err.println("警告: 无法删除密码文件: " + passwordFile);
            }
        }
        
        return password;
    }
    
    /**
     * 从环境变量读取密码
     * 
     * @param envName 环境变量名
     * @return 密码，如果环境变量不存在返回 null
     */
    public static String readPasswordFromEnv(String envName) {
        return System.getenv(envName);
    }
    
    /**
     * 检查密码强度
     * 
     * @param password 密码
     * @return 强度等级：0=弱，1=中，2=强
     */
    public static int checkPasswordStrength(String password) {
        if (password == null || password.isEmpty()) {
            return 0;
        }
        
        int score = 0;
        
        // 长度检查
        if (password.length() >= 8) score++;
        if (password.length() >= 12) score++;
        
        // 复杂度检查
        if (password.matches(".*[a-z].*")) score++; // 小写字母
        if (password.matches(".*[A-Z].*")) score++; // 大写字母
        if (password.matches(".*[0-9].*")) score++; // 数字
        if (password.matches(".*[^a-zA-Z0-9].*")) score++; // 特殊字符
        
        // 分数映射到等级
        if (score <= 2) return 0; // 弱
        if (score <= 4) return 1; // 中
        return 2; // 强
    }
    
    /**
     * 获取密码强度描述
     * 
     * @param password 密码
     * @return 强度描述
     */
    public static String getPasswordStrengthDescription(String password) {
        int strength = checkPasswordStrength(password);
        switch (strength) {
            case 0: return "弱 (建议使用更复杂的密码)";
            case 1: return "中等";
            case 2: return "强";
            default: return "未知";
        }
    }
    
    /**
     * 验证密码是否符合最低要求
     * 
     * @param password 密码
     * @return 是否符合要求
     */
    public static boolean validatePassword(String password) {
        if (password == null || password.isEmpty()) {
            return false;
        }
        
        // 最低要求：至少 6 位
        return password.length() >= 6;
    }
}
