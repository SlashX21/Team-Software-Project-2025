"""
异步请求队列管理器
支持多用户并发处理、优先级队列、用户级别限流
"""

import asyncio
import time
import logging
import hashlib
import json
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict, deque
from enum import Enum

logger = logging.getLogger(__name__)

class RequestPriority(Enum):
    """请求优先级"""
    HIGH = 1
    NORMAL = 2
    LOW = 3

class RequestStatus(Enum):
    """请求状态"""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class RequestItem:
    """请求项数据类"""
    request_id: str
    user_id: int
    request_type: str
    data: Dict[str, Any]
    priority: RequestPriority
    created_at: float
    timeout: int = 60
    retry_count: int = 0
    max_retries: int = 3
    status: RequestStatus = RequestStatus.PENDING
    result: Optional[Dict] = None
    error: Optional[Dict] = None
    processing_start_time: Optional[float] = None

class RateLimitExceedException(Exception):
    """速率限制异常"""
    pass

class UserRateLimiter:
    """用户级别速率限制器"""
    
    def __init__(self, max_requests_per_minute: int = 60, max_requests_per_hour: int = 1000):
        self.max_requests_per_minute = max_requests_per_minute
        self.max_requests_per_hour = max_requests_per_hour
        self.user_requests = defaultdict(lambda: {"minute": deque(), "hour": deque()})
        
    def check_rate_limit(self, user_id: int) -> bool:
        """检查用户是否超过速率限制"""
        current_time = time.time()
        user_data = self.user_requests[user_id]
        
        # 清理过期的请求记录
        self._cleanup_expired_requests(user_data, current_time)
        
        # 检查每分钟限制
        if len(user_data["minute"]) >= self.max_requests_per_minute:
            return False
            
        # 检查每小时限制
        if len(user_data["hour"]) >= self.max_requests_per_hour:
            return False
            
        return True
    
    def record_request(self, user_id: int):
        """记录用户请求"""
        current_time = time.time()
        user_data = self.user_requests[user_id]
        
        user_data["minute"].append(current_time)
        user_data["hour"].append(current_time)
        
        # 清理过期记录
        self._cleanup_expired_requests(user_data, current_time)
    
    def _cleanup_expired_requests(self, user_data: Dict, current_time: float):
        """清理过期的请求记录"""
        # 清理1分钟前的记录
        while user_data["minute"] and current_time - user_data["minute"][0] > 60:
            user_data["minute"].popleft()
            
        # 清理1小时前的记录
        while user_data["hour"] and current_time - user_data["hour"][0] > 3600:
            user_data["hour"].popleft()
    
    def get_user_stats(self, user_id: int) -> Dict[str, Any]:
        """获取用户速率限制统计"""
        current_time = time.time()
        user_data = self.user_requests[user_id]
        self._cleanup_expired_requests(user_data, current_time)
        
        return {
            "requests_last_minute": len(user_data["minute"]),
            "requests_last_hour": len(user_data["hour"]),
            "remaining_requests_minute": max(0, self.max_requests_per_minute - len(user_data["minute"])),
            "remaining_requests_hour": max(0, self.max_requests_per_hour - len(user_data["hour"]))
        }

