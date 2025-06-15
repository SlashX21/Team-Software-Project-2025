// package org.ocr.controller;

// import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
// import org.ocr.pojo.DTO.BarcodeRequest;
// import org.ocr.pojo.response.BarcodeResponse;
// import org.ocr.pojo.response.ScanResponse;
// import org.ocr.service.IOcrService;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.http.MediaType;
// import org.springframework.validation.annotation.Validated;
// import org.springframework.web.bind.annotation.*;
// import org.springframework.web.multipart.MultipartFile;

// @RestController
// @RequestMapping("/ocr")
// public class OcrController {
    
//     @Autowired
//     private IOcrService ocrService;
    
//     /**
//      * 扫描收据接口 - 对应Python服务的POST /scan
//      * @param file 上传的图片文件
//      * @return 扫描结果
//      */
//     @PostMapping(value = "/scan", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
//     public ResponseMessage<ScanResponse> scanReceipt(@RequestParam("file") MultipartFile file) {
//         try {
//             // 验证文件
//             if (file.isEmpty()) {
//                 return ResponseMessage.error("文件不能为空");
//             }
            
//             // 验证文件类型
//             String contentType = file.getContentType();
//             if (contentType == null || !contentType.startsWith("image/")) {
//                 return ResponseMessage.error("只支持图片文件");
//             }
            
//             ScanResponse result = ocrService.scanReceipt(file);
//             return ResponseMessage.success(result);
            
//         } catch (Exception e) {
//             return ResponseMessage.error("扫描失败: " + e.getMessage());
//         }
//     }
    
//     /**
//      * 处理条码接口 - 对应Python服务的POST /barcode
//      * @param barcodeRequest 条码请求
//      * @return 处理结果
//      */
//     @PostMapping("/barcode")
//     public ResponseMessage<BarcodeResponse> processBarcode(@Validated @RequestBody BarcodeRequest barcodeRequest) {
//         try {
//             BarcodeResponse result = ocrService.processBarcode(barcodeRequest);
//             return ResponseMessage.success(result);
            
//         } catch (Exception e) {
//             return ResponseMessage.error("条码处理失败: " + e.getMessage());
//         }
//     }
    
//     /**
//      * 健康检查接口
//      * @return 服务状态
//      */
//     @GetMapping("/health")
//     public ResponseMessage<String> health() {
//         return ResponseMessage.success("OCR服务运行正常");
//     }
// } 