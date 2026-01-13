package net.roseboy.classfinal.util;

/**
 * 进度条显示工具
 * 
 * @author ygqygq2
 * @since 2.0.1
 */
public class ProgressBar {
    private final long total;
    private long current = 0;
    private final String name;
    private long startTime;
    
    /**
     * 创建进度条
     * 
     * @param name 进度条名称
     * @param total 总数
     */
    public ProgressBar(String name, long total) {
        this.name = name;
        this.total = total;
        this.startTime = System.currentTimeMillis();
    }
    
    /**
     * 增加进度
     * 
     * @param count 增加数量
     */
    public void add(long count) {
        this.current += count;
    }
    
    /**
     * 增加1
     */
    public void increment() {
        add(1);
    }
    
    /**
     * 获取进度百分比
     */
    public int getPercentage() {
        if (total == 0) {
            return 0;
        }
        return (int) ((current * 100) / total);
    }
    
    /**
     * 获取已用时间（秒）
     */
    public long getElapsedSeconds() {
        return (System.currentTimeMillis() - startTime) / 1000;
    }
    
    /**
     * 获取预计剩余时间（秒）
     */
    public long getEstimatedRemainingSeconds() {
        if (current == 0) {
            return 0;
        }
        long elapsed = getElapsedSeconds();
        long total = (elapsed * this.total) / current;
        return total - elapsed;
    }
    
    /**
     * 显示进度条
     */
    public void display() {
        if (Log.getCurrentLevel().getLevel() > Log.LogLevel.INFO.getLevel()) {
            return; // 非INFO级别以上不显示
        }
        
        int percentage = getPercentage();
        int barLength = 30;
        int filled = (int) ((percentage / 100.0) * barLength);
        
        StringBuilder bar = new StringBuilder();
        bar.append(name).append(" [");
        
        for (int i = 0; i < barLength; i++) {
            if (i < filled) {
                bar.append("=");
            } else if (i == filled) {
                bar.append(">");
            } else {
                bar.append(" ");
            }
        }
        
        bar.append("] ");
        bar.append(String.format("%3d%%", percentage));
        bar.append(" (").append(current).append("/").append(total).append(")");
        
        long remaining = getEstimatedRemainingSeconds();
        if (remaining > 0) {
            bar.append(" ETA: ").append(remaining).append("s");
        }
        
        // 清除当前行并打印进度条
        System.out.print("\r" + bar.toString());
        
        if (percentage == 100) {
            System.out.println();
        }
    }
    
    /**
     * 完成
     */
    public void complete() {
        current = total;
        display();
    }
}
