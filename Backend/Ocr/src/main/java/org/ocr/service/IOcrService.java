package org.ocr.service;

import org.ocr.pojo.DTO.BarcodeRequest;
import org.ocr.pojo.response.BarcodeResponse;
import org.ocr.pojo.response.ScanResponse;
import org.springframework.web.multipart.MultipartFile;

public interface IOcrService {
    
    /**
     * 扫描收据图片，提取商品信息
     * @param file 上传的图片文件
     * @return 扫描结果，包含商品列表
     */
    ScanResponse scanReceipt(MultipartFile file);
    
    /**
     * 处理条码信息
     * @param barcodeRequest 条码请求
     * @return 条码处理结果
     */
    BarcodeResponse processBarcode(BarcodeRequest barcodeRequest);
} 