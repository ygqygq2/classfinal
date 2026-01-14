package net.roseboy.classfinal.util;

import org.junit.jupiter.api.Test;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.*;

/**
 * PasswordUtil 单元测试
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class PasswordUtilTest {
    
    @Test
    public void testReadPasswordFromFile() throws IOException {
        // 创建临时密码文件
        String tempFile = "/tmp/test-password-" + System.currentTimeMillis() + ".txt";
        String password = "test123456";
        Files.write(Paths.get(tempFile), password.getBytes());
        
        try {
            // 测试读取密码
            String result = PasswordUtil.readPasswordFromFile(tempFile, false);
            assertEquals(password, result);
            
            // 文件应该还存在
            assertTrue(new File(tempFile).exists());
        } finally {
            // 清理
            new File(tempFile).delete();
        }
    }
    
    @Test
    public void testReadPasswordFromFileWithDelete() throws IOException {
        // 创建临时密码文件
        String tempFile = "/tmp/test-password-delete-" + System.currentTimeMillis() + ".txt";
        String password = "test123456";
        Files.write(Paths.get(tempFile), password.getBytes());
        
        // 测试读取密码并删除
        String result = PasswordUtil.readPasswordFromFile(tempFile, true);
        assertEquals(password, result);
        
        // 文件应该被删除
        assertFalse(new File(tempFile).exists());
    }
    
    @Test
    public void testReadPasswordFromFileWithWhitespace() throws IOException {
        // 创建带空白符的密码文件
        String tempFile = "/tmp/test-password-ws-" + System.currentTimeMillis() + ".txt";
        String password = "  test123456  \n";
        Files.write(Paths.get(tempFile), password.getBytes());
        
        try {
            // 测试读取密码（应该去除空白）
            String result = PasswordUtil.readPasswordFromFile(tempFile, false);
            assertEquals("test123456", result);
        } finally {
            new File(tempFile).delete();
        }
    }
    
    @Test
    public void testReadPasswordFromNonExistentFile() {
        assertThrows(IOException.class, () -> {
            PasswordUtil.readPasswordFromFile("/tmp/non-existent-file.txt", false);
        });
    }
    
    @Test
    public void testReadPasswordFromEnv() {
        // 设置环境变量（注意：这个测试依赖于环境变量）
        String result = PasswordUtil.readPasswordFromEnv("PATH");
        assertNotNull(result); // PATH 环境变量应该存在
        
        // 测试不存在的环境变量
        String result2 = PasswordUtil.readPasswordFromEnv("NON_EXISTENT_VAR_12345");
        assertNull(result2);
    }
    
    @Test
    public void testCheckPasswordStrength() {
        // 测试弱密码
        assertEquals(0, PasswordUtil.checkPasswordStrength("123"));
        assertEquals(0, PasswordUtil.checkPasswordStrength("abc"));
        assertEquals(0, PasswordUtil.checkPasswordStrength("12345"));
        
        // 测试中等密码
        assertEquals(1, PasswordUtil.checkPasswordStrength("abcd1234"));
        assertEquals(1, PasswordUtil.checkPasswordStrength("Password"));
        
        // 测试强密码
        assertEquals(2, PasswordUtil.checkPasswordStrength("Abcd1234@!"));
        assertEquals(2, PasswordUtil.checkPasswordStrength("MyP@ssw0rd123"));
    }
    
    @Test
    public void testGetPasswordStrengthDescription() {
        assertTrue(PasswordUtil.getPasswordStrengthDescription("123").contains("弱"));
        assertTrue(PasswordUtil.getPasswordStrengthDescription("abcd1234").contains("中等"));
        assertTrue(PasswordUtil.getPasswordStrengthDescription("Abcd1234@!").contains("强"));
    }
    
    @Test
    public void testValidatePassword() {
        // 测试无效密码
        assertFalse(PasswordUtil.validatePassword(null));
        assertFalse(PasswordUtil.validatePassword(""));
        assertFalse(PasswordUtil.validatePassword("12345")); // 少于6位
        
        // 测试有效密码
        assertTrue(PasswordUtil.validatePassword("123456"));
        assertTrue(PasswordUtil.validatePassword("abcdef"));
        assertTrue(PasswordUtil.validatePassword("MyPassword123"));
    }
}
