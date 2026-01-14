package net.roseboy.classfinal.util;

import java.io.*;
import java.util.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

/**
 * jar/war操作工具类
 *
 * @author roseboy
 */
public class JarUtils {
    //打包时需要删除的文件
    public static final String[] DLE_FILES = {".DS_Store", "Thumbs.db"};
    
    //记录原JAR的entry顺序，key=targetDir路径, value=entry名称->顺序索引
    private static final Map<String, LinkedHashMap<String, Integer>> JAR_ENTRY_ORDER = new HashMap<>();

    /**
     * 把目录压缩成jar
     *
     * @param jarDir    需要打包的目录
     * @param targetJar 打包出的jar/war文件路径
     * @return 打包出的jar/war文件路径
     */
    public static String doJar(String jarDir, String targetJar) {
        File jarDirFile = new File(jarDir);
        //枚举jarDir下的所有文件以及目录
        List<File> files = new ArrayList<>();
        IoUtils.listFile(files, jarDirFile);
        
        // 按原JAR的entry顺序排序，如果有记录的话
        LinkedHashMap<String, Integer> entryOrder = JAR_ENTRY_ORDER.get(jarDir);
        if (entryOrder != null && !entryOrder.isEmpty()) {
            files.sort((f1, f2) -> {
                String path1 = f1.getAbsolutePath().substring(jarDirFile.getAbsolutePath().length() + 1).replace(File.separator, "/");
                String path2 = f2.getAbsolutePath().substring(jarDirFile.getAbsolutePath().length() + 1).replace(File.separator, "/");
                Integer order1 = entryOrder.getOrDefault(path1, Integer.MAX_VALUE);
                Integer order2 = entryOrder.getOrDefault(path2, Integer.MAX_VALUE);
                int cmp = order1.compareTo(order2);
                // 如果顺序相同或都没有记录，则按路径字母序
                return cmp != 0 ? cmp : path1.compareTo(path2);
            });
        } else {
            // 如果没有记录原始顺序，至少保证按字母序排序（确定性）
            files.sort((f1, f2) -> f1.getAbsolutePath().compareTo(f2.getAbsolutePath()));
        }

        ZipOutputStream zos = null;
        OutputStream out = null;

        try {
            File jar = new File(targetJar);
            if (jar.exists()) {
                jar.delete();
            }

            out = new FileOutputStream(jar);
            zos = new ZipOutputStream(out);

            for (File file : files) {
                if (isDel(file)) {
                    continue;
                }
                String fileName = file.getAbsolutePath().substring(jarDirFile.getAbsolutePath().length() + 1);
                fileName = fileName.replace(File.separator, "/");
                //目录，添加一个目录entry
                if (file.isDirectory()) {
                    ZipEntry ze = new ZipEntry(fileName + "/");
                    ze.setTime(System.currentTimeMillis());
                    zos.putNextEntry(ze);
                    zos.closeEntry();
                }
                //jar文件，需要写crc信息
                else if (fileName.endsWith(".jar")) {
                    byte[] bytes = IoUtils.readFileToByte(file);
                    ZipEntry ze = new ZipEntry(fileName);
                    ze.setMethod(ZipEntry.STORED);
                    ze.setSize(bytes.length);
                    ze.setTime(System.currentTimeMillis());
                    ze.setCrc(IoUtils.crc32(bytes));
                    zos.putNextEntry(ze);
                    zos.write(bytes);
                    zos.closeEntry();
                }
                //其他文件直接写入
                else {
                    ZipEntry ze = new ZipEntry(fileName);
                    ze.setTime(System.currentTimeMillis());
                    zos.putNextEntry(ze);
                    byte[] bytes = IoUtils.readFileToByte(file);
                    zos.write(bytes);
                    zos.closeEntry();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            IoUtils.close(zos, out);
        }
        return targetJar;
    }


    /**
     * 释放jar内以及子jar的所有文件
     *
     * @param jarPath   jar文件
     * @param targetDir 释放文件夹
     * @return 所有文件的完整路径，包含目录
     */
    public static List<String> unJar(String jarPath, String targetDir) {
        return unJar(jarPath, targetDir, null);
    }

    /**
     * 释放jar内以及子jar的所有文件
     *
     * @param jarPath   jar文件
     * @param targetDir 释放文件夹
     * @return 所有文件的完整路径，包含目录
     */
    public static List<String> unJar(String jarPath, String targetDir, List<String> includeFiles) {
        List<String> list = new ArrayList<>();
        File target = new File(targetDir);
        if (!target.exists()) {
            target.mkdirs();
        }
        
        // 记录原JAR的entry顺序
        LinkedHashMap<String, Integer> entryOrder = new LinkedHashMap<>();

        FileInputStream fin = null;
        ZipFile zipFile = null;
        try {
            zipFile = new ZipFile(new File(jarPath));
            ZipEntry entry;
            File targetFile;
            
            // 第一次遍历：记录所有entry的顺序
            Enumeration<?> entries = zipFile.entries();
            int orderIndex = 0;
            while (entries.hasMoreElements()) {
                entry = (ZipEntry) entries.nextElement();
                entryOrder.put(entry.getName(), orderIndex++);
            }
            
            //先把文件夹创建出来
            entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                entry = (ZipEntry) entries.nextElement();
                if (entry.isDirectory()) {
                    targetFile = new File(target, entry.getName());
                    if(!targetFile.exists()){
                        targetFile.mkdirs();
                    }
                } else {//有时候entries没有目录,根据文件路径创建目录
                    int lastSeparatorIndex = entry.getName().lastIndexOf("/");
                    if (lastSeparatorIndex > 0) {
                        targetFile = new File(target, entry.getName().substring(0, lastSeparatorIndex));
                        if (!targetFile.exists()) {
                            targetFile.mkdirs();
                        }
                    }
                }
            }

            //再释放文件
            entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                entry = (ZipEntry) entries.nextElement();
                if (entry.isDirectory()) {
                    continue;
                }
                targetFile = new File(target, entry.getName());

                //跳过未包含的文件
                if (includeFiles != null && includeFiles.size() > 0 && !includeFiles.contains(targetFile.getName())) {
                    continue;
                }
                byte[] bytes = IoUtils.toBytes(zipFile.getInputStream(entry));
                IoUtils.writeFile(targetFile, bytes);
                list.add(targetFile.getAbsolutePath());
            }
            
            // 保存entry顺序记录
            JAR_ENTRY_ORDER.put(targetDir, entryOrder);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            IoUtils.close(zipFile, fin);
        }
        return list;
    }

