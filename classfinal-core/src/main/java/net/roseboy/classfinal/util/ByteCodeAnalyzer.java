package net.roseboy.classfinal.util;

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.IOException;

/**
 * 字节码分析工具
 * 用于检测类文件是否包含特定的字节码特征（如Lambda表达式）
 * 
 * Lambda表达式在Java 8+中通过invokedynamic指令实现，编译后会：
 * 1. 在常量池中添加CONSTANT_InvokeDynamic项
 * 2. 生成合成方法，方法名以"lambda$"开头
 * 3. 添加BootstrapMethods属性
 *
 * @author roseboy
 */
public class ByteCodeAnalyzer {
    
    // 常量池标签（基于JVM规范）
    private static final int CONSTANT_Utf8 = 1;
    private static final int CONSTANT_Integer = 3;
    private static final int CONSTANT_Float = 4;
    private static final int CONSTANT_Long = 5;
    private static final int CONSTANT_Double = 6;
    private static final int CONSTANT_Class = 7;
    private static final int CONSTANT_String = 8;
    private static final int CONSTANT_Fieldref = 9;
    private static final int CONSTANT_Methodref = 10;
    private static final int CONSTANT_InterfaceMethodref = 11;
    private static final int CONSTANT_NameAndType = 12;
    private static final int CONSTANT_MethodHandle = 15;
    private static final int CONSTANT_MethodType = 16;
    private static final int CONSTANT_InvokeDynamic = 18;

    /**
     * 检测类文件是否包含Lambda表达式或invokedynamic指令
     * 
     * 检测策略：
     * 1. 检查常量池中是否有CONSTANT_InvokeDynamic项（最可靠）
     * 2. 检查是否有"lambda$"开头的方法名（兜底）
     * 3. 检查是否有BootstrapMethods属性（辅助）
     * 
     * @param classBytes 类文件字节码
     * @return true表示包含Lambda/invokedynamic，false表示不包含
     */
    public static boolean containsLambda(byte[] classBytes) {
        if (classBytes == null || classBytes.length < 10) {
            return false;
        }
        
        try (DataInputStream dis = new DataInputStream(new ByteArrayInputStream(classBytes))) {
            // 检查魔数 0xCAFEBABE
            int magic = dis.readInt();
            if (magic != 0xCAFEBABE) {
                return false;
            }
            
            // 跳过版本号
            dis.skipBytes(4); // minor_version + major_version
            
            // 读取常量池大小
            int constantPoolCount = dis.readUnsignedShort();
            
            // 扫描常量池，查找 InvokeDynamic 或 Lambda 特征
            for (int i = 1; i < constantPoolCount; i++) {
                int tag = dis.readUnsignedByte();
                
                switch (tag) {
                    case CONSTANT_Utf8:
                        int length = dis.readUnsignedShort();
                        byte[] bytes = new byte[length];
                        dis.readFully(bytes);
                        String str = new String(bytes, "UTF-8");
                        // 检查是否包含lambda合成方法名或BootstrapMethods属性
                        if (str.startsWith("lambda$") || str.equals("BootstrapMethods")) {
                            Log.debug("检测到Lambda特征: " + str);
                            return true;
                        }
                        break;
                    case CONSTANT_Integer:
                    case CONSTANT_Float:
                        dis.skipBytes(4);
                        break;
                    case CONSTANT_Long:
                    case CONSTANT_Double:
                        dis.skipBytes(8);
                        i++; // Long和Double占用两个常量池槽位
                        break;
                    case CONSTANT_Class:
                    case CONSTANT_String:
                    case CONSTANT_MethodType:
                        dis.skipBytes(2);
                        break;
                    case CONSTANT_Fieldref:
                    case CONSTANT_Methodref:
                    case CONSTANT_InterfaceMethodref:
                    case CONSTANT_NameAndType:
                        dis.skipBytes(4);
                        break;
                    case CONSTANT_MethodHandle:
                        dis.skipBytes(3);
                        break;
                    case CONSTANT_InvokeDynamic:
                        // 找到InvokeDynamic常量，确认有Lambda或动态调用
                        Log.debug("检测到InvokeDynamic指令");
                        dis.skipBytes(4); // bootstrap_method_attr_index + name_and_type_index
                        return true;
                    default:
                        // 未知标签类型，为了安全跳过
                        Log.debug("未知的常量池标签: " + tag);
                        return false; // 保守处理，遇到未知标签返回false
                }
            }
            
            return false;
        } catch (IOException e) {
            Log.debug("分析字节码时出错: " + e.getMessage());
            return false; // 出错时保守返回false，不跳过加密
        }
    }
    
    /**
     * 从文件读取并检测是否包含Lambda
     * 
     * @param classFile class文件
     * @return true表示包含Lambda
     */
    public static boolean containsLambda(File classFile) {
        if (classFile == null || !classFile.exists() || !classFile.isFile()) {
            return false;
        }
        
        byte[] bytes = IoUtils.readFileToByte(classFile);
        return containsLambda(bytes);
    }
    
    /**
     * 检测类名是否像是Lambda合成类
     * 
     * @param className 类名
     * @return true表示可能是Lambda类
     */
    public static boolean isLambdaClassName(String className) {
        return className != null && className.contains("$$Lambda$");
    }
}
