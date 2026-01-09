package net.roseboy.classfinal;

/**
 * 常量
 *
 * @author roseboy
 */
public class Const {
    public static final String VERSION = getVersion();

    //加密出来的文件名
    public static final String FILE_NAME = ".classes";
    
    /**
     * 动态获取版本号
     * 优先从 MANIFEST.MF 读取，如果获取不到则使用 dev
     */
    private static String getVersion() {
        String version = Const.class.getPackage().getImplementationVersion();
        if (version == null || version.trim().isEmpty()) {
            // 尝试从环境变量获取（用于 CI/CD）
            version = System.getenv("CLASSFINAL_VERSION");
        }
        if (version == null || version.trim().isEmpty()) {
            version = "dev";
        }
        return "v" + version;
    }

    //lib下的jar解压的目录名后缀
    public static final String LIB_JAR_DIR = "__temp__";

    //默认加密方式
    public static final int ENCRYPT_TYPE = 1;

    //密码标记
    public static final String CONFIG_PASS = "org.springframework.config.Pass";
    //机器码标记
    public static final String CONFIG_CODE = "org.springframework.config.Code";
    //加密密码的hash
    public static final String CONFIG_PASSHASH = "org.springframework.config.PassHash";

    //本项目需要打包的代码
    public static final String[] CLASSFINAL_FILES = {"CoreAgent.class", "InputForm.class", "InputForm$1.class",
            "JarDecryptor.class", "AgentTransformer.class", "Const.class", "CmdLineOption.class",
            "EncryptUtils.class", "IoUtils.class", "JarUtils.class", "Log.class", "StrUtils.class",
            "SysUtils.class"};

    //调试模式
    public static boolean DEBUG = false;

    public static void pringInfo() {
        String sysName = System.getProperty("os.name");
        if (sysName.contains("Windows")) {
            System.out.println();
            System.out.println("=========================================================");
            System.out.println("   Java Class Encryption Tool " + VERSION + " by ygqygq2");
            System.out.println("=========================================================");
            System.out.println();
            return;
        }


        String[] color = {"\033[31m", "\033[32m", "\033[33m", "\033[34m", "\033[35m", "\033[36m",
                "\033[90m", "\033[92m", "\033[93m", "\033[94m", "\033[95m", "\033[96m"};
        System.out.println();

        for (int i = 0; i < 57; i++) {
            System.out.print(color[i % color.length] + "=\033[0m");
        }
        System.out.println();
        System.out.println("   \033[31mJava \033[92mClass \033[95mEncryption \033[96mTool\033[0m \033[37m"
                + VERSION + "\033[0m by \033[91mygqygq2\033[0m");
        for (int i = 56; i >= 0; i--) {
            System.out.print(color[i % color.length] + "=\033[0m");
        }
        System.out.println();
        System.out.println();
    }

}
