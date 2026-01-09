package net.roseboy.classfinal.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@Controller
public class MainController {

    @GetMapping("/")
    public String index(HttpServletRequest request) {
        request.setAttribute("ttt", "rrrrr");
        return "index";
    }

    @GetMapping("/health")
    @ResponseBody
    public Map<String, Object> health() {
        Map<String, Object> result = new HashMap<>();
        result.put("status", "UP");
        result.put("application", "ClassFinal Web");
        result.put("version", "2.0.1-SNAPSHOT");
        result.put("timestamp", System.currentTimeMillis());
        return result;
    }
}
