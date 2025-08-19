"""
生产环境优化测试运行器
简化的测试执行脚本，验证核心功能
"""

import asyncio
import sys
import os
import logging
from datetime import datetime

# 添加模块路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_azure_openai_config():
    """测试Azure OpenAI配置"""
    try:
        from llm_evaluation.azure_openai_client import AzureOpenAIClient
        
        # 测试配置加载
        client = AzureOpenAIClient()
        config = client.config
        
        assert config["api_key"] is not None, "Azure API密钥未配置"
        assert config["endpoint"] is not None, "Azure端点未配置"
        assert config["model"] is not None, "Azure模型未配置"
        
        logger.info("✓ Azure OpenAI配置测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ Azure OpenAI配置测试失败: {e}")
        return False

async def test_client_factory():
    """测试客户端工厂"""
    try:
        # 设置测试环境变量
        os.environ.setdefault("OPENAI_API_KEY", "test_key_for_fallback")
        
        from llm_evaluation.client_factory import AIClientFactory
        
        # 测试创建Azure客户端
        azure_client = AIClientFactory.create_client("azure")
        assert azure_client is not None, "Azure客户端创建失败"
        
        # 测试弹性客户端
        resilient_client = AIClientFactory.create_resilient_client()
        assert resilient_client is not None, "弹性客户端创建失败"
        
        logger.info("✓ 客户端工厂测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 客户端工厂测试失败: {e}")
        return False

async def test_request_queue():
    """测试请求队列"""
    try:
        from common.request_queue import RequestQueueManager, RequestPriority
        
        # 创建队列管理器
        queue_manager = RequestQueueManager(max_concurrent=2, max_queue_size=5)
        
        # 测试处理器注册
        async def test_processor(data):
            await asyncio.sleep(0.01)
            return {"result": "processed"}
        
        queue_manager.register_processor("test", test_processor)
        
        # 启动队列
        await queue_manager.start()
        
        # 提交测试请求
        request_id = await queue_manager.enqueue_request(
            user_id=1,
            request_type="test",
            request_data={"test": "data"},
            priority=RequestPriority.NORMAL
        )
        
        # 等待处理
        await asyncio.sleep(0.1)
        
        # 检查状态
        status = await queue_manager.get_request_status(request_id)
        assert status is not None, "请求状态获取失败"
        
        # 停止队列
        await queue_manager.stop()
        
        logger.info("✓ 请求队列测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 请求队列测试失败: {e}")
        return False

async def test_data_validation():
    """测试数据验证"""
    try:
        from common.data_validator import validate_recommendation_request
        
        # 测试有效请求
        valid_request = {
            "userId": 1,
            "productBarcode": "1234567890123"
        }
        
        result = validate_recommendation_request("barcode_recommendation", valid_request)
        assert result.is_valid == True, "有效请求验证失败"
        
        # 测试无效请求
        invalid_request = {
            "userId": -1,
            "productBarcode": "invalid"
        }
        
        result = validate_recommendation_request("barcode_recommendation", invalid_request)
        assert result.is_valid == False, "无效请求应该验证失败"
        assert len(result.errors) > 0, "应该有验证错误"
        
        logger.info("✓ 数据验证测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 数据验证测试失败: {e}")
        return False

async def test_error_handling():
    """测试错误处理"""
    try:
        from common.error_handler import get_error_handler, ErrorContext
        
        error_handler = get_error_handler()
        
        # 测试错误处理
        test_error = Exception("测试错误")
        context = ErrorContext(user_id=1, operation="test")
        
        error_info = error_handler.handle_error(test_error, context)
        assert error_info is not None, "错误处理结果为空"
        assert error_info.code is not None, "错误代码为空"
        assert error_info.user_message is not None, "用户消息为空"
        
        # 测试统计信息
        stats = error_handler.get_error_statistics()
        assert stats["total_errors"] >= 1, "错误统计不正确"
        
        logger.info("✓ 错误处理测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 错误处理测试失败: {e}")
        return False

