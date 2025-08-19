"""
性能监控器
实时跟踪系统性能指标、用户活动和服务健康状态
"""

import time
import asyncio
import logging
try:
    import psutil
    PSUTIL_AVAILABLE = True
except ImportError:
    PSUTIL_AVAILABLE = False
import threading
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import deque, defaultdict
from enum import Enum
import json

logger = logging.getLogger(__name__)

class MetricType(Enum):
    """指标类型"""
    COUNTER = "counter"      # 计数器（累加）
    GAUGE = "gauge"         # 瞬时值
    HISTOGRAM = "histogram"  # 分布统计
    TIMER = "timer"         # 时间测量

@dataclass
class MetricData:
    """指标数据"""
    name: str
    metric_type: MetricType
    value: float
    timestamp: float
    labels: Dict[str, str] = field(default_factory=dict)
    description: Optional[str] = None

@dataclass
class PerformanceSnapshot:
    """性能快照"""
    timestamp: float
    request_metrics: Dict[str, Any]
    system_metrics: Dict[str, Any]
    service_metrics: Dict[str, Any]
    error_metrics: Dict[str, Any]

class PerformanceMonitor:
    """性能监控器"""
    
    def __init__(self, collection_interval: int = 60, max_history: int = 1440):  # 24小时数据
        self.collection_interval = collection_interval
        self.max_history = max_history
        
        # 核心指标存储
        self.metrics = {
            # 请求指标
            "request_count": 0,
            "success_count": 0,
            "error_count": 0,
            "response_times": deque(maxlen=10000),  # 保留最近10000次请求
            "concurrent_requests": 0,
            "queue_size": 0,
            
            # 用户指标
            "active_users": 0,
            "total_users": 0,
            "user_sessions": 0,
            
            # AI服务指标
            "ai_requests": 0,
            "ai_success_count": 0,
            "ai_error_count": 0,
            "ai_response_times": deque(maxlen=1000),
            "token_usage": 0,
            "ai_cost_usd": 0.0,
            
            # 系统指标
            "cpu_usage": 0.0,
            "memory_usage": 0.0,
            "disk_usage": 0.0,
            "network_io": {"bytes_sent": 0, "bytes_recv": 0}
        }
        
        # 历史数据存储
        self.metric_history = deque(maxlen=max_history)
        
        # 分类指标存储
        self.request_type_metrics = defaultdict(lambda: {
            "count": 0,
            "success": 0,
            "error": 0,
            "response_times": deque(maxlen=1000)
        })
        
        self.user_metrics = defaultdict(lambda: {
            "request_count": 0,
            "last_activity": 0,
            "session_duration": 0,
            "error_count": 0
        })
        
        # 性能阈值
        self.thresholds = {
            "response_time_p95_ms": 3000,
            "error_rate_threshold": 0.05,  # 5%
            "cpu_usage_threshold": 0.8,    # 80%
            "memory_usage_threshold": 0.8,  # 80%
            "queue_size_threshold": 100
        }
        
        # 告警状态
        self.alerts = {
            "active_alerts": [],
            "alert_history": deque(maxlen=100)
        }
        
        # 监控状态
        self.start_time = time.time()
        self.is_monitoring = False
        self.monitoring_task = None
        
        # 自定义指标
        self.custom_metrics = {}
        self.metric_callbacks = {}  # metric_name -> callback_function
    
    async def start_monitoring(self):
        """启动监控"""
        if self.is_monitoring:
            return
        
        self.is_monitoring = True
        self.monitoring_task = asyncio.create_task(self._monitoring_loop())
        logger.info("性能监控器已启动")
    
    async def stop_monitoring(self):
        """停止监控"""
        self.is_monitoring = False
        if self.monitoring_task:
            self.monitoring_task.cancel()
            try:
                await self.monitoring_task
            except asyncio.CancelledError:
                pass
        logger.info("性能监控器已停止")
    
    def record_request(self, request_type: str, response_time_ms: int, 
                      success: bool, user_id: Optional[int] = None,
                      additional_metrics: Optional[Dict] = None):
        """记录请求指标"""
        current_time = time.time()
        
        # 更新全局指标
        self.metrics["request_count"] += 1
        self.metrics["response_times"].append(response_time_ms)
        
        if success:
            self.metrics["success_count"] += 1
        else:
            self.metrics["error_count"] += 1
        
        # 更新请求类型指标
        type_metrics = self.request_type_metrics[request_type]
        type_metrics["count"] += 1
        type_metrics["response_times"].append(response_time_ms)
        
        if success:
            type_metrics["success"] += 1
        else:
            type_metrics["error"] += 1
        
        # 更新用户指标
        if user_id:
            user_metrics = self.user_metrics[user_id]
            user_metrics["request_count"] += 1
            user_metrics["last_activity"] = current_time
            
            if not success:
                user_metrics["error_count"] += 1
        
        # 处理额外指标
        if additional_metrics:
            for key, value in additional_metrics.items():
                if key in self.metrics:
                    if isinstance(value, (int, float)):
                        self.metrics[key] += value
                    else:
                        self.metrics[key] = value
        
        # 检查性能告警
        self._check_performance_alerts()
    
    def record_ai_request(self, response_time_ms: int, success: bool, 
                         token_usage: int = 0, cost_usd: float = 0.0,
                         model: str = "unknown"):
        """记录AI服务请求指标"""
        self.metrics["ai_requests"] += 1
        self.metrics["ai_response_times"].append(response_time_ms)
        self.metrics["token_usage"] += token_usage
        self.metrics["ai_cost_usd"] += cost_usd
        
        if success:
            self.metrics["ai_success_count"] += 1
        else:
            self.metrics["ai_error_count"] += 1
        
        # 记录模型特定指标
        model_key = f"ai_model_{model}"
        if model_key not in self.request_type_metrics:
            self.request_type_metrics[model_key] = {
                "count": 0,
                "success": 0,
                "error": 0,
                "response_times": deque(maxlen=1000),
                "token_usage": 0,
                "cost_usd": 0.0
            }
        
        model_metrics = self.request_type_metrics[model_key]
        model_metrics["count"] += 1
        model_metrics["response_times"].append(response_time_ms)
        model_metrics["token_usage"] += token_usage
        model_metrics["cost_usd"] += cost_usd
        
        if success:
            model_metrics["success"] += 1
        else:
            model_metrics["error"] += 1
    
    def update_concurrent_requests(self, count: int):
        """更新并发请求数"""
        self.metrics["concurrent_requests"] = count
    
    def update_queue_size(self, size: int):
        """更新队列大小"""
        self.metrics["queue_size"] = size
        
        # 检查队列大小告警
        if size > self.thresholds["queue_size_threshold"]:
            self._trigger_alert("high_queue_size", f"队列大小过大: {size}")
    
    def update_user_metrics(self, active_users: int, total_users: int, sessions: int):
        """更新用户指标"""
        self.metrics["active_users"] = active_users
        self.metrics["total_users"] = total_users
        self.metrics["user_sessions"] = sessions
    
    def add_custom_metric(self, name: str, value: float, 
                         metric_type: MetricType = MetricType.GAUGE,
                         labels: Optional[Dict[str, str]] = None):
        """添加自定义指标"""
        metric = MetricData(
            name=name,
            metric_type=metric_type,
            value=value,
            timestamp=time.time(),
            labels=labels or {}
        )
        
        self.custom_metrics[name] = metric
    
    def register_metric_callback(self, metric_name: str, callback: Callable[[], float]):
        """注册指标回调函数"""
        self.metric_callbacks[metric_name] = callback
    
    def get_performance_report(self) -> Dict[str, Any]:
        """获取性能报告"""
        current_time = time.time()
        uptime_seconds = current_time - self.start_time
        
        # 计算响应时间统计
        response_times = list(self.metrics["response_times"])
        ai_response_times = list(self.metrics["ai_response_times"])
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "uptime_seconds": uptime_seconds,
            "uptime_hours": uptime_seconds / 3600,
            
            # 请求统计
            "request_metrics": {
                "total_requests": self.metrics["request_count"],
                "successful_requests": self.metrics["success_count"],
                "failed_requests": self.metrics["error_count"],
                "success_rate": self._calculate_success_rate(),
                "error_rate": self._calculate_error_rate(),
                "requests_per_second": self.metrics["request_count"] / max(uptime_seconds, 1),
                "concurrent_requests": self.metrics["concurrent_requests"],
                "queue_size": self.metrics["queue_size"]
            },
            
            # 响应时间统计
            "response_time_metrics": self._calculate_response_time_stats(response_times),
            
            # AI服务统计
            "ai_metrics": {
                "total_ai_requests": self.metrics["ai_requests"],
                "ai_success_count": self.metrics["ai_success_count"],
                "ai_error_count": self.metrics["ai_error_count"],
                "ai_success_rate": self._calculate_ai_success_rate(),
                "total_tokens": self.metrics["token_usage"],
                "total_cost_usd": self.metrics["ai_cost_usd"],
                "average_tokens_per_request": self._calculate_avg_tokens_per_request(),
                "ai_response_time_stats": self._calculate_response_time_stats(ai_response_times)
            },
            
            # 用户统计
            "user_metrics": {
                "active_users": self.metrics["active_users"],
                "total_users": self.metrics["total_users"],
                "active_sessions": self.metrics["user_sessions"],
                "average_requests_per_user": self._calculate_avg_requests_per_user()
            },
            
            # 系统资源
            "system_metrics": self._get_system_metrics(),
            
            # 请求类型分布
            "request_type_distribution": self._get_request_type_stats(),
            
            # 告警信息
            "alerts": {
                "active_alerts": len(self.alerts["active_alerts"]),
                "recent_alerts": list(self.alerts["alert_history"])[-10:]  # 最近10个告警
            }
        }
        
        return report
    
    def get_real_time_metrics(self) -> Dict[str, Any]:
        """获取实时指标"""
        current_time = time.time()
        
        # 最近5分钟的指标
        recent_requests = [t for t in self.metrics["response_times"] 
                          if current_time - t < 300]  # 假设response_times包含时间戳
        
        return {
            "timestamp": datetime.now().isoformat(),
            "current_concurrent_requests": self.metrics["concurrent_requests"],
            "current_queue_size": self.metrics["queue_size"],
            "recent_requests_5min": len(recent_requests),
            "recent_avg_response_time": sum(recent_requests) / max(len(recent_requests), 1) if recent_requests else 0,
            "current_success_rate": self._calculate_success_rate(),
            "current_error_rate": self._calculate_error_rate(),
            "active_users": self.metrics["active_users"],
            "system_cpu": self.metrics["cpu_usage"],
            "system_memory": self.metrics["memory_usage"],
            "active_alerts": len(self.alerts["active_alerts"])
        }
    
    def get_historical_data(self, hours: int = 24) -> List[Dict[str, Any]]:
        """获取历史数据"""
        cutoff_time = time.time() - (hours * 3600)
        
        return [
            snapshot for snapshot in self.metric_history
            if snapshot.timestamp > cutoff_time
        ]
    
    async def _monitoring_loop(self):
        """监控循环"""
        while self.is_monitoring:
            try:
                # 收集系统指标
                await self._collect_system_metrics()
                
                # 执行自定义指标回调
                self._execute_metric_callbacks()
                
                # 创建性能快照
                snapshot = self._create_performance_snapshot()
                self.metric_history.append(snapshot)
                
                # 清理过期数据
                self._cleanup_expired_data()
                
                # 检查系统健康状态
                self._check_system_health()
                
                # 等待下一次收集
                await asyncio.sleep(self.collection_interval)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"监控循环异常: {e}")
                await asyncio.sleep(self.collection_interval)
    
    async def _collect_system_metrics(self):
        """收集系统指标"""
        try:
            if PSUTIL_AVAILABLE:
                # CPU使用率
                self.metrics["cpu_usage"] = psutil.cpu_percent(interval=0.1)
                
                # 内存使用率
                memory = psutil.virtual_memory()
                self.metrics["memory_usage"] = memory.percent / 100
                
                # 磁盘使用率
                disk = psutil.disk_usage('/')
                self.metrics["disk_usage"] = disk.percent / 100
                
                # 网络IO
                net_io = psutil.net_io_counters()
                self.metrics["network_io"] = {
                    "bytes_sent": net_io.bytes_sent,
                    "bytes_recv": net_io.bytes_recv
                }
            else:
                # 模拟系统指标（当psutil不可用时）
                self.metrics["cpu_usage"] = 25.0  # 模拟25%CPU使用率
                self.metrics["memory_usage"] = 0.45  # 模拟45%内存使用率
                self.metrics["disk_usage"] = 0.60  # 模拟60%磁盘使用率
                self.metrics["network_io"] = {
                    "bytes_sent": 1024 * 1024 * 100,  # 100MB
                    "bytes_recv": 1024 * 1024 * 200   # 200MB
                }
                
        except Exception as e:
            logger.error(f"系统指标收集失败: {e}")
    
    def _execute_metric_callbacks(self):
        """执行指标回调"""
        for metric_name, callback in self.metric_callbacks.items():
            try:
                value = callback()
                self.add_custom_metric(metric_name, value)
            except Exception as e:
                logger.error(f"指标回调执行失败 {metric_name}: {e}")
    
    def _create_performance_snapshot(self) -> PerformanceSnapshot:
        """创建性能快照"""
        current_time = time.time()
        
        return PerformanceSnapshot(
            timestamp=current_time,
            request_metrics={
                "total_requests": self.metrics["request_count"],
                "success_count": self.metrics["success_count"],
                "error_count": self.metrics["error_count"],
                "concurrent_requests": self.metrics["concurrent_requests"],
                "queue_size": self.metrics["queue_size"]
            },
            system_metrics={
                "cpu_usage": self.metrics["cpu_usage"],
                "memory_usage": self.metrics["memory_usage"],
                "disk_usage": self.metrics["disk_usage"]
            },
            service_metrics={
                "active_users": self.metrics["active_users"],
                "ai_requests": self.metrics["ai_requests"],
                "token_usage": self.metrics["token_usage"],
                "ai_cost_usd": self.metrics["ai_cost_usd"]
            },
            error_metrics={
                "error_rate": self._calculate_error_rate(),
                "ai_error_rate": self._calculate_ai_error_rate()
            }
        )
    
    def _cleanup_expired_data(self):
        """清理过期数据"""
        current_time = time.time()
        
        # 清理用户指标中的非活跃用户
        inactive_users = []
        for user_id, metrics in self.user_metrics.items():
            if current_time - metrics["last_activity"] > 3600:  # 1小时无活动
                inactive_users.append(user_id)
        
        for user_id in inactive_users:
            del self.user_metrics[user_id]
    
    def _check_performance_alerts(self):
        """检查性能告警"""
        current_time = time.time()
        
        # 检查错误率
        error_rate = self._calculate_error_rate()
        if error_rate > self.thresholds["error_rate_threshold"]:
            self._trigger_alert("high_error_rate", f"错误率过高: {error_rate:.2%}")
        
        # 检查响应时间
        if self.metrics["response_times"]:
            p95_response_time = self._calculate_percentile(list(self.metrics["response_times"]), 0.95)
            if p95_response_time > self.thresholds["response_time_p95_ms"]:
                self._trigger_alert("high_response_time", f"P95响应时间过高: {p95_response_time:.1f}ms")
    
    def _check_system_health(self):
        """检查系统健康状态"""
        # 检查CPU使用率
        if self.metrics["cpu_usage"] > self.thresholds["cpu_usage_threshold"]:
            self._trigger_alert("high_cpu_usage", f"CPU使用率过高: {self.metrics['cpu_usage']:.1%}")
        
        # 检查内存使用率
        if self.metrics["memory_usage"] > self.thresholds["memory_usage_threshold"]:
            self._trigger_alert("high_memory_usage", f"内存使用率过高: {self.metrics['memory_usage']:.1%}")
    
    def _trigger_alert(self, alert_type: str, message: str):
        """触发告警"""
        alert = {
            "type": alert_type,
            "message": message,
            "timestamp": time.time(),
            "severity": "warning"
        }
        
        # 避免重复告警
        if not any(a["type"] == alert_type for a in self.alerts["active_alerts"]):
            self.alerts["active_alerts"].append(alert)
            self.alerts["alert_history"].append(alert)
            logger.warning(f"性能告警: {message}")
    
    def _calculate_success_rate(self) -> float:
        """计算成功率"""
        total = self.metrics["request_count"]
        if total == 0:
            return 1.0
        return self.metrics["success_count"] / total
    
    def _calculate_error_rate(self) -> float:
        """计算错误率"""
        total = self.metrics["request_count"]
        if total == 0:
            return 0.0
        return self.metrics["error_count"] / total
    
    def _calculate_ai_success_rate(self) -> float:
        """计算AI服务成功率"""
        total = self.metrics["ai_requests"]
        if total == 0:
            return 1.0
        return self.metrics["ai_success_count"] / total
    
    def _calculate_ai_error_rate(self) -> float:
        """计算AI服务错误率"""
        total = self.metrics["ai_requests"]
        if total == 0:
            return 0.0
        return self.metrics["ai_error_count"] / total
    
    def _calculate_avg_tokens_per_request(self) -> float:
        """计算平均每请求token数"""
        total_requests = self.metrics["ai_requests"]
        if total_requests == 0:
            return 0.0
        return self.metrics["token_usage"] / total_requests
    
    def _calculate_avg_requests_per_user(self) -> float:
        """计算平均每用户请求数"""
        total_users = len(self.user_metrics)
        if total_users == 0:
            return 0.0
        return self.metrics["request_count"] / total_users
    
    def _calculate_response_time_stats(self, response_times: List[float]) -> Dict[str, float]:
        """计算响应时间统计"""
        if not response_times:
            return {
                "min_ms": 0,
                "max_ms": 0,
                "avg_ms": 0,
                "p50_ms": 0,
                "p95_ms": 0,
                "p99_ms": 0
            }
        
        sorted_times = sorted(response_times)
        
        return {
            "min_ms": min(sorted_times),
            "max_ms": max(sorted_times),
            "avg_ms": sum(sorted_times) / len(sorted_times),
            "p50_ms": self._calculate_percentile(sorted_times, 0.5),
            "p95_ms": self._calculate_percentile(sorted_times, 0.95),
            "p99_ms": self._calculate_percentile(sorted_times, 0.99)
        }
    
    def _calculate_percentile(self, values: List[float], percentile: float) -> float:
        """计算百分位数"""
        if not values:
            return 0.0
        
        index = int(len(values) * percentile)
        return values[min(index, len(values) - 1)]
    
    def _get_system_metrics(self) -> Dict[str, Any]:
        """获取系统指标"""
        return {
            "cpu_usage_percent": self.metrics["cpu_usage"],
            "memory_usage_percent": self.metrics["memory_usage"] * 100,
            "disk_usage_percent": self.metrics["disk_usage"] * 100,
            "network_bytes_sent": self.metrics["network_io"]["bytes_sent"],
            "network_bytes_recv": self.metrics["network_io"]["bytes_recv"]
        }
    
    def _get_request_type_stats(self) -> Dict[str, Any]:
        """获取请求类型统计"""
        stats = {}
        
        for request_type, metrics in self.request_type_metrics.items():
            response_times = list(metrics["response_times"])
            stats[request_type] = {
                "count": metrics["count"],
                "success": metrics["success"],
                "error": metrics["error"],
                "success_rate": metrics["success"] / max(metrics["count"], 1),
                "avg_response_time": sum(response_times) / max(len(response_times), 1),
                "token_usage": metrics.get("token_usage", 0),
                "cost_usd": metrics.get("cost_usd", 0.0)
            }
        
        return stats

