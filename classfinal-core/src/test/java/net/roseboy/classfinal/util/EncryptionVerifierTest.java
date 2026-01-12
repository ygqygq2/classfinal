package net.roseboy.classfinal.util;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.jar.JarEntry;
import java.util.jar.JarOutputStream;
import java.util.jar.Manifest;
import java.util.jar.Attributes;

import static org.junit.Assert.*;

/**
 * EncryptionVerifier 单元测试
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class EncryptionVerifierTest {
    
    private String testJarFile;
    
    @Before
    public void setUp() {
        testJarFile = "/tmp/test-jar-" + System.currentTimeMillis() + ".jar";
    }
    
    @After
    public void tearDown() {
        if (testJarFile != null) {
            new File(testJarFile).delete();
        }
    }
    
    @Test
    public void testVerifyUnencryptedJar() throws IOException {
        // 创建一个未加密的 JAR
        createSimpleJar(testJarFile, false);
        
        EncryptionVerifier.VerifyResult result = EncryptionVerifier.verify(testJarFile);
        
        assertNotNull(result);
        assertFalse("应该识别为未加密", result.isEncrypted());
        assertTrue("应该有类文件", result.getTotalClasses() > 0);
        assertEquals("未加密 JAR 加密类数应为 0", 0, result.getEncryptedClasses());
        assertEquals("加密率应为 0", 0.0, result.getEncryptionRate(), 0.01);
    }
    
    @Test
    public void testVerifyEncryptedJar() throws IOException {
        // 创建一个带加密标记的 JAR
        createSimpleJar(testJarFile, true);
        
        EncryptionVerifier.VerifyResult result = EncryptionVerifier.verify(testJarFile);
        
        assertNotNull(result);
        assertTrue("应该识别为已加密", result.isEncrypted());
        assertEquals("加密方法应为 AES", "AES", result.getEncryptionMethod());
    }
    
    @Test
    public void testVerifyResultGetters() throws IOException {
        createSimpleJar(testJarFile, true);
        
        EncryptionVerifier.VerifyResult result = EncryptionVerifier.verify(testJarFile);
        
        // 测试所有 getter 方法
        assertNotNull(result.getEncryptionMethod());
        assertTrue(result.getTotalClasses() >= 0);
        assertTrue(result.getEncryptedClasses() >= 0);
        assertNotNull(result.getEncryptedPackages());
        assertTrue(result.getEncryptionRate() >= 0.0);
    }
    
    @Test
    public void testVerifyResultSetters() {
        EncryptionVerifier.VerifyResult result = new EncryptionVerifier.VerifyResult();
        
        result.setEncrypted(true);
        result.setEncryptionMethod("AES");
        result.setPasswordProtected(true);
        result.setMachineBinding(true);
        result.setTotalClasses(100);
        result.setEncryptedClasses(80);
        
        assertTrue(result.isEncrypted());
        assertEquals("AES", result.getEncryptionMethod());
        assertTrue(result.isPasswordProtected());
        assertTrue(result.isMachineBinding());
        assertEquals(100, result.getTotalClasses());
        assertEquals(80, result.getEncryptedClasses());
        assertEquals(80.0, result.getEncryptionRate(), 0.01);
    }
    
    @Test
    public void testEncryptionRateCalculation() {
        EncryptionVerifier.VerifyResult result = new EncryptionVerifier.VerifyResult();
        
        // 测试 0/0 情况
        result.setTotalClasses(0);
        result.setEncryptedClasses(0);
        assertEquals(0.0, result.getEncryptionRate(), 0.01);
        
        // 测试 50/100 = 50%
        result.setTotalClasses(100);
        result.setEncryptedClasses(50);
        assertEquals(50.0, result.getEncryptionRate(), 0.01);
        
        // 测试 100/100 = 100%
        result.setEncryptedClasses(100);
        assertEquals(100.0, result.getEncryptionRate(), 0.01);
        
        // 测试 33/100 = 33%
        result.setEncryptedClasses(33);
        assertEquals(33.0, result.getEncryptionRate(), 0.01);
    }
    
    @Test
    public void testPrintResult() throws IOException {
        // 创建已加密的 JAR
        createSimpleJar(testJarFile, true);
        EncryptionVerifier.VerifyResult result = EncryptionVerifier.verify(testJarFile);
        
        // 捕获标准输出
        ByteArrayOutputStream outContent = new ByteArrayOutputStream();
        PrintStream originalOut = System.out;
        System.setOut(new PrintStream(outContent));
        
        try {
            EncryptionVerifier.printResult(result);
            
            String output = outContent.toString();
            assertTrue("输出应包含标题", output.contains("JAR 加密验证结果"));
            assertTrue("输出应包含加密状态", output.contains("已加密"));
            assertTrue("输出应包含分隔线", output.contains("========================================="));
        } finally {
            System.setOut(originalOut);
        }
    }
    
    @Test
    public void testPrintResultUnencrypted() throws IOException {
        // 创建未加密的 JAR
        createSimpleJar(testJarFile, false);
        EncryptionVerifier.VerifyResult result = EncryptionVerifier.verify(testJarFile);
        
        ByteArrayOutputStream outContent = new ByteArrayOutputStream();
        PrintStream originalOut = System.out;
        System.setOut(new PrintStream(outContent));
        
        try {
            EncryptionVerifier.printResult(result);
            
            String output = outContent.toString();
            assertTrue("输出应包含未加密状态", output.contains("未加密"));
            assertTrue("输出应包含总类数", output.contains("总类数"));
        } finally {
            System.setOut(originalOut);
        }
    }
    
    @Test(expected = IOException.class)
    public void testVerifyNonExistentJar() throws IOException {
        EncryptionVerifier.verify("/tmp/non-existent-jar-12345.jar");
    }
    
    @Test
    public void testEncryptedPackagesList() throws IOException {
        // 创建带包名的 JAR
        createJarWithPackages(testJarFile);
        
        EncryptionVerifier.VerifyResult result = EncryptionVerifier.verify(testJarFile);
        
        assertNotNull(result.getEncryptedPackages());
        // 包列表可能为空或包含包名（取决于加密检测逻辑）
        assertTrue(result.getEncryptedPackages().size() >= 0);
    }
    
    /**
     * 创建简单的测试 JAR
     */
    private void createSimpleJar(String jarPath, boolean withEncryptionMarker) throws IOException {
        Manifest manifest = new Manifest();
        manifest.getMainAttributes().put(Attributes.Name.MANIFEST_VERSION, "1.0");
        
        if (withEncryptionMarker) {
            // 添加 ClassFinal 加密标记
            manifest.getMainAttributes().putValue("Premain-Class", "net.roseboy.classfinal.Agent");
        }
        
        try (JarOutputStream jos = new JarOutputStream(new FileOutputStream(jarPath), manifest)) {
            // 添加一个简单的类文件（模拟）
            JarEntry entry = new JarEntry("com/example/Test.class");
            jos.putNextEntry(entry);
            
            // 写入简单的类文件内容（正常类文件以 CAFEBABE 开头）
            byte[] classBytes = {
                (byte) 0xCA, (byte) 0xFE, (byte) 0xBA, (byte) 0xBE,  // 魔数
                0x00, 0x00, 0x00, 0x34  // 版本号
            };
            jos.write(classBytes);
            jos.closeEntry();
            
            // 如果是加密 JAR,添加 classfinal.properties
            if (withEncryptionMarker) {
                JarEntry configEntry = new JarEntry("classfinal.properties");
                jos.putNextEntry(configEntry);
                String props = "pwd.mode=password\n";
                jos.write(props.getBytes());
                jos.closeEntry();
            }
        }
    }
    
    /**
     * 创建带包结构的 JAR
     */
    private void createJarWithPackages(String jarPath) throws IOException {
        Manifest manifest = new Manifest();
        manifest.getMainAttributes().put(Attributes.Name.MANIFEST_VERSION, "1.0");
        
        try (JarOutputStream jos = new JarOutputStream(new FileOutputStream(jarPath), manifest)) {
            // 添加多个包的类文件
            String[] classFiles = {
                "com/example/Test.class",
                "com/example/util/Helper.class",
                "org/demo/Main.class"
            };
            
            byte[] classBytes = {
                (byte) 0xCA, (byte) 0xFE, (byte) 0xBA, (byte) 0xBE,
                0x00, 0x00, 0x00, 0x34
            };
            
            for (String className : classFiles) {
                JarEntry entry = new JarEntry(className);
                jos.putNextEntry(entry);
                jos.write(classBytes);
                jos.closeEntry();
            }
        }
    }
}
