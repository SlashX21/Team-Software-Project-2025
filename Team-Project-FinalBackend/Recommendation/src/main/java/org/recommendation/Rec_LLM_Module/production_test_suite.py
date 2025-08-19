#!/usr/bin/env python3
"""
Grocery Guardian Recommendation模块生产环境测试套件
整合所有生产优化功能的完整测试，包含详细的中文测试报告生成

测试范围：
- Azure OpenAI集成测试
- 多用户并发处理测试
- 数据验证和安全测试
- 错误处理和降级服务测试
- 性能监控和健康检查测试
- 端到端集成工作流程测试
"""

import asyncio
import sys
import os
import time
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

# 添加模块路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class TestResult:
    """测试结果类"""
    def __init__(self, test_name: str, category: str):
        self.test_name = test_name
        self.category = category
        self.success = False
        self.start_time = time.time()
        self.end_time = None
        self.duration_ms = 0
        self.details = {}
        self.error_message = ""
        self.metrics = {}
    
    def complete(self, success: bool, details: Dict[str, Any] = None, error: str = ""):
        """完成测试"""
        self.end_time = time.time()
        self.duration_ms = int((self.end_time - self.start_time) * 1000)
        self.success = success
        self.details = details or {}
        self.error_message = error

class ProductionTestSuite:
    """生产环境测试套件"""
    
    def __init__(self):
        self.test_results = []
        self.start_time = time.time()
        self.environment_info = self._collect_environment_info()
        self.test_summary = {
            "total_tests": 0,
            "passed_tests": 0,
            "failed_tests": 0,
            "categories": {},
            "performance_metrics": {},
            "system_status": "unknown"
        }
    
    def _collect_environment_info(self) -> Dict[str, Any]:
        """收集环境信息"""
        return {
            "test_start_time": datetime.now().isoformat(),
            "python_version": sys.version,
            "azure_openai_configured": bool(os.getenv("AZURE_OPENAI_API_KEY")),
            "openai_fallback_configured": bool(os.getenv("OPENAI_API_KEY")),
            "environment": os.getenv("ENVIRONMENT", "unknown"),
            "test_runner": "ProductionTestSuite v1.0"
        }
    
    async def run_azure_openai_integration_test(self) -> TestResult:
        """测试Azure OpenAI集成功能"""
        result = TestResult("Azure OpenAI集成测试", "AI服务")
        
        try:
            from llm_evaluation.azure_openai_client import AzureOpenAIClient
            
            print("🔍 测试Azure OpenAI集成...")
            
            # 创建Azure客户端
            client = AzureOpenAIClient()
            
            # 测试基础请求
            start_time = time.time()
            response = await client.generate_completion(
                "请用一句话简单介绍健康饮食的重要性。",
                config_override={"max_tokens": 100}
            )
            api_response_time = int((time.time() - start_time) * 1000)
            
            if response.success:
                # 获取统计信息
                stats = client.get_usage_statistics()
                
                result.complete(True, {
                    "api_response_time_ms": api_response_time,
                    "model": response.model,
                    "content_length": len(response.content),
                    "token_usage": response.usage.get('total_tokens', 0),
                    "prompt_tokens": response.usage.get('prompt_tokens', 0),
                    "completion_tokens": response.usage.get('completion_tokens', 0),
                    "total_requests": stats['total_requests'],
                    "success_rate": stats['success_rate'],
                    "response_preview": response.content[:100] + "..." if len(response.content) > 100 else response.content
                })
                print(f"✅ Azure OpenAI集成成功 - 响应时间: {api_response_time}ms")
            else:
                result.complete(False, {"error_details": response.error}, str(response.error))
                print(f"❌ Azure OpenAI请求失败: {response.error}")
                
        except Exception as e:
            result.complete(False, {"exception_type": type(e).__name__}, str(e))
            print(f"❌ Azure OpenAI集成测试异常: {e}")
        
        return result
    
    async def run_concurrent_processing_test(self) -> TestResult:
        """测试多用户并发处理能力"""
        result = TestResult("并发处理能力测试", "性能")
        
        try:
            from common.request_queue import RequestQueueManager, RequestPriority
            
            print("🔍 测试多用户并发处理...")
            
            # 创建队列管理器
            queue_manager = RequestQueueManager(max_concurrent=5, max_queue_size=20)
            
            # 模拟处理函数
            processing_times = []
            async def concurrent_processor(data):
                start = time.time()
                await asyncio.sleep(0.05)  # 模拟处理时间
                process_time = int((time.time() - start) * 1000)
                processing_times.append(process_time)
                return {"result": f"处理完成: {data.get('request_id')}", "process_time": process_time}
            
            # 注册处理器并启动
            queue_manager.register_processor("concurrent_test", concurrent_processor)
            await queue_manager.start()
            
            # 并发提交多个用户的请求
            request_ids = []
            users = [1, 2, 3, 4, 5]  # 5个不同用户
            
            start_time = time.time()
            for user_id in users:
                for i in range(3):  # 每个用户3个请求
                    request_id = await queue_manager.enqueue_request(
                        user_id=user_id,
                        request_type="concurrent_test",
                        request_data={"request_id": f"user_{user_id}_req_{i}", "user_id": user_id},
                        priority=RequestPriority.NORMAL
                    )
                    request_ids.append((request_id, user_id))
            
            # 等待所有请求处理完成
            await asyncio.sleep(2)
            total_time = int((time.time() - start_time) * 1000)
            
            # 检查结果
            completed_count = 0
            successful_count = 0
            for request_id, user_id in request_ids:
                status = await queue_manager.get_request_status(request_id)
                if status:
                    completed_count += 1
                    if status["status"] == "completed":
                        successful_count += 1
            
            # 获取队列统计
            stats = queue_manager.get_queue_stats()
            await queue_manager.stop()
            
            # 计算性能指标
            avg_processing_time = sum(processing_times) / len(processing_times) if processing_times else 0
            throughput = len(request_ids) / (total_time / 1000) if total_time > 0 else 0
            
            success = successful_count == len(request_ids)
            result.complete(success, {
                "total_requests": len(request_ids),
                "completed_requests": completed_count,
                "successful_requests": successful_count,
                "total_processing_time_ms": total_time,
                "avg_processing_time_ms": int(avg_processing_time),
                "throughput_requests_per_second": round(throughput, 2),
                "unique_users": len(users),
                "requests_per_user": 3,
                "queue_stats": stats
            })
            
            if success:
                print(f"✅ 并发处理测试通过 - 处理{len(request_ids)}个请求，吞吐量: {throughput:.2f} req/s")
            else:
                print(f"❌ 并发处理测试失败 - 完成: {successful_count}/{len(request_ids)}")
                
        except Exception as e:
            result.complete(False, {"exception_type": type(e).__name__}, str(e))
            print(f"❌ 并发处理测试异常: {e}")
        
        return result
    
    async def run_data_validation_security_test(self) -> TestResult:
        """测试数据验证和安全功能"""
        result = TestResult("数据验证和安全测试", "安全")
        
        try:
            from common.data_validator import validate_recommendation_request
            
            print("🔍 测试数据验证和安全...")
            
            test_cases = [
                {
                    "name": "有效条码推荐请求",
                    "type": "barcode_recommendation",
                    "data": {
                        "userId": 1,
                        "productBarcode": "1234567890123",
                        "userPreferences": {
                            "healthGoal": "lose_weight",
                            "allergens": ["nuts", "dairy"],
                            "dietaryRestrictions": ["vegetarian"]
                        }
                    },
                    "should_pass": True
                },
                {
                    "name": "有效小票分析请求",
                    "type": "receipt_analysis",
                    "data": {
                        "userId": 2,
                        "purchasedItems": [
                            {"barcode": "1234567890123", "quantity": 2, "price": 5.99},
                            {"barcode": "9876543210987", "quantity": 1, "price": 3.50}
                        ],
                        "receiptInfo": {
                            "storeName": "测试超市",
                            "totalAmount": 15.48,
                            "purchaseDate": "2025-01-30T10:30:00Z"
                        }
                    },
                    "should_pass": True
                },
                {
                    "name": "无效用户ID",
                    "type": "barcode_recommendation",
                    "data": {"userId": -1, "productBarcode": "1234567890123"},
                    "should_pass": False
                },
                {
                    "name": "无效条码格式",
                    "type": "barcode_recommendation", 
                    "data": {"userId": 1, "productBarcode": "invalid_barcode"},
                    "should_pass": False
                },
                {
                    "name": "潜在恶意输入",
                    "type": "barcode_recommendation",
                    "data": {
                        "userId": 1,
                        "productBarcode": "1234567890123",
                        "userPreferences": {
                            "healthGoal": "<script>alert('xss')</script>",
                            "allergens": ["'; DROP TABLE users; --"]
                        }
                    },
                    "should_pass": False
                }
            ]
            
            passed_tests = 0
            security_blocks = 0
            validation_details = []
            
            for test_case in test_cases:
                test_result = validate_recommendation_request(test_case["type"], test_case["data"])
                
                if test_case["should_pass"]:
                    if test_result.is_valid:
                        passed_tests += 1
                        validation_details.append({
                            "test": test_case["name"],
                            "status": "通过",
                            "result": "有效请求正确验证"
                        })
                    else:
                        validation_details.append({
                            "test": test_case["name"],
                            "status": "失败",
                            "result": f"有效请求被错误拒绝: {test_result.errors}"
                        })
                else:
                    if not test_result.is_valid:
                        passed_tests += 1
                        security_blocks += 1
                        validation_details.append({
                            "test": test_case["name"],
                            "status": "通过",
                            "result": f"无效/恶意请求正确拒绝: {len(test_result.errors)}个错误"
                        })
                    else:
                        validation_details.append({
                            "test": test_case["name"],
                            "status": "失败",
                            "result": "危险请求未被拦截"
                        })
            
            success = passed_tests == len(test_cases)
            result.complete(success, {
                "total_test_cases": len(test_cases),
                "passed_tests": passed_tests,
                "security_blocks": security_blocks,
                "validation_details": validation_details,
                "security_coverage": f"{security_blocks}/{len([t for t in test_cases if not t['should_pass']])}"
            })
            
            if success:
                print(f"✅ 数据验证测试通过 - {passed_tests}/{len(test_cases)}个测试用例通过")
            else:
                print(f"❌ 数据验证测试失败 - {passed_tests}/{len(test_cases)}个测试用例通过")
                
        except Exception as e:
            result.complete(False, {"exception_type": type(e).__name__}, str(e))
            print(f"❌ 数据验证测试异常: {e}")
        
        return result
    
    async def run_error_recovery_test(self) -> TestResult:
        """测试错误处理和恢复机制"""
        result = TestResult("错误处理和恢复测试", "可靠性")
        
        try:
            from common.error_handler import get_error_handler, ErrorContext
            from common.fallback_service import get_fallback_service
            
            print("🔍 测试错误处理和恢复...")
            
            error_handler = get_error_handler()
            fallback_service = get_fallback_service()
            
            # 测试不同类型的错误处理
            error_scenarios = [
                {
                    "name": "AI服务速率限制错误",
                    "error": Exception("Rate limit exceeded (429)"),
                    "context": ErrorContext(user_id=1, operation="ai_completion"),
                    "expected_category": "rate_limit_error"
                },
                {
                    "name": "网络连接错误",
                    "error": Exception("Connection timeout"),
                    "context": ErrorContext(user_id=2, operation="api_request"),
                    "expected_category": "network_error"
                },
                {
                    "name": "数据库连接错误",
                    "error": Exception("Database connection failed"),
                    "context": ErrorContext(user_id=3, operation="database_query"),
                    "expected_category": "database_error"
                }
            ]
            
            error_handling_results = []
            fallback_tests = []
            
            for scenario in error_scenarios:
                # 测试错误处理
                error_info = error_handler.handle_error(scenario["error"], scenario["context"])
                
                error_handling_results.append({
                    "scenario": scenario["name"],
                    "error_code": error_info.code,
                    "category": error_info.category.value,
                    "severity": error_info.severity.value,
                    "fallback_available": error_info.fallback_available,
                    "retry_after": error_info.retry_after,
                    "user_message": error_info.user_message[:50] + "..." if len(error_info.user_message) > 50 else error_info.user_message
                })
                
                # 如果支持降级，测试降级服务
                if error_info.fallback_available:
                    fallback_result = fallback_service.get_barcode_fallback_recommendation(
                        user_id=scenario["context"].user_id,
                        barcode="1234567890123"
                    )
                    
                    fallback_tests.append({
                        "scenario": scenario["name"],
                        "fallback_success": fallback_result["success"],
                        "fallback_mode": fallback_result["data"]["fallbackMode"],
                        "recommendations_count": len(fallback_result["data"]["recommendations"]),
                        "has_analysis": "llmAnalysis" in fallback_result["data"]
                    })
            
            # 获取错误统计
            error_stats = error_handler.get_error_statistics()
            
            success = all(r["error_code"] for r in error_handling_results) and all(f["fallback_success"] for f in fallback_tests)
            
            result.complete(success, {
                "error_scenarios_tested": len(error_scenarios),
                "error_handling_results": error_handling_results,
                "fallback_tests": fallback_tests,
                "error_statistics": error_stats,
                "successful_fallbacks": len([f for f in fallback_tests if f["fallback_success"]])
            })
            
            if success:
                print(f"✅ 错误处理测试通过 - 处理{len(error_scenarios)}种错误场景")
            else:
                print(f"❌ 错误处理测试失败")
                
        except Exception as e:
            result.complete(False, {"exception_type": type(e).__name__}, str(e))
            print(f"❌ 错误处理测试异常: {e}")
        
        return result
    
    async def run_performance_monitoring_test(self) -> TestResult:
        """测试性能监控和健康检查"""
        result = TestResult("性能监控和健康检查测试", "监控")
        
        try:
            from monitoring.performance_monitor import get_performance_monitor
            from monitoring.health_checker import get_health_checker
            
            print("🔍 测试性能监控和健康检查...")
            
            # 性能监控测试
            monitor = get_performance_monitor()
            
            # 模拟一些请求指标
            test_metrics = []
            for i in range(10):
                response_time = 100 + (i * 10)  # 100-190ms
                success = i < 8  # 80%成功率
                monitor.record_request(f"test_request", response_time, success, user_id=(i % 3) + 1)
                test_metrics.append({"response_time": response_time, "success": success})
            
            # 模拟AI请求指标
            for i in range(5):
                ai_response_time = 200 + (i * 20)
                ai_success = i < 4  # 80%成功率
                monitor.record_ai_request(ai_response_time, ai_success, token_usage=50+i*10, cost_usd=0.001*(i+1))
            
            # 更新系统指标
            monitor.update_concurrent_requests(5)
            monitor.update_queue_size(8)
            monitor.update_user_metrics(active_users=3, total_users=5, sessions=3)
            
            # 获取性能报告
            performance_report = monitor.get_performance_report()
            real_time_metrics = monitor.get_real_time_metrics()
            
            # 健康检查测试
            health_checker = get_health_checker()
            
            # 注册测试健康检查
            async def test_healthy_service():
                return {"status": "healthy", "message": "测试服务正常", "response_time": 50}
            
            async def test_degraded_service():
                return {"status": "degraded", "message": "测试服务性能下降", "response_time": 200}
            
            health_checker.register_health_check("test_healthy", test_healthy_service)
            health_checker.register_health_check("test_degraded", test_degraded_service)
            
            # 执行健康检查
            health_results = await health_checker.check_all_services()
            health_summary = health_checker.get_health_summary()
            
            # 验证结果
            performance_valid = (
                performance_report["request_metrics"]["total_requests"] == 10 and
                performance_report["ai_metrics"]["total_ai_requests"] == 5 and
                performance_report["user_metrics"]["active_users"] == 3
            )
            
            health_valid = (
                len(health_results) >= 2 and
                health_summary["total_services"] >= 2
            )
            
            success = performance_valid and health_valid
            
            result.complete(success, {
                "performance_metrics": {
                    "total_requests": performance_report["request_metrics"]["total_requests"],
                    "success_rate": performance_report["request_metrics"]["success_rate"],
                    "ai_requests": performance_report["ai_metrics"]["total_ai_requests"],
                    "total_tokens": performance_report["ai_metrics"]["total_tokens"],
                    "total_cost": performance_report["ai_metrics"]["total_cost_usd"],
                    "active_users": performance_report["user_metrics"]["active_users"],
                    "concurrent_requests": real_time_metrics["current_concurrent_requests"],
                    "queue_size": real_time_metrics["current_queue_size"]
                },
                "health_check_results": {
                    "total_services": health_summary["total_services"],
                    "overall_status": health_summary["overall_status"],
                    "healthy_services": health_summary["status_distribution"].get("healthy", 0),
                    "degraded_services": health_summary["status_distribution"].get("degraded", 0),
                    "unhealthy_services": health_summary["status_distribution"].get("unhealthy", 0)
                },
                "monitoring_capabilities": {
                    "real_time_metrics": True,
                    "historical_data": True,
                    "health_monitoring": True,
                    "alert_system": performance_report.get("alerts", {}).get("active_alerts", 0) >= 0
                }
            })
            
            if success:
                print(f"✅ 监控系统测试通过 - 性能指标和健康检查正常")
            else:
                print(f"❌ 监控系统测试失败")
                
        except Exception as e:
            result.complete(False, {"exception_type": type(e).__name__}, str(e))
            print(f"❌ 监控系统测试异常: {e}")
        
        return result
    
    async def run_end_to_end_workflow_test(self) -> TestResult:
        """测试端到端工作流程"""
        result = TestResult("端到端工作流程测试", "集成")
        
        try:
            print("🔍 测试端到端工作流程...")
            
            # 导入所需模块
            from common.session_manager import get_session_manager
            from common.data_validator import validate_recommendation_request
            from common.request_queue import RequestQueueManager, RequestPriority
            from monitoring.performance_monitor import get_performance_monitor
            
            workflow_steps = []
            
            # 步骤1: 创建用户会话
            session_manager = get_session_manager()
            user_id = 12345
            session_id = session_manager.create_session(
                user_id=user_id,
                user_agent="TestAgent/1.0",
                ip_address="127.0.0.1"
            )
            workflow_steps.append({"step": "创建用户会话", "status": "成功", "session_id": session_id})
            
            # 步骤2: 验证请求数据
            request_data = {
                "userId": user_id,
                "productBarcode": "1234567890123",
                "userPreferences": {
                    "healthGoal": "lose_weight",
                    "allergens": ["nuts"],
                    "dietaryRestrictions": ["vegetarian"]
                }
            }
            
            validation_result = validate_recommendation_request("barcode_recommendation", request_data)
            if validation_result.is_valid:
                workflow_steps.append({"step": "数据验证", "status": "通过", "cleaned_data_keys": list(validation_result.cleaned_data.keys())})
            else:
                workflow_steps.append({"step": "数据验证", "status": "失败", "errors": validation_result.errors})
                raise Exception("数据验证失败")
            
            # 步骤3: 检查重复请求
            is_duplicate = session_manager.check_duplicate_request(user_id, request_data)
            workflow_steps.append({"step": "重复请求检查", "status": "通过" if not is_duplicate else "发现重复", "is_duplicate": is_duplicate})
            
            # 步骤4: 队列处理
            queue_manager = RequestQueueManager(max_concurrent=3, max_queue_size=10)
            
            async def mock_recommendation_processor(data):
                # 模拟AI服务调用
                await asyncio.sleep(0.1)
                
                # 记录AI指标
                monitor = get_performance_monitor()
                monitor.record_ai_request(100, True, token_usage=75, cost_usd=0.0008)
                
                return {
                    "recommendationId": f"rec_{int(time.time())}",
                    "recommendations": [
                        {"productName": "低卡路里燕麦", "reason": "符合减重目标，无坚果成分"},
                        {"productName": "素食蛋白棒", "reason": "素食友好，高蛋白"}
                    ],
                    "llmAnalysis": {
                        "summary": "基于您的减重目标和素食偏好，推荐低热量、高营养密度的食品",
                        "nutritionScore": 85,
                        "healthScore": 90
                    }
                }
            
            queue_manager.register_processor("barcode_recommendation", mock_recommendation_processor)
            await queue_manager.start()
            
            # 步骤5: 提交请求到队列
            start_time = time.time()
            request_id = await queue_manager.enqueue_request(
                user_id=user_id,
                request_type="barcode_recommendation",
                request_data=validation_result.cleaned_data,
                priority=RequestPriority.NORMAL
            )
            workflow_steps.append({"step": "请求入队", "status": "成功", "request_id": request_id})
            
            # 步骤6: 等待处理完成
            await asyncio.sleep(0.5)
            
            # 步骤7: 获取结果
            request_result = await queue_manager.get_request_status(request_id)
            processing_time = (time.time() - start_time) * 1000
            
            if request_result and request_result["status"] == "completed":
                workflow_steps.append({
                    "step": "请求处理", 
                    "status": "完成", 
                    "processing_time_ms": int(processing_time),
                    "has_recommendations": "recommendations" in request_result.get("result", {}),
                    "recommendation_count": len(request_result.get("result", {}).get("recommendations", []))
                })
            else:
                workflow_steps.append({"step": "请求处理", "status": "失败", "result": request_result})
                raise Exception("请求处理失败")
            
            # 步骤8: 更新会话活动
            session_manager.update_session_activity(
                user_id=user_id,
                request_type="barcode_recommendation",
                response_time_ms=int(processing_time),
                success=True
            )
            workflow_steps.append({"step": "会话更新", "status": "完成"})
            
            # 步骤9: 获取最终状态
            session_summary = session_manager.get_session_summary(session_id)
            performance_report = get_performance_monitor().get_performance_report()
            
            await queue_manager.stop()
            
            # 验证工作流程完整性
            expected_steps = ["创建用户会话", "数据验证", "重复请求检查", "请求入队", "请求处理", "会话更新"]
            completed_steps = [step["step"] for step in workflow_steps if step["status"] in ["成功", "完成", "通过"]]
            
            success = all(step in completed_steps for step in expected_steps)
            
            result.complete(success, {
                "workflow_steps": workflow_steps,
                "total_steps": len(workflow_steps),
                "successful_steps": len([s for s in workflow_steps if s["status"] in ["成功", "完成", "通过"]]),
                "processing_time_ms": int(processing_time),
                "session_summary": {
                    "request_count": session_summary["request_count"],
                    "success_rate": session_summary["success_rate"]
                },
                "final_metrics": {
                    "total_requests": performance_report["request_metrics"]["total_requests"],
                    "ai_requests": performance_report["ai_metrics"]["total_ai_requests"],
                    "tokens_used": performance_report["ai_metrics"]["total_tokens"],
                    "estimated_cost": performance_report["ai_metrics"]["total_cost_usd"]
                }
            })
            
            if success:
                print(f"✅ 端到端工作流程测试通过 - {len(completed_steps)}/{len(expected_steps)}个步骤完成")
            else:
                print(f"❌ 端到端工作流程测试失败")
                
        except Exception as e:
            result.complete(False, {"exception_type": type(e).__name__}, str(e))
            print(f"❌ 端到端工作流程测试异常: {e}")
        
        return result
    
    async def run_all_tests(self):
        """运行所有测试"""
        print("🚀 开始Grocery Guardian Recommendation模块生产环境完整测试")
        print("=" * 80)
        print(f"测试开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"测试环境: {self.environment_info['environment']}")
        print("=" * 80)
        
        # 定义所有测试
        test_functions = [
            ("Azure OpenAI集成", self.run_azure_openai_integration_test),
            ("多用户并发处理", self.run_concurrent_processing_test),
            ("数据验证和安全", self.run_data_validation_security_test),
            ("错误处理和恢复", self.run_error_recovery_test),
            ("性能监控和健康检查", self.run_performance_monitoring_test),
            ("端到端工作流程", self.run_end_to_end_workflow_test),
        ]
        
        # 执行所有测试
        for test_name, test_func in test_functions:
            print(f"\n📋 执行测试: {test_name}")
            print("-" * 60)
            
            try:
                test_result = await test_func()
                self.test_results.append(test_result)
                
                if test_result.success:
                    print(f"✅ {test_name} - 通过 (耗时: {test_result.duration_ms}ms)")
                else:
                    print(f"❌ {test_name} - 失败 (耗时: {test_result.duration_ms}ms)")
                    if test_result.error_message:
                        print(f"   错误: {test_result.error_message}")
                        
            except Exception as e:
                # 创建失败的测试结果
                failed_result = TestResult(test_name, "未知")
                failed_result.complete(False, {"exception_type": type(e).__name__}, str(e))
                self.test_results.append(failed_result)
                print(f"❌ {test_name} - 异常: {e}")
        
        # 计算总体统计
        self._calculate_test_summary()
        
        # 生成测试报告
        report = self._generate_comprehensive_report()
        
        # 保存报告
        report_file = self._save_test_report(report)
        
        print("\n" + "=" * 80)
        print("🎯 测试完成总结")
        print("=" * 80)
        print(f"总测试数: {self.test_summary['total_tests']}")
        print(f"通过: {self.test_summary['passed_tests']}")
        print(f"失败: {self.test_summary['failed_tests']}")
        print(f"成功率: {(self.test_summary['passed_tests']/self.test_summary['total_tests']*100):.1f}%")
        print(f"测试报告已保存: {report_file}")
        
        if self.test_summary['failed_tests'] == 0:
            print("🎉 所有测试通过！Recommendation模块生产环境优化完成，可以投入使用。")
            self.test_summary['system_status'] = "ready_for_production"
        else:
            print(f"⚠️ 有 {self.test_summary['failed_tests']} 个测试失败，请检查相关功能。")
            self.test_summary['system_status'] = "needs_attention"
        
        return self.test_summary['failed_tests'] == 0
    
    def _calculate_test_summary(self):
        """计算测试摘要"""
        self.test_summary['total_tests'] = len(self.test_results)
        self.test_summary['passed_tests'] = len([r for r in self.test_results if r.success])
        self.test_summary['failed_tests'] = len([r for r in self.test_results if not r.success])
        
        # 按类别统计
        for result in self.test_results:
            category = result.category
            if category not in self.test_summary['categories']:
                self.test_summary['categories'][category] = {'total': 0, 'passed': 0, 'failed': 0}
            
            self.test_summary['categories'][category]['total'] += 1
            if result.success:
                self.test_summary['categories'][category]['passed'] += 1
            else:
                self.test_summary['categories'][category]['failed'] += 1
        
        # 性能指标汇总
        total_duration = sum([r.duration_ms for r in self.test_results])
        self.test_summary['performance_metrics'] = {
            'total_test_duration_ms': total_duration,
            'average_test_duration_ms': total_duration / len(self.test_results) if self.test_results else 0,
            'fastest_test_ms': min([r.duration_ms for r in self.test_results]) if self.test_results else 0,
            'slowest_test_ms': max([r.duration_ms for r in self.test_results]) if self.test_results else 0
        }
    
    def _generate_comprehensive_report(self) -> str:
        """生成完整的中文测试报告"""
        report_lines = []
        
        # 报告标题
        report_lines.extend([
            "# Grocery Guardian Recommendation模块生产环境测试报告",
            "",
            f"**生成时间**: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}",
            f"**测试版本**: ProductionTestSuite v1.0",
            f"**测试环境**: {self.environment_info['environment']}",
            "",
            "## 执行摘要",
            "",
            f"本次测试对Grocery Guardian项目的Recommendation模块进行了全面的生产环境验证，涵盖了Azure OpenAI集成、多用户并发处理、数据安全验证、错误处理恢复、性能监控以及端到端工作流程等6个核心功能领域。",
            "",
            f"- **总测试数**: {self.test_summary['total_tests']}项",
            f"- **通过测试**: {self.test_summary['passed_tests']}项",
            f"- **失败测试**: {self.test_summary['failed_tests']}项", 
            f"- **成功率**: {(self.test_summary['passed_tests']/self.test_summary['total_tests']*100):.1f}%",
            f"- **系统状态**: {'✅ 生产就绪' if self.test_summary['system_status'] == 'ready_for_production' else '⚠️ 需要关注'}",
            "",
        ])
        
        # 测试环境信息
        report_lines.extend([
            "## 测试环境信息",
            "",
            f"- **Python版本**: {self.environment_info['python_version'].split()[0]}",
            f"- **Azure OpenAI配置**: {'✅ 已配置' if self.environment_info['azure_openai_configured'] else '❌ 未配置'}",
            f"- **OpenAI备用配置**: {'✅ 已配置' if self.environment_info['openai_fallback_configured'] else '❌ 未配置'}",
            f"- **测试开始时间**: {self.environment_info['test_start_time']}",
            "",
        ])
        
        # 按类别统计
        report_lines.extend([
            "## 测试类别统计",
            "",
            "| 测试类别 | 总数 | 通过 | 失败 | 成功率 |",
            "|---------|------|------|------|--------|"
        ])
        
        for category, stats in self.test_summary['categories'].items():
            success_rate = (stats['passed'] / stats['total'] * 100) if stats['total'] > 0 else 0
            report_lines.append(f"| {category} | {stats['total']} | {stats['passed']} | {stats['failed']} | {success_rate:.1f}% |")
        
        report_lines.append("")
        
        # 详细测试结果
        report_lines.extend([
            "## 详细测试结果",
            ""
        ])
        
        for i, result in enumerate(self.test_results, 1):
            status_icon = "✅" if result.success else "❌"
            report_lines.extend([
                f"### {i}. {result.test_name} {status_icon}",
                "",
                f"- **测试类别**: {result.category}",
                f"- **执行时间**: {result.duration_ms}ms",
                f"- **测试结果**: {'通过' if result.success else '失败'}",
            ])
            
            if result.error_message:
                report_lines.append(f"- **错误信息**: {result.error_message}")
            
            # 添加详细结果
            if result.details:
                report_lines.append("- **详细信息**:")
                for key, value in result.details.items():
                    if isinstance(value, dict):
                        report_lines.append(f"  - **{key}**:")
                        for sub_key, sub_value in value.items():
                            report_lines.append(f"    - {sub_key}: {sub_value}")
                    elif isinstance(value, list):
                        report_lines.append(f"  - **{key}**: {len(value)}项")
                        for item in value[:3]:  # 只显示前3项
                            if isinstance(item, dict):
                                item_summary = ", ".join([f"{k}: {v}" for k, v in list(item.items())[:2]])  # 只显示前2个字段
                                report_lines.append(f"    - {item_summary}")
                            else:
                                report_lines.append(f"    - {item}")
                        if len(value) > 3:
                            report_lines.append(f"    - ... (还有{len(value)-3}项)")
                    else:
                        report_lines.append(f"  - **{key}**: {value}")
            
            report_lines.append("")
        
        # 性能指标分析
        report_lines.extend([
            "## 性能指标分析",
            "",
            f"- **总测试耗时**: {self.test_summary['performance_metrics']['total_test_duration_ms']}ms ({self.test_summary['performance_metrics']['total_test_duration_ms']/1000:.1f}秒)",
            f"- **平均测试耗时**: {self.test_summary['performance_metrics']['average_test_duration_ms']:.1f}ms",
            f"- **最快测试**: {self.test_summary['performance_metrics']['fastest_test_ms']}ms",
            f"- **最慢测试**: {self.test_summary['performance_metrics']['slowest_test_ms']}ms",
            "",
        ])
        
        # 生产就绪评估
        report_lines.extend([
            "## 生产就绪评估",
            "",
        ])
        
        if self.test_summary['system_status'] == 'ready_for_production':
            report_lines.extend([
                "### ✅ 系统生产就绪",
                "",
                "所有核心功能测试通过，系统具备以下生产能力：",
                "",
                "1. **AI服务集成**: Azure OpenAI集成正常，支持实际的AI推荐生成",
                "2. **并发处理**: 支持多用户并发访问，队列管理工作正常",
                "3. **数据安全**: 输入验证和安全过滤机制有效防护",
                "4. **错误恢复**: 完善的错误处理和自动降级机制",
                "5. **性能监控**: 实时性能指标收集和健康状态监控",
                "6. **端到端流程**: 完整的请求处理工作流程验证通过",
                "",
                "**建议**: 系统可以部署到生产环境，建议进行负载测试以验证高并发性能。",
                ""
            ])
        else:
            failed_tests = [r for r in self.test_results if not r.success]
            report_lines.extend([
                "### ⚠️ 系统需要关注",
                "",
                f"有{len(failed_tests)}个测试失败，需要修复以下问题：",
                ""
            ])
            
            for failed_test in failed_tests:
                report_lines.extend([
                    f"- **{failed_test.test_name}**: {failed_test.error_message}",
                ])
            
            report_lines.extend([
                "",
                "**建议**: 修复失败的测试项目后重新进行测试验证。",
                ""
            ])
        
        # 技术架构说明
        report_lines.extend([
            "## 技术架构说明",
            "",
            "### 核心组件",
            "",
            "1. **Azure OpenAI客户端** (`llm_evaluation/azure_openai_client.py`)",
            "   - 提供Azure OpenAI服务集成",
            "   - 支持自动重试和错误处理",
            "   - 实时使用统计和成本跟踪",
            "",
            "2. **请求队列管理器** (`common/request_queue.py`)",
            "   - 异步请求处理和并发控制",
            "   - 用户级别的速率限制",
            "   - 优先级队列和重复请求检测",
            "",
            "3. **数据验证器** (`common/data_validator.py`)",
            "   - 全面的输入数据验证和清理",
            "   - 安全过滤和恶意输入检测",
            "   - 支持多种请求类型验证",
            "",
            "4. **错误处理器** (`common/error_handler.py`)",
            "   - 统一的错误分类和处理",
            "   - 自动错误恢复和重试机制",
            "   - 错误统计和模式分析",
            "",
            "5. **降级服务** (`common/fallback_service.py`)",
            "   - 基于规则的备用推荐服务",
            "   - AI服务不可用时的自动降级",
            "   - 保证系统基础可用性",
            "",
            "6. **性能监控器** (`monitoring/performance_monitor.py`)",
            "   - 实时性能指标收集",
            "   - 系统资源监控和告警",
            "   - 历史数据存储和分析",
            "",
            "7. **健康检查器** (`monitoring/health_checker.py`)",
            "   - 服务健康状态监控",
            "   - 自动健康检查调度",
            "   - 系统整体健康评估",
            "",
        ])
        
        # 部署建议
        report_lines.extend([
            "## 部署建议",
            "",
            "### 环境变量配置",
            "",
            "确保以下环境变量正确配置：",
            "",
            "```bash",
            "# Azure OpenAI配置（主要）",
            "AZURE_OPENAI_API_KEY=your_azure_api_key",
            "AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/",
            "AZURE_OPENAI_API_VERSION=2024-02-01",
            "AZURE_OPENAI_MODEL=gpt-4o-mini-prod",
            "",
            "# OpenAI配置（备用）",
            "OPENAI_API_KEY=your_openai_api_key",
            "",
            "# 性能配置",
            "MAX_CONCURRENT_REQUESTS=15",
            "MAX_QUEUE_SIZE=200",
            "REQUEST_TIMEOUT=45",
            "",
            "# 监控配置",
            "MONITORING_ENABLED=true",
            "METRICS_COLLECTION_INTERVAL=60",
            "```",
            "",
            "### 容量规划",
            "",
            "- **并发用户**: 建议初始配置支持100+并发用户",
            "- **请求处理**: 15个并发AI请求，队列容量200",
            "- **响应时间**: 95%请求在3秒内完成",
            "- **成本控制**: Azure OpenAI按token计费，建议设置预算告警",
            "",
        ])
        
        # 监控和维护
        report_lines.extend([
            "## 监控和维护",
            "",
            "### 关键指标监控",
            "",
            "1. **性能指标**",
            "   - 请求成功率 (目标: >99%)",
            "   - 平均响应时间 (目标: <2秒)",
            "   - 并发请求数量",
            "   - 队列大小和处理速度",
            "",
            "2. **AI服务指标**",
            "   - Token使用量和成本",
            "   - AI请求成功率",
            "   - 模型响应时间",
            "   - 降级服务使用频率",
            "",
            "3. **系统资源**",
            "   - CPU和内存使用率",
            "   - 网络IO和磁盘使用",
            "   - 数据库连接池状态",
            "",
            "### 日常维护任务",
            "",
            "- 定期检查错误日志和告警",
            "- 监控AI服务成本和使用配额",
            "- 更新安全过滤规则",
            "- 备份性能指标和配置",
            "",
        ])
        
        # 报告结尾
        report_lines.extend([
            "---",
            "",
            f"**报告生成**: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}",
            f"**测试工具**: Grocery Guardian生产测试套件 v1.0",
            f"**联系信息**: 如有问题请联系开发团队",
            ""
        ])
        
        return "\n".join(report_lines)
    
    def _save_test_report(self, report_content: str) -> str:
        """保存测试报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_filename = f"recommendation_production_test_report_{timestamp}.md"
        report_path = os.path.join(os.path.dirname(__file__), report_filename)
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(report_content)
        
        return report_path

async def main():
    """主函数"""
    # 自动设置环境变量（从Docker配置中获取）
    if not os.getenv("AZURE_OPENAI_API_KEY"):
        os.environ["AZURE_OPENAI_API_KEY"] = "73540b77e3304ee8b9614e8593f08f02"
    if not os.getenv("AZURE_OPENAI_ENDPOINT"):
        os.environ["AZURE_OPENAI_ENDPOINT"] = "https://xiangopenai2025.openai.azure.com/"
    if not os.getenv("AZURE_OPENAI_API_VERSION"):
        os.environ["AZURE_OPENAI_API_VERSION"] = "2024-02-01"
    if not os.getenv("AZURE_OPENAI_MODEL"):
        os.environ["AZURE_OPENAI_MODEL"] = "gpt-4o-mini-prod"
    if not os.getenv("OPENAI_API_KEY"):
        os.environ["OPENAI_API_KEY"] = "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"
    if not os.getenv("ENVIRONMENT"):
        os.environ["ENVIRONMENT"] = "java_integration"
    
    print("🔧 环境变量已自动配置")
    
    # 创建测试套件并运行
    test_suite = ProductionTestSuite()
    success = await test_suite.run_all_tests()
    
    return success

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)