package com.demo.backend;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/ocr")
public class OcrController {
    
    @Value("${ocr.service.base-url:http://localhost:8000}")
    private String ocrServiceBaseUrl;
    
    @Value("${ocr.service.api-token:123456}")
    private String apiToken;
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    /**
     * 扫描收据接口 - 对应Python服务的POST /scan
     * 图片上传扫描接口 /ocr/scan
     */
    @PostMapping(value = "/scan", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseMessage<Map<String, Object>> scanReceipt(@RequestParam("file") MultipartFile file) {
        try {
            // 检查图片是否为空
            if (file.isEmpty()) {
                return new ResponseMessage<>(400, "文件不能为空", null);
            }
            
            // 判断文件类型是不是图片，如果不是图片，则返回错误
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return new ResponseMessage<>(400, "只支持图片文件", null);
            }
            
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            headers.setBearerAuth(apiToken);
            
            // 构造上传文件的请求体
            // 用 ByteArrayResource 包装上传的文件流，并设置文件名。
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename();
                }
            });
            
            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            
            // 调用Python OCR服务的/scan接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                ocrServiceBaseUrl + "/scan", 
                requestEntity, 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (IOException e) {
            return new ResponseMessage<>(500, "读取文件失败: " + e.getMessage(), null);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "调用OCR服务失败: " + e.getMessage(), null);
        }
    }
    
    /**
     * 处理条码接口 - 对应Python服务的POST /barcode
     * barcode识别接口 /ocr/barcode
     * 
     * 接口逻辑:
     *  1. 前端 POST 一个 JSON 请求，例如 { "barcode": "12345678" }
     *  2. 设置 Content-Type: application/json
     *  3. 添加授权 Token
     *  4. 直接用 RestTemplate 发送 POST 请求到 /barcode，返回结果给前端
     */
    @PostMapping("/barcode")
    public ResponseMessage<Map<String, Object>> processBarcode(@RequestBody Map<String, String> request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiToken);
            
            HttpEntity<Map<String, String>> requestEntity = new HttpEntity<>(request, headers);
            
            // 调用Python OCR服务的/barcode接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                ocrServiceBaseUrl + "/barcode", 
                requestEntity, 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "调用条码服务失败: " + e.getMessage(), null);
        }
    }
    
    /**
     * 健康检查接口
     */
    @GetMapping("/health")
    public ResponseMessage<String> health() {
        return ResponseMessage.success("OCR服务运行正常");
    }
} 