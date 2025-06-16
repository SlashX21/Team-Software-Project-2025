"""
Grocery Guardian 基础功能测试
测试条形码扫描和小票分析的核心流程
"""

import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, List

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 导入推荐系统组件
from recommendation.recommender import (
    get_recommendation_engine, 
    BarcodeRecommendationRequest,
    ReceiptRecommendationRequest
)
from database.db_manager import DatabaseManager

class GroceryGuardianTester:
    """基础功能测试器"""
    
    def __init__(self):
        self.engine = get_recommendation_engine()
        self.db = DatabaseManager()
        
    async def test_barcode_recommendation(self):
        """测试条形码扫描推荐"""
        logger.info("🔍 开始条形码扫描推荐测试...")
        
        # 测试请求数据（JSON格式）
        test_request = {
            "scan_type": "barcode",
            "user_id": 1,
            "product_barcode": "5449000000996",  # 测试商品条码
            "scan_context": {
                "location": "Tesco",
                "timestamp": datetime.now().isoformat()
            }
        }
        
        try:
            # 创建推荐请求
            request = BarcodeRecommendationRequest(
                user_id=test_request["user_id"],
                product_barcode=test_request["product_barcode"],
                scan_context=test_request.get("scan_context")
            )
            
            # 执行推荐
            response = await self.engine.recommend_alternatives(request)
            
            # 验证响应
            assert response.success, f"推荐失败: {response.message}"
            assert response.scan_type == "barcode_scan"
            assert len(response.recommendations) <= 5
            
            logger.info(f"✅ 条形码推荐成功 - 推荐数量: {len(response.recommendations)}")
            logger.info(f"   处理时间: {response.processing_metadata['processing_time_ms']}ms")
            
            # 打印推荐结果
            for i, rec in enumerate(response.recommendations[:2], 1):
                logger.info(f"   推荐{i}: {rec.product.get('name', 'Unknown')} (评分: {rec.recommendation_score:.2f})")
            
            return {
                "status": "success",
                "recommendations_count": len(response.recommendations),
                "processing_time_ms": response.processing_metadata["processing_time_ms"],
                "llm_analysis_available": bool(response.llm_analysis.get("summary"))
            }
            
        except Exception as e:
            logger.error(f"❌ 条形码推荐测试失败: {e}")
            return {"status": "failed", "error": str(e)}
    
    async def test_receipt_analysis(self):
        """测试小票分析推荐"""
        logger.info("📄 开始小票分析推荐测试...")
        
        # 测试请求数据（JSON格式）
        test_request = {
            "scan_type": "receipt",
            "user_id": 1,
            "purchased_items": [
                {
                    "barcode": "5449000000996",
                    "item_name": "Coca-Cola Classic 500ml",
                    "quantity": 2,
                    "unit_price": 1.25,
                    "total_price": 2.50
                },
                {
                    "barcode": "7622210951717", 
                    "item_name": "White Bread",
                    "quantity": 1,
                    "unit_price": 1.99,
                    "total_price": 1.99
                }
            ],
            "receipt_context": {
                "store": "Tesco",
                "purchase_date": "2025-06-13",
                "total_amount": 4.49
            }
        }
        
        try:
            # 创建小票分析请求
            request = ReceiptRecommendationRequest(
                user_id=test_request["user_id"],
                purchased_items=test_request["purchased_items"],
                receipt_context=test_request.get("receipt_context")
            )
            
            # 执行分析
            response = await self.engine.analyze_receipt_recommendations(request)
            
            # 验证响应
            assert response["success"], f"小票分析失败: {response.get('message')}"
            assert response["scan_type"] == "receipt_analysis"
            assert "item_recommendations" in response
            
            logger.info(f"✅ 小票分析成功 - 商品数量: {response.get('purchased_items_count', 0)}")
            logger.info(f"   处理时间: {response['processing_metadata']['processing_time_ms']}ms")
            
            # 打印分析结果
            item_recs = response.get("item_recommendations", [])
            for i, item_rec in enumerate(item_recs[:2], 1):
                original_name = item_rec["original_item"].get("name", "Unknown")
                alternatives_count = len(item_rec.get("alternatives", []))
                logger.info(f"   商品{i}: {original_name} → {alternatives_count}个替代建议")
            
            return {
                "status": "success",
                "items_analyzed": len(item_recs),
                "processing_time_ms": response["processing_metadata"]["processing_time_ms"],
                "nutrition_analysis_available": bool(response.get("overall_nutrition_analysis"))
            }
            
        except Exception as e:
            logger.error(f"❌ 小票分析测试失败: {e}")
            return {"status": "failed", "error": str(e)}
    
    def test_database_connection(self):
        """测试数据库连接"""
        logger.info("🗄️ 测试数据库连接...")
        
        try:
            with self.db:
                # 测试基础查询
                test_product = self.db.get_product_by_barcode("5449000000996")
                test_user = self.db.get_user_profile(1)
                
                assert test_product is not None, "测试商品未找到"
                assert test_user is not None, "测试用户未找到"
                
                logger.info(f"✅ 数据库连接正常")
                logger.info(f"   测试商品: {test_product.get('name', 'Unknown')}")
                logger.info(f"   测试用户: {test_user.get('username', 'Unknown')}")
                
                return {
                    "status": "success",
                    "product_found": test_product is not None,
                    "user_found": test_user is not None
                }
                
        except Exception as e:
            logger.error(f"❌ 数据库连接测试失败: {e}")
            return {"status": "failed", "error": str(e)}
    
    async def run_all_tests(self):
        """运行所有基础测试"""
        logger.info("🚀 开始Grocery Guardian基础测试套件...")
        
        results = {
            "test_suite": "Grocery Guardian Basic Tests",
            "timestamp": datetime.now().isoformat(),
            "results": {}
        }
        
        # 1. 数据库连接测试
        results["results"]["database_connection"] = self.test_database_connection()
        
        # 2. 条形码推荐测试
        results["results"]["barcode_recommendation"] = await self.test_barcode_recommendation()
        
        # 3. 小票分析测试
        results["results"]["receipt_analysis"] = await self.test_receipt_analysis()
        
        # 统计测试结果
        passed = sum(1 for r in results["results"].values() if r["status"] == "success")
        total = len(results["results"])
        
        logger.info(f"📊 测试完成: {passed}/{total} 通过")
        
        if passed == total:
            logger.info("🎉 所有测试通过！系统运行正常")
        else:
            logger.warning("⚠️ 部分测试失败，请检查错误信息")
        
        return results

# 主测试函数
async def main():
    """主测试入口"""
    tester = GroceryGuardianTester()
    results = await tester.run_all_tests()
    
    # 输出详细结果
    print("\n" + "="*50)
    print("📋 测试结果详情:")
    print("="*50)
    
    for test_name, result in results["results"].items():
        status_emoji = "✅" if result["status"] == "success" else "❌"
        print(f"{status_emoji} {test_name.replace('_', ' ').title()}: {result['status']}")
        
        if result["status"] == "failed":
            print(f"   错误: {result.get('error', 'Unknown error')}")
        elif "processing_time_ms" in result:
            print(f"   处理时间: {result['processing_time_ms']}ms")
    
    print("="*50)
    return results

# 运行测试
if __name__ == "__main__":
    # 确保数据库已连接并有测试数据
    print("🔧 准备测试环境...")
    
    # 运行异步测试
    results = asyncio.run(main())
    
    # 保存测试结果（可选）
    with open("test_results.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"\n📁 测试结果已保存到 test_results.json")