    /**
     * 在jar中根据文件名释放文件
     *
     * @param zip        压缩文件
     * @param fileName   文件名
     * @param targetFile 释放的目标文件
     * @return 释放出的文件的绝对路径
     */
    public static String releaseFileFromJar(File zip, String fileName, File targetFile) {
        byte[] bytes = getFileFromJar(zip, fileName);
        if (bytes == null) {
            return null;
        }
        IoUtils.writeFile(targetFile, bytes);
        return targetFile.getAbsolutePath();

    }

    /**
     * 在压缩文件中获取一个文件的字节
     *
     * @param zip      压缩文件
     * @param fileName 文件名
     * @return 文件的字节
     */
    public static byte[] getFileFromJar(File zip, String fileName) {
        ZipFile zipFile = null;
        try {
            if (!zip.exists()) {
                return null;
            }
            zipFile = new ZipFile(zip);
            ZipEntry zipEntry = zipFile.getEntry(fileName);
            if (zipEntry == null) {
                return null;
            }
            InputStream is = zipFile.getInputStream(zipEntry);
            return IoUtils.toBytes(is);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            IoUtils.close(zipFile);
        }
        return null;
    }

    /**
     * 是否删除这个文件
     *
     * @param file 文件
     * @return 是否需要删除
     */
    public static boolean isDel(File file) {
        for (String f : DLE_FILES) {
            if (file.getAbsolutePath().endsWith(f)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 获取class运行的classes目录或所在的jar包目录
     *
     * @return 路径字符串
     */
    public static String getRootPath(String path) {
        if (path == null) {
            path = JarUtils.class.getResource("").getPath();
        }

        try {
            path = java.net.URLDecoder.decode(path, "utf-8");
        } catch (UnsupportedEncodingException e) {
        }

        if (path.startsWith("jar:") || path.startsWith("war:")) {
            path = path.substring(4);
        }
        if (path.startsWith("file:")) {
            path = path.substring(5);
        }

        //没解压的war包
        if (path.contains("*")) {
            return path.substring(0, path.indexOf("*"));
        }
        //war包解压后的WEB-INF
        else if (path.contains("WEB-INF")) {
            return path.substring(0, path.indexOf("WEB-INF"));
        }
        //jar
        else if (path.contains("!")) {
            return path.substring(0, path.indexOf("!"));
        }
        //普通jar/war
        else if (path.endsWith(".jar") || path.endsWith(".war")) {
            return path;
        }
        //no
        else if (path.contains("/classes/")) {
            return path.substring(0, path.indexOf("/classes/") + 9);
        }
        return null;
    }

}
