package net.roseboy.classfinal.util;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ByteCodeAnalyzer 单元测试
 * 测试Lambda表达式检测功能
 */
class ByteCodeAnalyzerTest {

    @Test
    void testContainsLambda_withNullBytes() {
        assertFalse(ByteCodeAnalyzer.containsLambda((byte[]) null));
    }

    @Test
    void testContainsLambda_withEmptyBytes() {
        assertFalse(ByteCodeAnalyzer.containsLambda(new byte[0]));
    }

    @Test
    void testContainsLambda_withInvalidMagicNumber() {
        byte[] invalidClass = new byte[]{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41};
        assertFalse(ByteCodeAnalyzer.containsLambda(invalidClass));
    }

    @Test
    void testContainsLambda_withSimpleClass() {
        // 简单的类，没有Lambda
        // public class Simple { public void test() {} }
        byte[] simpleClass = createSimpleClassBytes();
        assertFalse(ByteCodeAnalyzer.containsLambda(simpleClass));
    }

    @Test
    void testContainsLambda_withLambdaInConstantPool() {
        // 包含"lambda$"字符串的类
        byte[] classWithLambdaName = createClassWithLambdaMethodName();
        assertTrue(ByteCodeAnalyzer.containsLambda(classWithLambdaName));
    }

    @Test
    void testContainsLambda_withBootstrapMethods() {
        // 包含BootstrapMethods属性的类
        byte[] classWithBootstrap = createClassWithBootstrapMethods();
        assertTrue(ByteCodeAnalyzer.containsLambda(classWithBootstrap));
    }

    @Test
    void testContainsLambda_withInvokeDynamic() {
        // 包含InvokeDynamic常量的类（tag=18）
        byte[] classWithInvokeDynamic = createClassWithInvokeDynamic();
        assertTrue(ByteCodeAnalyzer.containsLambda(classWithInvokeDynamic));
    }

    @Test
    void testContainsLambda_withFile(@TempDir Path tempDir) throws Exception {
        // 测试从文件读取
        File testFile = tempDir.resolve("Test.class").toFile();
        try (FileOutputStream fos = new FileOutputStream(testFile)) {
            fos.write(createClassWithLambdaMethodName());
        }
        
        assertTrue(ByteCodeAnalyzer.containsLambda(testFile));
    }

    @Test
    void testContainsLambda_withNonExistentFile() {
        File nonExistent = new File("/tmp/nonexistent.class");
        assertFalse(ByteCodeAnalyzer.containsLambda(nonExistent));
    }

    // ========== 辅助方法：创建测试用的class字节码 ==========

    /**
     * 创建一个简单的类字节码（不包含Lambda）
     * 最小化的有效class文件结构
     */
    private byte[] createSimpleClassBytes() {
        return new byte[]{
            (byte) 0xCA, (byte) 0xFE, (byte) 0xBA, (byte) 0xBE, // magic
            0x00, 0x00,                                         // minor version
            0x00, 0x34,                                         // major version (52 = Java 8)
            0x00, 0x0A,                                         // constant pool count = 10
            // Constant pool entries (简化版)
            0x01, 0x00, 0x06, 'S', 'i', 'm', 'p', 'l', 'e',   // #1 Utf8 "Simple"
            0x07, 0x00, 0x01,                                   // #2 Class #1
            0x01, 0x00, 0x10, 'j', 'a', 'v', 'a', '/', 'l', 'a', 'n', 'g', '/', 'O', 'b', 'j', 'e', 'c', 't', // #3 Utf8 "java/lang/Object"
            0x07, 0x00, 0x03,                                   // #4 Class #3
            0x01, 0x00, 0x06, '<', 'i', 'n', 'i', 't', '>',   // #5 Utf8 "<init>"
            0x01, 0x00, 0x03, '(', ')', 'V',                   // #6 Utf8 "()V"
            0x01, 0x00, 0x04, 'C', 'o', 'd', 'e',              // #7 Utf8 "Code"
            0x0C, 0x00, 0x05, 0x00, 0x06,                      // #8 NameAndType #5 #6
            0x0A, 0x00, 0x04, 0x00, 0x08,                      // #9 Methodref #4 #8
            // 省略其他字段...
        };
    }

    /**
     * 创建包含"lambda$"方法名的类字节码
     */
    private byte[] createClassWithLambdaMethodName() {
        return new byte[]{
            (byte) 0xCA, (byte) 0xFE, (byte) 0xBA, (byte) 0xBE, // magic
            0x00, 0x00,                                         // minor version
            0x00, 0x34,                                         // major version
            0x00, 0x05,                                         // constant pool count = 5
            // #1: Utf8 "lambda$main$0"
            0x01, 0x00, 0x0D, 'l', 'a', 'm', 'b', 'd', 'a', '$', 'm', 'a', 'i', 'n', '$', '0',
            0x01, 0x00, 0x04, 't', 'e', 's', 't',              // #2 Utf8 "test"
            0x01, 0x00, 0x03, '(', ')', 'V',                   // #3 Utf8 "()V"
            0x0C, 0x00, 0x01, 0x00, 0x03,                      // #4 NameAndType #1 #3
        };
    }

    /**
     * 创建包含BootstrapMethods属性名的类字节码
     */
    private byte[] createClassWithBootstrapMethods() {
        return new byte[]{
            (byte) 0xCA, (byte) 0xFE, (byte) 0xBA, (byte) 0xBE,
            0x00, 0x00,
            0x00, 0x34,
            0x00, 0x04,
            // #1: Utf8 "BootstrapMethods"
            0x01, 0x00, 0x10, 'B', 'o', 'o', 't', 's', 't', 'r', 'a', 'p', 'M', 'e', 't', 'h', 'o', 'd', 's',
            0x01, 0x00, 0x04, 't', 'e', 's', 't',
            0x01, 0x00, 0x03, '(', ')', 'V',
        };
    }

    /**
     * 创建包含InvokeDynamic常量的类字节码
     */
    private byte[] createClassWithInvokeDynamic() {
        return new byte[]{
            (byte) 0xCA, (byte) 0xFE, (byte) 0xBA, (byte) 0xBE,
            0x00, 0x00,
            0x00, 0x34,
            0x00, 0x06,
            0x01, 0x00, 0x04, 't', 'e', 's', 't',              // #1 Utf8 "test"
            0x01, 0x00, 0x03, '(', ')', 'V',                   // #2 Utf8 "()V"
            0x0C, 0x00, 0x01, 0x00, 0x02,                      // #3 NameAndType #1 #2
            // #4: InvokeDynamic (tag=18)
            0x12,                                               // tag = 18 (CONSTANT_InvokeDynamic)
            0x00, 0x00,                                         // bootstrap_method_attr_index
            0x00, 0x03,                                         // name_and_type_index
            0x01, 0x00, 0x04, 'd', 'u', 'm', 'm', 'y',        // #5 Utf8 "dummy"
        };
    }
}
