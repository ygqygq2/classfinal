package net.roseboy.classfinal.util;

import net.roseboy.classfinal.Const;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * 控制台打印日志工具
 *
 * @author roseboy
 */
public class Log {
    public static final SimpleDateFormat datetimeFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    
    /**
     * 日志级别枚举
     */
    public enum LogLevel {
        DEBUG(0, "DEBUG"),
        INFO(1, "INFO"),
        WARN(2, "WARN"),
        ERROR(3, "ERROR");
        
        private final int level;
        private final String name;
        
        LogLevel(int level, String name) {
            this.level = level;
            this.name = name;
        }
        
        public int getLevel() {
            return level;
        }
        
        public String getName() {
            return name;
        }
        
        public static LogLevel fromString(String level) {
            if (level == null) {
                return INFO;
            }
            switch (level.toUpperCase()) {
                case "DEBUG": return DEBUG;
                case "INFO": return INFO;
                case "WARN": return WARN;
                case "ERROR": return ERROR;
                default: return INFO;
            }
        }
    }
    
    /**
     * 当前日志级别，默认为INFO（延迟初始化避免类加载问题）
     */
    private static LogLevel currentLevel = null;
    
    /**
     * 获取当前日志级别
     */
    public static LogLevel getCurrentLevel() {
        if (currentLevel == null) {
            currentLevel = LogLevel.INFO;
        }
        return currentLevel;
    }
    
    /**
     * 设置日志级别
     * 
     * @param level 日志级别字符串 (DEBUG|INFO|WARN|ERROR)
     */
    public static void setLogLevel(String level) {
        currentLevel = LogLevel.fromString(level);
    }
    
    /**
     * 设置日志级别
     * 
     * @param level 日志级别
     */
    public static void setLogLevel(LogLevel level) {
        if (level != null) {
            currentLevel = level;
        }
    }
    
    /**
     * 输出debug信息
     *
     * @param msg 信息
     */
    public static void debug(Object msg) {
        if (Const.DEBUG && getCurrentLevel().getLevel() <= LogLevel.DEBUG.getLevel()) {
            String log = datetimeFormat.format(new Date()) + " [DEBUG] " + msg;
            System.out.println(log);
        }
    }
    
    /**
     * 输出info信息
     *
     * @param msg 信息
     */
    public static void info(Object msg) {
        if (getCurrentLevel().getLevel() <= LogLevel.INFO.getLevel()) {
            String log = "[INFO] " + msg;
            System.out.println(log);
        }
    }
    
    /**
     * 输出warn信息
     *
     * @param msg 信息
     */
    public static void warn(Object msg) {
        if (getCurrentLevel().getLevel() <= LogLevel.WARN.getLevel()) {
            String log = "[WARN] " + msg;
            System.out.println(log);
        }
    }
    
    /**
     * 输出error信息
     *
     * @param msg 信息
     */
    public static void error(Object msg) {
        if (getCurrentLevel().getLevel() <= LogLevel.ERROR.getLevel()) {
            String log = "[ERROR] " + msg;
            System.err.println(log);
        }
    }

    /**
     * 输出
     *
     * @param obj 内容
     */
    public static void println(String obj) {
        System.out.println(obj);
    }

    /**
     * 输出
     *
     * @param obj 内容
     */
    public static void print(String obj) {
        System.out.print(obj);
    }

    /**
     * 输出
     */
    public static void println() {
        System.out.println();
    }
}
