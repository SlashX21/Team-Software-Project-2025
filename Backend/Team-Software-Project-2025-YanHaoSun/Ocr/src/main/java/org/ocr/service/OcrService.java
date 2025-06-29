// package org.ocr.service;

// import org.ocr.pojo.DTO.BarcodeRequest;
// import org.ocr.pojo.response.BarcodeResponse;
// import org.ocr.pojo.response.ScanResponse;
// import org.springframework.beans.factory.annotation.Value;
// import org.springframework.core.io.ByteArrayResource;
// import org.springframework.http.*;
// import org.springframework.stereotype.Service;
// import org.springframework.util.LinkedMultiValueMap;
// import org.springframework.util.MultiValueMap;
// import org.springframework.web.client.RestTemplate;
// import org.springframework.web.multipart.MultipartFile;

// import java.io.IOException;

// @Service
// public class OcrService implements IOcrService {
    
//     @Value("${ocr.service.base-url:http://localhost:8000}")
//     private String ocrServiceBaseUrl;
    
//     @Value("${ocr.service.api-token:123456}")
//     private String apiToken;
    
//     private final RestTemplate restTemplate = new RestTemplate();
    
//     @Override
//     public ScanResponse scanReceipt(MultipartFile file) {
//         try {
//             // 准备请求头
//             HttpHeaders headers = new HttpHeaders();
//             headers.setContentType(MediaType.MULTIPART_FORM_DATA);
//             headers.setBearerAuth(apiToken);
            
//             // 准备文件上传的数据
//             MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
//             body.add("file", new ByteArrayResource(file.getBytes()) {
//                 @Override
//                 public String getFilename() {
//                     return file.getOriginalFilename();
//                 }
//             });
            
//             HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            
//             // 调用Python OCR服务的/scan接口
//             ResponseEntity<ScanResponse> response = restTemplate.postForEntity(
//                 ocrServiceBaseUrl + "/scan", 
//                 requestEntity, 
//                 ScanResponse.class
//             );
            
//             return response.getBody();
            
//         } catch (IOException e) {
//             throw new RuntimeException("读取文件失败: " + e.getMessage(), e);
//         } catch (Exception e) {
//             throw new RuntimeException("调用OCR服务失败: " + e.getMessage(), e);
//         }
//     }
    
//     @Override
//     public BarcodeResponse processBarcode(BarcodeRequest barcodeRequest) {
//         try {
//             // 准备请求头
//             HttpHeaders headers = new HttpHeaders();
//             headers.setContentType(MediaType.APPLICATION_JSON);
//             headers.setBearerAuth(apiToken);
            
//             HttpEntity<BarcodeRequest> requestEntity = new HttpEntity<>(barcodeRequest, headers);
            
//             // 调用Python OCR服务的/barcode接口
//             ResponseEntity<BarcodeResponse> response = restTemplate.postForEntity(
//                 ocrServiceBaseUrl + "/barcode", 
//                 requestEntity, 
//                 BarcodeResponse.class
//             );
            
//             return response.getBody();
            
//         } catch (Exception e) {
//             throw new RuntimeException("调用条码服务失败: " + e.getMessage(), e);
//         }
//     }
// } 