async def test_fallback_service():
    """测试降级服务"""
    try:
        from common.fallback_service import get_fallback_service
        
        fallback_service = get_fallback_service()
        
        # 测试条码推荐降级
        result = fallback_service.get_barcode_fallback_recommendation(
            user_id=1,
            barcode="1234567890123"
        )
        
        assert result["success"] == True, "降级服务失败"
        assert result["data"]["fallbackMode"] == True, "降级模式标记错误"
        assert "recommendations" in result["data"], "缺少推荐数据"
        
        logger.info("✓ 降级服务测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 降级服务测试失败: {e}")
        return False

async def test_session_management():
    """测试会话管理"""
    try:
        from common.session_manager import get_session_manager
        
        session_manager = get_session_manager()
        
        # 创建会话
        session_id = session_manager.create_session(user_id=1)
        assert session_id is not None, "会话创建失败"
        
        # 获取会话
        session = session_manager.get_user_session(user_id=1)
        assert session is not None, "会话获取失败"
        assert session.user_id == 1, "会话用户ID错误"
        
        logger.info("✓ 会话管理测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 会话管理测试失败: {e}")
        return False

async def test_performance_monitoring():
    """测试性能监控"""
    try:
        from monitoring.performance_monitor import get_performance_monitor
        
        monitor = get_performance_monitor()
        
        # 记录测试指标
        monitor.record_request("test", 100, True, user_id=1)
        monitor.record_ai_request(150, True, token_usage=50, cost_usd=0.001)
        
        # 获取报告
        report = monitor.get_performance_report()
        assert report["request_metrics"]["total_requests"] >= 1, "请求指标错误"
        assert report["ai_metrics"]["total_ai_requests"] >= 1, "AI指标错误"
        
        logger.info("✓ 性能监控测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 性能监控测试失败: {e}")
        return False

async def test_health_checker():
    """测试健康检查"""
    try:
        from monitoring.health_checker import get_health_checker
        
        health_checker = get_health_checker()
        
        # 注册测试检查
        async def test_check():
            return {"status": "healthy", "message": "测试正常"}
        
        health_checker.register_health_check("test_service", test_check)
        
        # 执行检查
        result = await health_checker.check_service_health("test_service")
        assert result.status.value == "healthy", "健康检查状态错误"
        
        # 获取摘要
        summary = health_checker.get_health_summary()
        assert "test_service" in summary["services"], "服务未在摘要中"
        
        logger.info("✓ 健康检查测试通过")
        return True
    except Exception as e:
        logger.error(f"✗ 健康检查测试失败: {e}")
        return False

async def main():
    """主测试函数"""
    logger.info("开始生产环境优化功能测试")
    logger.info("=" * 50)
    
    test_functions = [
        ("Azure OpenAI配置", test_azure_openai_config),
        ("客户端工厂", test_client_factory),
        ("请求队列", test_request_queue),
        ("数据验证", test_data_validation),
        ("错误处理", test_error_handling),
        ("降级服务", test_fallback_service),
        ("会话管理", test_session_management),
        ("性能监控", test_performance_monitoring),
        ("健康检查", test_health_checker),
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in test_functions:
        logger.info(f"运行测试: {test_name}")
        try:
            success = await test_func()
            if success:
                passed += 1
            else:
                failed += 1
        except Exception as e:
            logger.error(f"测试异常 {test_name}: {e}")
            failed += 1
        
        logger.info("-" * 30)
    
    logger.info("=" * 50)
    logger.info(f"测试完成 - 通过: {passed}, 失败: {failed}")
    
    if failed == 0:
        logger.info("🎉 所有测试通过！生产环境优化功能正常工作。")
        return True
    else:
        logger.warning(f"⚠️ 有 {failed} 个测试失败，请检查相关功能。")
        return False

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)