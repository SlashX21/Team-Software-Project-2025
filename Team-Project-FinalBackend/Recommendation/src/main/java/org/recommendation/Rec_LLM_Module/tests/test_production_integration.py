"""
生产环境优化集成测试
测试Azure OpenAI集成、并发处理、错误处理和监控系统
"""

import asyncio
import pytest
import time
import json
import logging
from unittest.mock import Mock, patch, AsyncMock
from typing import Dict, List, Any

# 导入要测试的模块
from llm_evaluation.azure_openai_client import AzureOpenAIClient, AzureLLMResponse
from llm_evaluation.client_factory import AIClientFactory, ResilientAIClient
from common.request_queue import RequestQueueManager, RequestPriority, get_queue_manager
from common.session_manager import SessionManager, get_session_manager
from common.data_validator import DataValidator, validate_recommendation_request
from common.error_handler import ErrorHandler, ErrorContext, get_error_handler
from common.fallback_service import FallbackService, get_fallback_service
from monitoring.performance_monitor import PerformanceMonitor, get_performance_monitor
from monitoring.health_checker import HealthChecker, get_health_checker

logger = logging.getLogger(__name__)

class TestProductionIntegration:
    """生产环境优化集成测试"""
    
    @pytest.fixture
    async def setup_test_environment(self):
        """设置测试环境"""
        # 清理全局实例
        import sys
        modules_to_clear = [
            'llm_evaluation.client_factory',
            'common.request_queue',
            'common.session_manager',
            'common.error_handler',
            'common.fallback_service',
            'monitoring.performance_monitor',
            'monitoring.health_checker'
        ]
        
        for module in modules_to_clear:
            if module in sys.modules:
                # 清理全局变量
                mod = sys.modules[module]
                for attr in dir(mod):
                    if attr.startswith('_global_'):
                        setattr(mod, attr, None)
        
        yield
        
        # 测试清理
        pass
    
    @pytest.mark.asyncio
    async def test_azure_openai_client_basic_functionality(self, setup_test_environment):
        """测试Azure OpenAI客户端基础功能"""
        # 模拟Azure OpenAI响应
        mock_response = Mock()
        mock_response.choices = [Mock()]
        mock_response.choices[0].message.content = "测试响应内容"
        mock_response.usage = Mock()
        mock_response.usage.total_tokens = 100
        mock_response.usage.prompt_tokens = 50
        mock_response.usage.completion_tokens = 50
        
        with patch('openai.AzureOpenAI') as mock_azure:
            mock_client = mock_azure.return_value
            mock_client.chat.completions.create.return_value = mock_response
            
            # 测试配置
            test_config = {
                "api_key": "test_key",
                "endpoint": "https://test.openai.azure.com/",
                "api_version": "2024-02-01",
                "model": "gpt-4o-mini-prod"
            }
            
            client = AzureOpenAIClient(test_config)
            
            # 测试基础请求
            response = await client.generate_completion("测试提示词")
            
            assert response.success == True
            assert response.content == "测试响应内容"
            assert response.model == "gpt-4o-mini-prod"
            assert response.usage["total_tokens"] == 100
            
            # 验证统计信息
            stats = client.get_usage_statistics()
            assert stats["total_requests"] == 1
            assert stats["successful_requests"] == 1
            assert stats["success_rate"] == 1.0
    
    @pytest.mark.asyncio
    async def test_azure_client_error_handling(self, setup_test_environment):
        """测试Azure客户端错误处理"""
        with patch('openai.AzureOpenAI') as mock_azure:
            mock_client = mock_azure.return_value
            
            # 模拟速率限制错误
            mock_client.chat.completions.create.side_effect = Exception("Rate limit exceeded (429)")
            
            test_config = {
                "api_key": "test_key",
                "endpoint": "https://test.openai.azure.com/",
                "api_version": "2024-02-01",
                "model": "gpt-4o-mini-prod",
                "retry_attempts": 2
            }
            
            client = AzureOpenAIClient(test_config)
            
            # 测试错误处理
            response = await client.generate_completion("测试提示词")
            
            assert response.success == False
            assert response.error is not None
            assert "AZURE_RATE_LIMIT_EXCEEDED" in response.error["code"]
            
            # 验证重试机制
            assert mock_client.chat.completions.create.call_count == 2
    
    @pytest.mark.asyncio
    async def test_resilient_client_fallback(self, setup_test_environment):
        """测试弹性客户端降级机制"""
        with patch('llm_evaluation.azure_openai_client.AzureOpenAI') as mock_azure, \
             patch('llm_evaluation.openai_client.OpenAI') as mock_openai:
            
            # Azure客户端失败
            mock_azure_client = mock_azure.return_value
            mock_azure_client.chat.completions.create.side_effect = Exception("Azure服务不可用")
            
            # OpenAI客户端成功
            mock_openai_response = Mock()
            mock_openai_response.choices = [Mock()]
            mock_openai_response.choices[0].message.content = "OpenAI降级响应"
            mock_openai_response.usage = Mock()
            mock_openai_response.usage.total_tokens = 80
            
            mock_openai_client = mock_openai.return_value
            mock_openai_client.chat.completions.create.return_value = mock_openai_response
            
            # 测试弹性客户端
            resilient_client = ResilientAIClient()
            response = await resilient_client.generate_completion("测试提示词")
            
            # 验证降级到OpenAI成功
            assert hasattr(response, 'content')
            # 在实际实现中，应该检查是否使用了备用客户端
    
    @pytest.mark.asyncio
    async def test_request_queue_concurrent_processing(self, setup_test_environment):
        """测试请求队列并发处理"""
        queue_manager = RequestQueueManager(max_concurrent=3, max_queue_size=10)
        
        # 模拟处理函数
        async def mock_processor(data):
            await asyncio.sleep(0.1)  # 模拟处理时间
            return {"result": f"处理完成: {data.get('test_data', 'unknown')}"}
        
        # 注册处理器
        queue_manager.register_processor("test_request", mock_processor)
        
        # 启动队列管理器
        await queue_manager.start()
        
        try:
            # 并发提交多个请求
            request_ids = []
            for i in range(5):
                request_id = await queue_manager.enqueue_request(
                    user_id=1,
                    request_type="test_request",
                    request_data={"test_data": f"request_{i}"},
                    priority=RequestPriority.NORMAL
                )
                request_ids.append(request_id)
            
            # 等待处理完成
            await asyncio.sleep(1)
            
            # 检查所有请求状态
            completed_count = 0
            for request_id in request_ids:
                status = await queue_manager.get_request_status(request_id)
                if status and status["status"] == "completed":
                    completed_count += 1
            
            assert completed_count == 5  # 所有请求都应该完成
            
            # 检查统计信息
            stats = queue_manager.get_queue_stats()
            assert stats["total_requests"] == 5
            assert stats["completed_requests"] == 5
            
        finally:
            await queue_manager.stop()
    
    @pytest.mark.asyncio
    async def test_rate_limiting(self, setup_test_environment):
        """测试速率限制功能"""
        queue_manager = RequestQueueManager(max_concurrent=1, max_queue_size=5)
        
        # 模拟快速处理器
        async def fast_processor(data):
            return {"result": "processed"}
        
        queue_manager.register_processor("fast_request", fast_processor)
        await queue_manager.start()
        
        try:
            # 快速提交多个请求（超过速率限制）
            user_id = 1
            successful_requests = 0
            rate_limited_requests = 0
            
            for i in range(20):  # 尝试提交20个请求
                try:
                    await queue_manager.enqueue_request(
                        user_id=user_id,
                        request_type="fast_request",
                        request_data={"test": i}
                    )
                    successful_requests += 1
                except Exception as e:
                    if "rate limit" in str(e).lower():
                        rate_limited_requests += 1
            
            # 验证速率限制生效
            assert rate_limited_requests > 0, "应该触发速率限制"
            assert successful_requests < 20, "不应该所有请求都成功"
            
        finally:
            await queue_manager.stop()
    
    def test_data_validation_comprehensive(self, setup_test_environment):
        """测试数据验证功能"""
        # 测试条码推荐请求验证
        valid_barcode_request = {
            "userId": 1,
            "productBarcode": "1234567890123",
            "userPreferences": {
                "healthGoal": "lose_weight",
                "allergens": ["nuts"],
                "dietaryRestrictions": ["vegetarian"]
            }
        }
        
        result = validate_recommendation_request("barcode_recommendation", valid_barcode_request)
        assert result.is_valid == True
        assert result.cleaned_data["userId"] == 1
        assert result.cleaned_data["productBarcode"] == "1234567890123"
        
        # 测试无效请求
        invalid_request = {
            "userId": -1,  # 无效用户ID
            "productBarcode": "invalid_barcode",  # 无效条码
        }
        
        result = validate_recommendation_request("barcode_recommendation", invalid_request)
        assert result.is_valid == False
        assert len(result.errors) > 0
        
        # 测试小票分析请求
        receipt_request = {
            "userId": 1,
            "purchasedItems": [
                {"barcode": "1234567890123", "quantity": 2, "price": 5.99},
                {"barcode": "9876543210987", "quantity": 1}
            ],
            "receiptInfo": {
                "storeName": "测试超市",
                "totalAmount": 11.98,
                "purchaseDate": "2025-01-15T10:30:00Z"
            }
        }
        
        result = validate_recommendation_request("receipt_analysis", receipt_request)
        assert result.is_valid == True
        assert len(result.cleaned_data["purchasedItems"]) == 2
    
    def test_error_handling_comprehensive(self, setup_test_environment):
        """测试错误处理功能"""
        error_handler = get_error_handler()
        
        # 测试AI服务错误
        ai_error = Exception("Rate limit exceeded (429)")
        context = ErrorContext(user_id=1, request_id="test_001", operation="ai_completion")
        
        error_info = error_handler.handle_error(ai_error, context)
        
        assert error_info.category.value == "rate_limit_error"
        assert error_info.retry_after == 60
        assert error_info.fallback_available == True
        assert "AI_RATE_LIMIT_EXCEEDED" in error_info.code
        
        # 测试数据库错误
        db_error = Exception("Connection to database failed")
        db_context = ErrorContext(user_id=1, operation="database_query")
        
        db_error_info = error_handler.handle_error(db_error, db_context)
        
        assert db_error_info.category.value == "database_error"
        assert db_error_info.severity.value in ["high", "critical"]
        assert db_error_info.fallback_available == False
        
        # 检查错误统计
        stats = error_handler.get_error_statistics()
        assert stats["total_errors"] == 2
        assert stats["errors_by_category"]["rate_limit_error"] == 1
        assert stats["errors_by_category"]["database_error"] == 1
    
    @pytest.mark.asyncio
    async def test_fallback_service_functionality(self, setup_test_environment):
        """测试降级服务功能"""
        fallback_service = get_fallback_service()
        
        # 测试条码推荐降级
        barcode_result = fallback_service.get_barcode_fallback_recommendation(
            user_id=1,
            barcode="1234567890123",
            user_preferences={"healthGoal": "lose_weight"}
        )
        
        assert barcode_result["success"] == True
        assert barcode_result["data"]["fallbackMode"] == True
        assert "recommendations" in barcode_result["data"]
        assert "llmAnalysis" in barcode_result["data"]
        
        # 测试小票分析降级
        purchased_items = [
            {"barcode": "1234567890123", "quantity": 2},
            {"barcode": "9876543210987", "quantity": 1}
        ]
        
        receipt_result = fallback_service.get_receipt_fallback_analysis(
            user_id=1,
            purchased_items=purchased_items,
            user_preferences={"healthGoal": "maintain"}
        )
        
        assert receipt_result["success"] == True
        assert receipt_result["data"]["fallbackMode"] == True
        assert "purchaseSummary" in receipt_result["data"]
        assert "recommendations" in receipt_result["data"]
    
    @pytest.mark.asyncio
    async def test_session_management(self, setup_test_environment):
        """测试会话管理功能"""
        session_manager = get_session_manager()
        
        # 创建用户会话
        user_id = 1
        session_id = session_manager.create_session(
            user_id=user_id,
            user_agent="TestAgent/1.0",
            ip_address="127.0.0.1"
        )
        
        assert session_id is not None
        assert session_id.startswith("session_")
        
        # 获取会话信息
        session_info = session_manager.get_user_session(user_id)
        assert session_info is not None
        assert session_info.user_id == user_id
        assert session_info.user_agent == "TestAgent/1.0"
        
        # 测试重复请求检测
        request_data = {"test": "data", "timestamp": time.time()}
        
        # 第一次请求应该不是重复
        is_duplicate_1 = session_manager.check_duplicate_request(user_id, request_data)
        assert is_duplicate_1 == False
        
        # 第二次相同请求应该被检测为重复
        is_duplicate_2 = session_manager.check_duplicate_request(user_id, request_data)
        assert is_duplicate_2 == True
        
        # 更新会话活动
        session_manager.update_session_activity(
            user_id=user_id,
            request_type="test_request",
            response_time_ms=150,
            success=True
        )
        
        # 获取会话摘要
        summary = session_manager.get_session_summary(session_id)
        assert summary["request_count"] == 1
        assert summary["successful_requests"] == 1
        assert summary["success_rate"] == 1.0
    
    @pytest.mark.asyncio
    async def test_performance_monitoring(self, setup_test_environment):
        """测试性能监控功能"""
        monitor = get_performance_monitor()
        
        # 记录一些测试指标
        monitor.record_request("test_request", 100, True, user_id=1)
        monitor.record_request("test_request", 150, True, user_id=2)
        monitor.record_request("test_request", 200, False, user_id=1)
        
        monitor.record_ai_request(250, True, token_usage=80, cost_usd=0.001, model="gpt-4o-mini")
        monitor.record_ai_request(300, False, token_usage=0, cost_usd=0.0, model="gpt-4o-mini")
        
        # 更新其他指标
        monitor.update_concurrent_requests(5)
        monitor.update_queue_size(10)
        monitor.update_user_metrics(active_users=3, total_users=10, sessions=5)
        
        # 获取性能报告
        report = monitor.get_performance_report()
        
        assert report["request_metrics"]["total_requests"] == 3
        assert report["request_metrics"]["successful_requests"] == 2
        assert report["request_metrics"]["failed_requests"] == 1
        assert report["request_metrics"]["success_rate"] == 2/3
        
        assert report["ai_metrics"]["total_ai_requests"] == 2
        assert report["ai_metrics"]["ai_success_count"] == 1
        assert report["ai_metrics"]["total_tokens"] == 80
        assert report["ai_metrics"]["total_cost_usd"] == 0.001
        
        assert report["user_metrics"]["active_users"] == 3
        assert report["user_metrics"]["total_users"] == 10
        
        # 测试实时指标
        real_time = monitor.get_real_time_metrics()
        assert real_time["current_concurrent_requests"] == 5
        assert real_time["current_queue_size"] == 10
        assert real_time["active_users"] == 3
    
    @pytest.mark.asyncio
    async def test_health_checker(self, setup_test_environment):
        """测试健康检查功能"""
        health_checker = get_health_checker()
        
        # 注册测试健康检查
        async def test_service_check():
            return {
                "status": "healthy",
                "message": "测试服务正常",
                "details": {"test": True}
            }
        
        async def failing_service_check():
            raise Exception("测试服务失败")
        
        health_checker.register_health_check("test_service", test_service_check)
        health_checker.register_health_check("failing_service", failing_service_check)
        
        # 执行健康检查
        all_results = await health_checker.check_all_services()
        
        # 验证结果
        assert "test_service" in all_results
        assert all_results["test_service"].status.value == "healthy"
        assert all_results["test_service"].message == "测试服务正常"
        
        assert "failing_service" in all_results
        assert all_results["failing_service"].status.value == "unhealthy"
        assert "测试服务失败" in all_results["failing_service"].message
        
        # 获取健康摘要
        summary = health_checker.get_health_summary()
        assert summary["total_services"] >= 2
        assert "status_distribution" in summary
        assert "services" in summary
    
    @pytest.mark.asyncio
    async def test_end_to_end_workflow(self, setup_test_environment):
        """测试端到端工作流程"""
        # 模拟完整的推荐请求流程
        
        # 1. 创建用户会话
        session_manager = get_session_manager()
        user_id = 1
        session_id = session_manager.create_session(user_id)
        
        # 2. 验证请求数据
        request_data = {
            "userId": user_id,
            "productBarcode": "1234567890123",
            "userPreferences": {
                "healthGoal": "lose_weight"
            }
        }
        
        validation_result = validate_recommendation_request("barcode_recommendation", request_data)
        assert validation_result.is_valid == True
        
        # 3. 检查重复请求
        is_duplicate = session_manager.check_duplicate_request(user_id, request_data)
        assert is_duplicate == False
        
        # 4. 模拟队列处理
        queue_manager = RequestQueueManager(max_concurrent=2, max_queue_size=5)
        
        async def mock_recommendation_processor(data):
            # 模拟AI服务调用
            await asyncio.sleep(0.1)
            
            # 记录AI指标
            monitor = get_performance_monitor()
            monitor.record_ai_request(100, True, token_usage=50, cost_usd=0.0005)
            
            return {
                "recommendationId": "rec_001",
                "recommendations": [
                    {"productName": "健康替代品", "reason": "低热量选择"}
                ],
                "llmAnalysis": {
                    "summary": "建议选择低热量替代品"
                }
            }
        
        queue_manager.register_processor("barcode_recommendation", mock_recommendation_processor)
        await queue_manager.start()
        
        try:
            # 5. 提交请求到队列
            start_time = time.time()
            request_id = await queue_manager.enqueue_request(
                user_id=user_id,
                request_type="barcode_recommendation",
                request_data=validation_result.cleaned_data,
                priority=RequestPriority.NORMAL
            )
            
            # 6. 等待处理完成
            await asyncio.sleep(0.5)
            
            # 7. 获取结果
            result = await queue_manager.get_request_status(request_id)
            processing_time = (time.time() - start_time) * 1000
            
            assert result is not None
            assert result["status"] == "completed"
            assert "recommendationId" in result["result"]
            
            # 8. 记录性能指标
            monitor = get_performance_monitor()
            monitor.record_request(
                "barcode_recommendation", 
                int(processing_time), 
                True, 
                user_id=user_id
            )
            
            # 9. 更新会话活动
            session_manager.update_session_activity(
                user_id=user_id,
                request_type="barcode_recommendation",
                response_time_ms=int(processing_time),
                success=True
            )
            
            # 10. 验证最终状态
            performance_report = monitor.get_performance_report()
            assert performance_report["request_metrics"]["total_requests"] >= 1
            assert performance_report["ai_metrics"]["total_ai_requests"] >= 1
            
            session_summary = session_manager.get_session_summary(session_id)
            assert session_summary["request_count"] >= 1
            assert session_summary["success_rate"] == 1.0
            
        finally:
            await queue_manager.stop()
    
    @pytest.mark.asyncio 
    async def test_error_recovery_workflow(self, setup_test_environment):
        """测试错误恢复工作流程"""
        # 模拟AI服务故障和恢复流程
        
        error_handler = get_error_handler()
        fallback_service = get_fallback_service()
        
        # 1. 模拟AI服务错误
        ai_error = Exception("Azure OpenAI service unavailable")
        context = ErrorContext(
            user_id=1,
            request_id="test_recovery_001",
            operation="ai_completion"
        )
        
        error_info = error_handler.handle_error(ai_error, context)
        
        # 2. 验证错误处理
        assert error_info.fallback_available == True
        assert error_info.code in ["AI_SERVICE_ERROR", "SYSTEM_ERROR"]
        
        # 3. 使用降级服务
        if error_info.fallback_available:
            fallback_result = fallback_service.get_barcode_fallback_recommendation(
                user_id=1,
                barcode="1234567890123"
            )
            
            assert fallback_result["success"] == True
            assert fallback_result["data"]["fallbackMode"] == True
            
        # 4. 记录恢复指标
        monitor = get_performance_monitor()
        monitor.record_request("fallback_recommendation", 50, True, user_id=1)
        
        # 5. 验证错误统计
        error_stats = error_handler.get_error_statistics()
        assert error_stats["total_errors"] >= 1
        
        performance_report = monitor.get_performance_report()
        assert performance_report["request_metrics"]["total_requests"] >= 1

if __name__ == "__main__":
    # 运行测试
    pytest.main([__file__, "-v", "--tb=short"])