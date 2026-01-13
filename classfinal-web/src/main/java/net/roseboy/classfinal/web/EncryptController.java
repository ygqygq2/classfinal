package net.roseboy.classfinal.web;

import net.roseboy.classfinal.JarEncryptor;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletResponse;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

/**
 * ClassFinal Web 加密控制器
 */
@Controller
@RequestMapping("/api")
public class EncryptController {

    private static final String UPLOAD_DIR = System.getProperty("java.io.tmpdir") + "/classfinal-web/";
    
    static {
        new File(UPLOAD_DIR).mkdirs();
    }

    /**
     * 上传待加密的 JAR/WAR 文件
     */
    @PostMapping("/upload")
    @ResponseBody
    public Map<String, Object> uploadFile(@RequestParam("file") MultipartFile file) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            if (file.isEmpty()) {
                result.put("success", false);
                result.put("message", "文件不能为空");
                return result;
            }
            
            String originalFilename = file.getOriginalFilename();
            if (!originalFilename.endsWith(".jar") && !originalFilename.endsWith(".war")) {
                result.put("success", false);
                result.put("message", "只支持 .jar 和 .war 文件");
                return result;
            }
            
            // 生成唯一文件名
            String fileId = UUID.randomUUID().toString();
            String savedPath = UPLOAD_DIR + fileId + "-" + originalFilename;
            File dest = new File(savedPath);
            file.transferTo(dest);
            
            result.put("success", true);
            result.put("fileId", fileId);
            result.put("filename", originalFilename);
            result.put("size", formatFileSize(file.getSize()));
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "上传失败: " + e.getMessage());
        }
        
        return result;
    }

    /**
     * 执行加密
     */
    @PostMapping("/encrypt")
    @ResponseBody
    public Map<String, Object> encrypt(@RequestBody Map<String, Object> params) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            String fileId = (String) params.get("fileId");
            String filename = (String) params.get("filename");
            String password = (String) params.get("password");
            String packages = (String) params.get("packages");
            String exclude = (String) params.get("exclude");
            Boolean libjars = (Boolean) params.get("libjars");
            Boolean nopwd = (Boolean) params.get("nopwd");
            
            // 验证参数
            if (fileId == null || filename == null) {
                result.put("success", false);
                result.put("message", "文件信息缺失");
                return result;
            }
            
            if (packages == null || packages.trim().isEmpty()) {
                result.put("success", false);
                result.put("message", "请指定要加密的包名");
                return result;
            }
            
            if (!Boolean.TRUE.equals(nopwd) && (password == null || password.trim().isEmpty())) {
                result.put("success", false);
                result.put("message", "请输入加密密码或选择无密码模式");
                return result;
            }
            
            String inputPath = UPLOAD_DIR + fileId + "-" + filename;
            File inputFile = new File(inputPath);
            if (!inputFile.exists()) {
                result.put("success", false);
                result.put("message", "文件不存在，请重新上传");
                return result;
            }
            
            // 准备密码
            char[] pwd = null;
            if (!Boolean.TRUE.equals(nopwd)) {
                pwd = password.toCharArray();
            }
            
            // 创建加密器
            JarEncryptor encryptor = new JarEncryptor(inputPath, pwd);
            
            // 设置要加密的包
            List<String> packageList = Arrays.asList(packages.split(","));
            encryptor.setPackages(packageList);
            
            // 设置排除的类
            if (exclude != null && !exclude.trim().isEmpty()) {
                List<String> excludeList = Arrays.asList(exclude.split(","));
                encryptor.setExcludeClass(excludeList);
            }
            
            // 设置要加密的 lib jar
            if (Boolean.TRUE.equals(libjars)) {
                encryptor.setIncludeJars(Arrays.asList("*"));
            }
            
            // 执行加密
            String encryptedPath = encryptor.doEncryptJar();
            
            // 检查加密结果
            if (encryptedPath == null || !new File(encryptedPath).exists()) {
                result.put("success", false);
                result.put("message", "加密失败，未生成加密文件");
                return result;
            }
            
            // 移动到标准位置
            String outputFilename = filename.replace(".jar", "-encrypted.jar")
                                           .replace(".war", "-encrypted.war");
            String outputPath = UPLOAD_DIR + fileId + "-" + outputFilename;
            File encryptedFile = new File(encryptedPath);
            File destFile = new File(outputPath);
            
            if (!encryptedFile.renameTo(destFile)) {
                // 如果重命名失败，尝试复制
                Files.copy(encryptedFile.toPath(), destFile.toPath());
                encryptedFile.delete();
            }
            
            result.put("success", true);
            result.put("message", "加密成功");
            result.put("encryptedFileId", fileId);
            result.put("encryptedFilename", outputFilename);
            result.put("size", formatFileSize(destFile.length()));
            
            // 清理原始文件
            inputFile.delete();
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "加密失败: " + e.getMessage());
        }
        
        return result;
    }

    /**
     * 下载加密后的文件
     */
    @GetMapping("/download/{fileId}/{filename}")
    public void download(@PathVariable String fileId, 
                        @PathVariable String filename,
                        HttpServletResponse response) {
        try {
            String filePath = UPLOAD_DIR + fileId + "-" + filename;
            File file = new File(filePath);
            
            if (!file.exists()) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().write("文件不存在");
                return;
            }
            
            response.setContentType("application/octet-stream");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
            response.setContentLength((int) file.length());
            
            try (FileInputStream fis = new FileInputStream(file);
                 OutputStream os = response.getOutputStream()) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = fis.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
                os.flush();
            }
            
            // 下载后删除文件
            file.delete();
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 格式化文件大小
     */
    private String formatFileSize(long size) {
        if (size < 1024) return size + " B";
        if (size < 1024 * 1024) return String.format("%.2f KB", size / 1024.0);
        return String.format("%.2f MB", size / (1024.0 * 1024.0));
    }
}