# 全局性能监控器实例
_global_performance_monitor = None

def get_performance_monitor() -> PerformanceMonitor:
    """获取全局性能监控器实例"""
    global _global_performance_monitor
    if _global_performance_monitor is None:
        import os
        collection_interval = int(os.getenv("METRICS_COLLECTION_INTERVAL", "60"))
        max_history = int(os.getenv("MAX_METRIC_HISTORY", "1440"))
        _global_performance_monitor = PerformanceMonitor(collection_interval, max_history)
    return _global_performance_monitor

# 便捷函数
def record_request_metric(request_type: str, response_time_ms: int, success: bool,
                         user_id: Optional[int] = None, **kwargs):
    """便捷的请求指标记录函数"""
    monitor = get_performance_monitor()
    monitor.record_request(request_type, response_time_ms, success, user_id, kwargs)

def record_ai_metric(response_time_ms: int, success: bool, token_usage: int = 0,
                    cost_usd: float = 0.0, model: str = "unknown"):
    """便捷的AI指标记录函数"""
    monitor = get_performance_monitor()
    monitor.record_ai_request(response_time_ms, success, token_usage, cost_usd, model)

async def start_performance_monitoring():
    """启动性能监控"""
    monitor = get_performance_monitor()
    await monitor.start_monitoring()

def get_current_performance_report() -> Dict[str, Any]:
    """获取当前性能报告"""
    monitor = get_performance_monitor()
    return monitor.get_performance_report()