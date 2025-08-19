"""
健康检查增强模块
提供全面的系统健康检查和服务状态监控
"""

import asyncio
import time
import logging
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)

class HealthStatus(Enum):
    """健康状态"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"

@dataclass
class HealthCheckResult:
    """健康检查结果"""
    service_name: str
    status: HealthStatus
    response_time_ms: float
    message: str
    details: Dict[str, Any]
    timestamp: float
    
class HealthChecker:
    """健康检查器"""
    
    def __init__(self):
        # 注册的健康检查函数
        self.health_checks = {}  # service_name -> check_function
        
        # 健康检查配置
        self.check_configs = {}  # service_name -> config
        
        # 健康状态缓存
        self.health_cache = {}  # service_name -> HealthCheckResult
        
        # 全局健康状态
        self.overall_status = HealthStatus.UNKNOWN
        
        # 检查间隔配置
        self.default_check_interval = 30  # 30秒
        
        # 后台任务
        self.background_checks = {}  # service_name -> task
        self.is_running = False
    
    def register_health_check(self, service_name: str, check_function: Callable,
                            interval_seconds: int = None, timeout_seconds: int = 10,
                            critical: bool = True):
        """注册健康检查函数"""
        self.health_checks[service_name] = check_function
        self.check_configs[service_name] = {
            "interval": interval_seconds or self.default_check_interval,
            "timeout": timeout_seconds,
            "critical": critical  # 是否影响整体健康状态
        }
        
        logger.info(f"注册健康检查: {service_name}")
    
    async def start_background_checks(self):
        """启动后台健康检查"""
        if self.is_running:
            return
        
        self.is_running = True
        
        # 为每个注册的服务启动后台检查
        for service_name in self.health_checks.keys():
            task = asyncio.create_task(self._background_check_loop(service_name))
            self.background_checks[service_name] = task
        
        logger.info("后台健康检查已启动")
    
    async def stop_background_checks(self):
        """停止后台健康检查"""
        self.is_running = False
        
        # 取消所有后台任务
        for task in self.background_checks.values():
            if not task.done():
                task.cancel()
        
        # 等待所有任务完成
        if self.background_checks:
            await asyncio.gather(*self.background_checks.values(), return_exceptions=True)
        
        self.background_checks.clear()
        logger.info("后台健康检查已停止")
    
    async def check_service_health(self, service_name: str) -> HealthCheckResult:
        """检查单个服务健康状态"""
        if service_name not in self.health_checks:
            return HealthCheckResult(
                service_name=service_name,
                status=HealthStatus.UNKNOWN,
                response_time_ms=0,
                message="未注册的服务",
                details={},
                timestamp=time.time()
            )
        
        check_function = self.health_checks[service_name]
        config = self.check_configs[service_name]
        start_time = time.time()
        
        try:
            # 执行健康检查，带超时
            result = await asyncio.wait_for(
                check_function(),
                timeout=config["timeout"]
            )
            
            response_time_ms = (time.time() - start_time) * 1000
            
            # 解析检查结果
            if isinstance(result, dict):
                status = HealthStatus(result.get("status", "unknown"))
                message = result.get("message", "健康检查完成")
                details = result.get("details", {})
            elif isinstance(result, bool):
                status = HealthStatus.HEALTHY if result else HealthStatus.UNHEALTHY
                message = "健康检查通过" if result else "健康检查失败"
                details = {}
            else:
                status = HealthStatus.HEALTHY
                message = str(result)
                details = {}
            
            health_result = HealthCheckResult(
                service_name=service_name,
                status=status,
                response_time_ms=response_time_ms,
                message=message,
                details=details,
                timestamp=time.time()
            )
            
            # 更新缓存
            self.health_cache[service_name] = health_result
            
            return health_result
            
        except asyncio.TimeoutError:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                service_name=service_name,
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"健康检查超时 ({config['timeout']}s)",
                details={"timeout": config["timeout"]},
                timestamp=time.time()
            )
        
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                service_name=service_name,
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"健康检查异常: {str(e)}",
                details={"error": str(e), "error_type": type(e).__name__},
                timestamp=time.time()
            )
    
    async def check_all_services(self) -> Dict[str, HealthCheckResult]:
        """检查所有服务健康状态"""
        results = {}
        
        # 并发执行所有健康检查
        tasks = {
            service_name: self.check_service_health(service_name)
            for service_name in self.health_checks.keys()
        }
        
        completed_results = await asyncio.gather(*tasks.values(), return_exceptions=True)
        
        for service_name, result in zip(tasks.keys(), completed_results):
            if isinstance(result, Exception):
                results[service_name] = HealthCheckResult(
                    service_name=service_name,
                    status=HealthStatus.UNHEALTHY,
                    response_time_ms=0,
                    message=f"检查异常: {str(result)}",
                    details={"exception": str(result)},
                    timestamp=time.time()
                )
            else:
                results[service_name] = result
        
        # 更新整体健康状态
        self._update_overall_status(results)
        
        return results
    
    def get_health_summary(self) -> Dict[str, Any]:
        """获取健康状态摘要"""
        current_time = time.time()
        
        # 使用缓存的结果
        cached_results = {}
        for service_name, result in self.health_cache.items():
            # 检查缓存是否过期（5分钟）
            if current_time - result.timestamp < 300:
                cached_results[service_name] = result
        
        # 计算各状态的服务数量
        status_counts = {status.value: 0 for status in HealthStatus}
        critical_unhealthy = 0
        total_response_time = 0
        
        for result in cached_results.values():
            status_counts[result.status.value] += 1
            total_response_time += result.response_time_ms
            
            # 检查关键服务的健康状态
            config = self.check_configs.get(result.service_name, {})
            if config.get("critical", True) and result.status == HealthStatus.UNHEALTHY:
                critical_unhealthy += 1
        
        # 确定整体状态
        overall_status = self._determine_overall_status(status_counts, critical_unhealthy)
        
        return {
            "overall_status": overall_status.value,
            "timestamp": datetime.now().isoformat(),
            "total_services": len(cached_results),
            "status_distribution": status_counts,
            "critical_unhealthy_services": critical_unhealthy,
            "average_response_time_ms": total_response_time / max(len(cached_results), 1),
            "services": {
                service_name: {
                    "status": result.status.value,
                    "message": result.message,
                    "response_time_ms": result.response_time_ms,
                    "last_check": datetime.fromtimestamp(result.timestamp).isoformat()
                }
                for service_name, result in cached_results.items()
            }
        }
    
    def get_detailed_health_report(self) -> Dict[str, Any]:
        """获取详细健康报告"""
        summary = self.get_health_summary()
        
        # 添加详细信息
        detailed_services = {}
        for service_name, result in self.health_cache.items():
            config = self.check_configs.get(service_name, {})
            detailed_services[service_name] = {
                "status": result.status.value,
                "message": result.message,
                "response_time_ms": result.response_time_ms,
                "last_check": datetime.fromtimestamp(result.timestamp).isoformat(),
                "details": result.details,
                "configuration": {
                    "check_interval": config.get("interval", self.default_check_interval),
                    "timeout": config.get("timeout", 10),
                    "critical": config.get("critical", True)
                }
            }
        
        return {
            **summary,
            "detailed_services": detailed_services,
            "check_history": self._get_recent_check_history(),
            "system_info": self._get_system_info()
        }
    
    async def _background_check_loop(self, service_name: str):
        """后台检查循环"""
        config = self.check_configs[service_name]
        interval = config["interval"]
        
        while self.is_running:
            try:
                await self.check_service_health(service_name)
                await asyncio.sleep(interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"后台健康检查异常 {service_name}: {e}")
                await asyncio.sleep(interval)
    
    def _update_overall_status(self, results: Dict[str, HealthCheckResult]):
        """更新整体健康状态"""
        critical_unhealthy = 0
        degraded_services = 0
        
        for result in results.values():
            config = self.check_configs.get(result.service_name, {})
            
            if config.get("critical", True):
                if result.status == HealthStatus.UNHEALTHY:
                    critical_unhealthy += 1
                elif result.status == HealthStatus.DEGRADED:
                    degraded_services += 1
        
        if critical_unhealthy > 0:
            self.overall_status = HealthStatus.UNHEALTHY
        elif degraded_services > 0:
            self.overall_status = HealthStatus.DEGRADED
        else:
            self.overall_status = HealthStatus.HEALTHY
    
    def _determine_overall_status(self, status_counts: Dict[str, int], 
                                critical_unhealthy: int) -> HealthStatus:
        """确定整体健康状态"""
        if critical_unhealthy > 0:
            return HealthStatus.UNHEALTHY
        elif status_counts.get("degraded", 0) > 0:
            return HealthStatus.DEGRADED
        elif status_counts.get("unhealthy", 0) > 0:
            return HealthStatus.DEGRADED  # 非关键服务不健康只导致降级
        else:
            return HealthStatus.HEALTHY
    
    def _get_recent_check_history(self) -> List[Dict[str, Any]]:
        """获取最近的检查历史"""
        # 这里可以实现检查历史记录
        # 现在返回基础信息
        return [
            {
                "service": service_name,
                "status": result.status.value,
                "timestamp": result.timestamp,
                "response_time_ms": result.response_time_ms
            }
            for service_name, result in self.health_cache.items()
        ]
    
    def _get_system_info(self) -> Dict[str, Any]:
        """获取系统信息"""
        return {
            "registered_services": len(self.health_checks),
            "background_checks_running": self.is_running,
            "cache_size": len(self.health_cache),
            "overall_status": self.overall_status.value
        }

# 预定义的健康检查函数
async def check_database_health() -> Dict[str, Any]:
    """数据库健康检查"""
    try:
        # 这里应该实现实际的数据库连接检查
        # 现在返回模拟结果
        start_time = time.time()
        
        # 模拟数据库查询
        await asyncio.sleep(0.1)
        
        response_time = (time.time() - start_time) * 1000
        
        return {
            "status": "healthy",
            "message": "数据库连接正常",
            "details": {
                "connection_pool_active": 10,
                "connection_pool_idle": 5,
                "query_response_time_ms": response_time
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "message": f"数据库连接失败: {str(e)}",
            "details": {"error": str(e)}
        }

async def check_ai_service_health() -> Dict[str, Any]:
    """AI服务健康检查"""
    try:
        # 导入AI客户端
        from llm_evaluation.client_factory import get_ai_client
        
        client = get_ai_client()
        health_result = await client.health_check()
        
        if health_result.get("status") == "healthy":
            return {
                "status": "healthy",
                "message": "AI服务正常",
                "details": health_result
            }
        else:
            return {
                "status": "unhealthy",
                "message": "AI服务不可用",
                "details": health_result
            }
            
    except Exception as e:
        return {
            "status": "unhealthy",
            "message": f"AI服务检查失败: {str(e)}",
            "details": {"error": str(e)}
        }

async def check_queue_health() -> Dict[str, Any]:
    """队列健康检查"""
    try:
        from common.request_queue import get_queue_manager
        
        queue_manager = get_queue_manager()
        stats = queue_manager.get_queue_stats()
        
        # 检查队列状态
        queue_size = stats.get("current_queue_size", 0)
        processing_count = stats.get("processing_tasks_count", 0)
        
        if queue_size > 100:  # 队列过大
            status = "degraded"
            message = f"队列大小过大: {queue_size}"
        elif processing_count > 20:  # 处理任务过多
            status = "degraded"
            message = f"处理任务过多: {processing_count}"
        else:
            status = "healthy"
            message = "队列状态正常"
        
        return {
            "status": status,
            "message": message,
            "details": {
                "queue_size": queue_size,
                "processing_tasks": processing_count,
                "total_requests": stats.get("total_requests", 0),
                "success_rate": stats.get("completed_requests", 0) / max(stats.get("total_requests", 1), 1)
            }
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "message": f"队列状态检查失败: {str(e)}",
            "details": {"error": str(e)}
        }

# 全局健康检查器实例
_global_health_checker = None

def get_health_checker() -> HealthChecker:
    """获取全局健康检查器实例"""
    global _global_health_checker
    if _global_health_checker is None:
        _global_health_checker = HealthChecker()
        
        # 注册默认的健康检查
        _global_health_checker.register_health_check(
            "database", check_database_health, interval_seconds=60, critical=True
        )
        _global_health_checker.register_health_check(
            "ai_service", check_ai_service_health, interval_seconds=30, critical=True
        )
        _global_health_checker.register_health_check(
            "request_queue", check_queue_health, interval_seconds=30, critical=False
        )
        
    return _global_health_checker

# 便捷函数
async def get_system_health() -> Dict[str, Any]:
    """获取系统健康状态"""
    health_checker = get_health_checker()
    return health_checker.get_health_summary()

async def get_detailed_system_health() -> Dict[str, Any]:
    """获取详细系统健康状态"""
    health_checker = get_health_checker()
    return health_checker.get_detailed_health_report()

async def start_health_monitoring():
    """启动健康监控"""
    health_checker = get_health_checker()
    await health_checker.start_background_checks()