class RequestQueueManager:
    """异步请求队列管理器"""
    
    def __init__(self, max_concurrent: int = 15, max_queue_size: int = 200):
        self.max_concurrent = max_concurrent
        self.max_queue_size = max_queue_size
        
        # 优先级队列
        self.priority_queues = {
            RequestPriority.HIGH: asyncio.Queue(maxsize=max_queue_size),
            RequestPriority.NORMAL: asyncio.Queue(maxsize=max_queue_size),
            RequestPriority.LOW: asyncio.Queue(maxsize=max_queue_size)
        }
        
        # 并发控制
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.processing_tasks = {}  # request_id -> task
        
        # 请求存储和结果缓存
        self.pending_requests = {}  # request_id -> RequestItem
        self.completed_requests = {}  # request_id -> RequestItem (最近100个)
        self.max_completed_cache = 100
        
        # 速率限制
        self.rate_limiter = UserRateLimiter()
        
        # 统计信息
        self.stats = {
            "total_requests": 0,
            "completed_requests": 0,
            "failed_requests": 0,
            "cancelled_requests": 0,
            "current_queue_size": 0,
            "current_processing": 0,
            "average_processing_time_ms": 0.0
        }
        
        self.processing_times = deque(maxlen=1000)  # 保留最近1000次处理时间
        
        # 处理器注册表
        self.request_processors = {}  # request_type -> processor_function
        
        # 启动后台处理任务
        self.background_task = None
        self.is_running = False
    
    def register_processor(self, request_type: str, processor: Callable):
        """注册请求处理器"""
        self.request_processors[request_type] = processor
        logger.info(f"注册请求处理器: {request_type}")
    
    async def start(self):
        """启动队列管理器"""
        if self.is_running:
            return
            
        self.is_running = True
        self.background_task = asyncio.create_task(self._process_requests_background())
        logger.info("请求队列管理器已启动")
    
    async def stop(self):
        """停止队列管理器"""
        self.is_running = False
        
        if self.background_task:
            self.background_task.cancel()
            try:
                await self.background_task
            except asyncio.CancelledError:
                pass
        
        # 取消所有正在处理的任务
        for task in self.processing_tasks.values():
            if not task.done():
                task.cancel()
        
        # 等待所有任务完成
        if self.processing_tasks:
            await asyncio.gather(*self.processing_tasks.values(), return_exceptions=True)
        
        logger.info("请求队列管理器已停止")
    
    async def enqueue_request(self, user_id: int, request_type: str, 
                            request_data: Dict[str, Any], 
                            priority: RequestPriority = RequestPriority.NORMAL,
                            timeout: int = 60) -> str:
        """请求入队，返回请求ID"""
        
        # 用户级别限流检查
        if not self.rate_limiter.check_rate_limit(user_id):
            user_stats = self.rate_limiter.get_user_stats(user_id)
            raise RateLimitExceedException(
                f"用户 {user_id} 请求频率过高。"
                f"每分钟限制: {user_stats['remaining_requests_minute']}/{self.rate_limiter.max_requests_per_minute}, "
                f"每小时限制: {user_stats['remaining_requests_hour']}/{self.rate_limiter.max_requests_per_hour}"
            )
        
        # 生成请求ID
        request_id = self._generate_request_id(user_id, request_type)
        
        # 创建请求项
        request_item = RequestItem(
            request_id=request_id,
            user_id=user_id,
            request_type=request_type,
            data=request_data,
            priority=priority,
            created_at=time.time(),
            timeout=timeout
        )
        
        # 检查队列是否满
        queue = self.priority_queues[priority]
        if queue.qsize() >= self.max_queue_size:
            raise Exception(f"队列已满，请稍后重试。当前队列大小: {queue.qsize()}")
        
        # 入队
        await queue.put(request_item)
        self.pending_requests[request_id] = request_item
        
        # 记录用户请求
        self.rate_limiter.record_request(user_id)
        
        # 更新统计
        self.stats["total_requests"] += 1
        self._update_queue_size()
        
        logger.info(f"请求入队: {request_id}, 用户: {user_id}, 类型: {request_type}, 优先级: {priority.name}")
        return request_id
    
    async def get_request_status(self, request_id: str) -> Optional[Dict[str, Any]]:
        """获取请求状态"""
        # 检查正在处理的请求
        if request_id in self.pending_requests:
            request_item = self.pending_requests[request_id]
            return {
                "request_id": request_id,
                "status": request_item.status.value,
                "created_at": request_item.created_at,
                "processing_start_time": request_item.processing_start_time,
                "elapsed_time_ms": int((time.time() - request_item.created_at) * 1000),
                "result": request_item.result,
                "error": request_item.error
            }
        
        # 检查已完成的请求
        if request_id in self.completed_requests:
            request_item = self.completed_requests[request_id]
            return {
                "request_id": request_id,
                "status": request_item.status.value,
                "created_at": request_item.created_at,
                "processing_start_time": request_item.processing_start_time,
                "elapsed_time_ms": int((time.time() - request_item.created_at) * 1000),
                "result": request_item.result,
                "error": request_item.error
            }
        
        return None
    
    async def cancel_request(self, request_id: str) -> bool:
        """取消请求"""
        if request_id in self.pending_requests:
            request_item = self.pending_requests[request_id]
            
            # 如果正在处理，取消任务
            if request_id in self.processing_tasks:
                task = self.processing_tasks[request_id]
                if not task.done():
                    task.cancel()
                    request_item.status = RequestStatus.CANCELLED
                    logger.info(f"取消正在处理的请求: {request_id}")
                    return True
            else:
                # 如果还在队列中，标记为取消
                request_item.status = RequestStatus.CANCELLED
                logger.info(f"取消队列中的请求: {request_id}")
                return True
        
        return False
    
    def _generate_request_id(self, user_id: int, request_type: str) -> str:
        """生成唯一请求ID"""
        timestamp = int(time.time() * 1000)
        content = f"{user_id}_{request_type}_{timestamp}"
        hash_part = hashlib.md5(content.encode()).hexdigest()[:8]
        return f"{user_id}_{request_type}_{timestamp}_{hash_part}"
    
    async def _process_requests_background(self):
        """后台请求处理器"""
        logger.info("开始后台请求处理")
        
        while self.is_running:
            try:
                # 按优先级处理请求
                request_item = await self._get_next_request()
                
                if request_item and request_item.status != RequestStatus.CANCELLED:
                    # 创建处理任务
                    task = asyncio.create_task(
                        self._process_single_request(request_item)
                    )
                    self.processing_tasks[request_item.request_id] = task
                    
                    # 任务完成后清理
                    task.add_done_callback(
                        lambda t, rid=request_item.request_id: self._cleanup_completed_task(rid)
                    )
                
                # 短暂休息，避免CPU占用过高
                await asyncio.sleep(0.01)
                
            except asyncio.CancelledError:
                logger.info("后台处理任务被取消")
                break
            except Exception as e:
                logger.error(f"后台处理异常: {e}")
                await asyncio.sleep(1)
    
    async def _get_next_request(self) -> Optional[RequestItem]:
        """按优先级获取下一个请求"""
        # 按优先级顺序检查队列
        for priority in [RequestPriority.HIGH, RequestPriority.NORMAL, RequestPriority.LOW]:
            queue = self.priority_queues[priority]
            if not queue.empty():
                try:
                    request_item = await asyncio.wait_for(queue.get(), timeout=0.1)
                    return request_item
                except asyncio.TimeoutError:
                    continue
        
        return None
    
    async def _process_single_request(self, request_item: RequestItem):
        """处理单个请求"""
        async with self.semaphore:
            request_item.status = RequestStatus.PROCESSING
            request_item.processing_start_time = time.time()
            self.stats["current_processing"] += 1
            
            try:
                # 检查超时
                if time.time() - request_item.created_at > request_item.timeout:
                    raise asyncio.TimeoutError("请求超时")
                
                # 获取处理器
                processor = self.request_processors.get(request_item.request_type)
                if not processor:
                    raise Exception(f"未找到请求类型 {request_item.request_type} 的处理器")
                
                # 执行处理
                result = await asyncio.wait_for(
                    processor(request_item.data),
                    timeout=request_item.timeout
                )
                
                # 处理成功
                request_item.status = RequestStatus.COMPLETED
                request_item.result = result
                self.stats["completed_requests"] += 1
                
                # 记录处理时间
                processing_time = (time.time() - request_item.processing_start_time) * 1000
                self.processing_times.append(processing_time)
                self._update_average_processing_time()
                
                logger.info(f"请求处理成功: {request_item.request_id}, 用时: {processing_time:.1f}ms")
                
            except asyncio.CancelledError:
                request_item.status = RequestStatus.CANCELLED
                self.stats["cancelled_requests"] += 1
                logger.info(f"请求被取消: {request_item.request_id}")
                
            except Exception as e:
                # 处理失败，考虑重试
                request_item.retry_count += 1
                
                if request_item.retry_count <= request_item.max_retries:
                    # 重新入队重试
                    logger.warning(f"请求失败，准备重试 ({request_item.retry_count}/{request_item.max_retries}): {request_item.request_id}, 错误: {e}")
                    await asyncio.sleep(min(2 ** request_item.retry_count, 10))  # 指数退避
                    
                    queue = self.priority_queues[request_item.priority]
                    await queue.put(request_item)
                    request_item.status = RequestStatus.PENDING
                else:
                    # 超过最大重试次数
                    request_item.status = RequestStatus.FAILED
                    request_item.error = {
                        "code": "PROCESSING_FAILED",
                        "message": str(e),
                        "retry_count": request_item.retry_count
                    }
                    self.stats["failed_requests"] += 1
                    logger.error(f"请求处理失败（超过最大重试次数）: {request_item.request_id}, 错误: {e}")
            
            finally:
                self.stats["current_processing"] -= 1
                
                # 移动到完成缓存
                if request_item.status in [RequestStatus.COMPLETED, RequestStatus.FAILED, RequestStatus.CANCELLED]:
                    self._move_to_completed_cache(request_item)
    
    def _cleanup_completed_task(self, request_id: str):
        """清理已完成的任务"""
        if request_id in self.processing_tasks:
            del self.processing_tasks[request_id]
    
    def _move_to_completed_cache(self, request_item: RequestItem):
        """移动请求到完成缓存"""
        if request_item.request_id in self.pending_requests:
            del self.pending_requests[request_item.request_id]
        
        # 添加到完成缓存
        self.completed_requests[request_item.request_id] = request_item
        
        # 保持缓存大小限制
        if len(self.completed_requests) > self.max_completed_cache:
            # 删除最旧的请求
            oldest_request_id = min(
                self.completed_requests.keys(),
                key=lambda x: self.completed_requests[x].created_at
            )
            del self.completed_requests[oldest_request_id]
    
    def _update_queue_size(self):
        """更新队列大小统计"""
        total_size = sum(queue.qsize() for queue in self.priority_queues.values())
        self.stats["current_queue_size"] = total_size
    
    def _update_average_processing_time(self):
        """更新平均处理时间"""
        if self.processing_times:
            self.stats["average_processing_time_ms"] = sum(self.processing_times) / len(self.processing_times)
    
    def get_queue_stats(self) -> Dict[str, Any]:
        """获取队列统计信息"""
        self._update_queue_size()
        
        return {
            **self.stats,
            "queue_sizes": {
                priority.name: queue.qsize() 
                for priority, queue in self.priority_queues.items()
            },
            "processing_tasks_count": len(self.processing_tasks),
            "pending_requests_count": len(self.pending_requests),
            "completed_cache_size": len(self.completed_requests),
            "rate_limiter_stats": {
                "max_requests_per_minute": self.rate_limiter.max_requests_per_minute,
                "max_requests_per_hour": self.rate_limiter.max_requests_per_hour
            }
        }

# 全局队列管理器实例
_global_queue_manager = None

def get_queue_manager() -> RequestQueueManager:
    """获取全局队列管理器实例"""
    global _global_queue_manager
    if _global_queue_manager is None:
        import os
        max_concurrent = int(os.getenv("MAX_CONCURRENT_REQUESTS", "15"))
        max_queue_size = int(os.getenv("MAX_QUEUE_SIZE", "200"))
        _global_queue_manager = RequestQueueManager(max_concurrent, max_queue_size)
    return _global_queue_manager

# 便捷函数
async def enqueue_recommendation_request(user_id: int, request_type: str, 
                                       data: Dict[str, Any], 
                                       priority: RequestPriority = RequestPriority.NORMAL) -> str:
    """便捷的推荐请求入队函数"""
    queue_manager = get_queue_manager()
    if not queue_manager.is_running:
        await queue_manager.start()
    
    return await queue_manager.enqueue_request(user_id, request_type, data, priority)

async def get_recommendation_result(request_id: str) -> Optional[Dict[str, Any]]:
    """便捷的推荐结果获取函数"""
    queue_manager = get_queue_manager()
    return await queue_manager.get_request_status(request_id)