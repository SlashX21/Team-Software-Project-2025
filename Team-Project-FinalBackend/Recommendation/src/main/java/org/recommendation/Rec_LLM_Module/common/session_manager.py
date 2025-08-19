"""
用户会话管理器
支持会话状态跟踪、重复请求检测、用户行为分析
"""

import time
import hashlib
import json
import uuid
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict, deque

logger = logging.getLogger(__name__)

@dataclass
class SessionInfo:
    """会话信息"""
    session_id: str
    user_id: int
    created_at: datetime
    last_activity: datetime
    request_count: int = 0
    total_processing_time_ms: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    user_agent: Optional[str] = None
    ip_address: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class RequestRecord:
    """请求记录"""
    request_hash: str
    request_type: str
    timestamp: float
    response_time_ms: int
    success: bool
    cache_hit: bool = False
    user_id: Optional[int] = None

class SessionManager:
    """用户会话管理器"""
    
    def __init__(self, session_timeout_minutes: int = 60, max_sessions: int = 10000):
        self.session_timeout = timedelta(minutes=session_timeout_minutes)
        self.max_sessions = max_sessions
        
        # 会话存储
        self.active_sessions = {}  # user_id -> SessionInfo
        self.session_by_id = {}    # session_id -> SessionInfo
        
        # 请求历史跟踪
        self.user_request_history = defaultdict(lambda: deque(maxlen=100))  # user_id -> [RequestRecord]
        
        # 重复请求检测
        self.recent_requests = defaultdict(lambda: deque(maxlen=50))  # user_id -> [request_hash]
        self.duplicate_detection_window = 300  # 5分钟
        
        # 用户行为模式分析
        self.user_patterns = defaultdict(lambda: {
            "request_intervals": deque(maxlen=20),  # 请求间隔时间
            "preferred_request_types": defaultdict(int),  # 偏好的请求类型
            "peak_hours": defaultdict(int),  # 活跃时间段
            "average_session_duration": 0.0,  # 平均会话时长
            "total_sessions": 0
        })
        
        # 缓存管理
        self.cache_manager = None  # 将在需要时初始化
        
        # 统计信息
        self.stats = {
            "total_sessions_created": 0,
            "active_sessions_count": 0,
            "expired_sessions_cleaned": 0,
            "duplicate_requests_detected": 0,
            "cache_hits": 0,
            "cache_misses": 0
        }
    
    def create_session(self, user_id: int, user_agent: Optional[str] = None, 
                      ip_address: Optional[str] = None) -> str:
        """创建用户会话"""
        # 检查是否已有活跃会话
        if user_id in self.active_sessions:
            existing_session = self.active_sessions[user_id]
            # 如果会话还未过期，更新活动时间并返回现有会话
            if datetime.now() - existing_session.last_activity < self.session_timeout:
                existing_session.last_activity = datetime.now()
                logger.debug(f"用户 {user_id} 使用现有会话: {existing_session.session_id}")
                return existing_session.session_id
            else:
                # 会话过期，清理旧会话
                self._cleanup_session(user_id)
        
        # 创建新会话
        session_id = f"session_{user_id}_{uuid.uuid4().hex[:8]}_{int(time.time())}"
        now = datetime.now()
        
        session_info = SessionInfo(
            session_id=session_id,
            user_id=user_id,
            created_at=now,
            last_activity=now,
            user_agent=user_agent,
            ip_address=ip_address
        )
        
        # 存储会话
        self.active_sessions[user_id] = session_info
        self.session_by_id[session_id] = session_info
        
        # 更新统计
        self.stats["total_sessions_created"] += 1
        self.stats["active_sessions_count"] = len(self.active_sessions)
        
        # 更新用户模式分析
        user_pattern = self.user_patterns[user_id]
        user_pattern["total_sessions"] += 1
        
        # 如果不是第一次会话，记录会话间隔
        if len(self.user_request_history[user_id]) > 0:
            last_request = self.user_request_history[user_id][-1]
            interval = now.timestamp() - last_request.timestamp
            user_pattern["request_intervals"].append(interval)
        
        # 清理过期会话（定期维护）
        if len(self.active_sessions) > self.max_sessions * 0.8:
            self._cleanup_expired_sessions()
        
        logger.info(f"创建新会话: {session_id}, 用户: {user_id}")
        return session_id
    
    def get_session(self, session_id: str) -> Optional[SessionInfo]:
        """获取会话信息"""
        session = self.session_by_id.get(session_id)
        if session and self._is_session_valid(session):
            return session
        return None
    
    def get_user_session(self, user_id: int) -> Optional[SessionInfo]:
        """获取用户的活跃会话"""
        session = self.active_sessions.get(user_id)
        if session and self._is_session_valid(session):
            return session
        return None
    
    def update_session_activity(self, user_id: int, request_type: str, 
                              response_time_ms: int, success: bool):
        """更新会话活动"""
        session = self.active_sessions.get(user_id)
        if not session:
            return
        
        # 更新会话信息
        session.last_activity = datetime.now()
        session.request_count += 1
        session.total_processing_time_ms += response_time_ms
        
        if success:
            session.successful_requests += 1
        else:
            session.failed_requests += 1
        
        # 记录请求历史
        request_record = RequestRecord(
            request_hash="",  # 将在check_duplicate_request中设置
            request_type=request_type,
            timestamp=time.time(),
            response_time_ms=response_time_ms,
            success=success,
            user_id=user_id
        )
        self.user_request_history[user_id].append(request_record)
        
        # 更新用户行为模式
        self._update_user_patterns(user_id, request_type, session)
    
    def check_duplicate_request(self, user_id: int, request_data: Dict[str, Any]) -> bool:
        """检查重复请求"""
        # 生成请求哈希
        request_hash = self._generate_request_hash(request_data)
        
        # 检查最近的请求
        recent_requests = self.recent_requests[user_id]
        current_time = time.time()
        
        # 清理过期的请求记录
        while recent_requests and current_time - recent_requests[0] > self.duplicate_detection_window:
            recent_requests.popleft()
        
        # 检查是否为重复请求
        if request_hash in recent_requests:
            self.stats["duplicate_requests_detected"] += 1
            logger.warning(f"检测到重复请求: 用户 {user_id}, 哈希: {request_hash[:8]}")
            return True
        
        # 记录新请求
        recent_requests.append(request_hash)
        return False
    
    def get_user_behavior_analysis(self, user_id: int) -> Dict[str, Any]:
        """获取用户行为分析"""
        if user_id not in self.user_patterns:
            return {"analysis": "insufficient_data", "message": "用户数据不足"}
        
        pattern = self.user_patterns[user_id]
        request_history = list(self.user_request_history[user_id])
        
        analysis = {
            "user_id": user_id,
            "total_sessions": pattern["total_sessions"],
            "total_requests": len(request_history),
            "analysis_timestamp": datetime.now().isoformat()
        }
        
        # 请求频率分析
        if len(request_history) > 1:
            intervals = []
            for i in range(1, len(request_history)):
                interval = request_history[i].timestamp - request_history[i-1].timestamp
                intervals.append(interval)
            
            analysis["request_frequency"] = {
                "average_interval_seconds": sum(intervals) / len(intervals),
                "min_interval_seconds": min(intervals),
                "max_interval_seconds": max(intervals)
            }
        
        # 请求类型偏好
        type_counts = defaultdict(int)
        success_rates = defaultdict(lambda: {"total": 0, "success": 0})
        
        for record in request_history:
            type_counts[record.request_type] += 1
            success_rates[record.request_type]["total"] += 1
            if record.success:
                success_rates[record.request_type]["success"] += 1
        
        analysis["request_types"] = {
            "preferences": dict(type_counts),
            "success_rates": {
                req_type: stats["success"] / stats["total"] 
                for req_type, stats in success_rates.items()
            }
        }
        
        # 活跃时间分析
        hour_counts = defaultdict(int)
        for record in request_history:
            hour = datetime.fromtimestamp(record.timestamp).hour
            hour_counts[hour] += 1
        
        if hour_counts:
            peak_hour = max(hour_counts.items(), key=lambda x: x[1])
            analysis["activity_patterns"] = {
                "peak_hour": peak_hour[0],
                "peak_hour_requests": peak_hour[1],
                "hourly_distribution": dict(hour_counts)
            }
        
        # 性能统计
        response_times = [r.response_time_ms for r in request_history if r.success]
        if response_times:
            analysis["performance"] = {
                "average_response_time_ms": sum(response_times) / len(response_times),
                "min_response_time_ms": min(response_times),
                "max_response_time_ms": max(response_times)
            }
        
        return analysis
    
    def get_session_summary(self, session_id: str) -> Optional[Dict[str, Any]]:
        """获取会话摘要"""
        session = self.session_by_id.get(session_id)
        if not session:
            return None
        
        duration_seconds = (session.last_activity - session.created_at).total_seconds()
        
        return {
            "session_id": session_id,
            "user_id": session.user_id,
            "created_at": session.created_at.isoformat(),
            "last_activity": session.last_activity.isoformat(),
            "duration_seconds": duration_seconds,
            "request_count": session.request_count,
            "successful_requests": session.successful_requests,
            "failed_requests": session.failed_requests,
            "success_rate": session.successful_requests / max(session.request_count, 1),
            "average_response_time_ms": session.total_processing_time_ms / max(session.request_count, 1),
            "user_agent": session.user_agent,
            "ip_address": session.ip_address,
            "is_valid": self._is_session_valid(session)
        }
    
    def _generate_request_hash(self, request_data: Dict[str, Any]) -> str:
        """生成请求哈希"""
        # 移除时间戳等变化的字段
        stable_data = {k: v for k, v in request_data.items() 
                      if k not in ['timestamp', 'requestId', 'sessionId']}
        
        data_str = json.dumps(stable_data, sort_keys=True)
        return hashlib.md5(data_str.encode()).hexdigest()
    
    def _is_session_valid(self, session: SessionInfo) -> bool:
        """检查会话是否有效"""
        return datetime.now() - session.last_activity < self.session_timeout
    
    def _cleanup_session(self, user_id: int):
        """清理单个会话"""
        if user_id in self.active_sessions:
            session = self.active_sessions[user_id]
            
            # 更新用户模式中的会话时长
            duration = (session.last_activity - session.created_at).total_seconds()
            pattern = self.user_patterns[user_id]
            
            if pattern["total_sessions"] > 0:
                current_avg = pattern["average_session_duration"]
                total_sessions = pattern["total_sessions"]
                pattern["average_session_duration"] = (
                    (current_avg * (total_sessions - 1) + duration) / total_sessions
                )
            
            # 删除会话
            session_id = session.session_id
            del self.active_sessions[user_id]
            if session_id in self.session_by_id:
                del self.session_by_id[session_id]
            
            logger.debug(f"清理会话: {session_id}, 用户: {user_id}")
    
    def _cleanup_expired_sessions(self):
        """清理过期会话"""
        current_time = datetime.now()
        expired_users = []
        
        for user_id, session in self.active_sessions.items():
            if current_time - session.last_activity >= self.session_timeout:
                expired_users.append(user_id)
        
        for user_id in expired_users:
            self._cleanup_session(user_id)
        
        self.stats["expired_sessions_cleaned"] += len(expired_users)
        self.stats["active_sessions_count"] = len(self.active_sessions)
        
        if expired_users:
            logger.info(f"清理了 {len(expired_users)} 个过期会话")
    
    def _update_user_patterns(self, user_id: int, request_type: str, session: SessionInfo):
        """更新用户行为模式"""
        pattern = self.user_patterns[user_id]
        
        # 更新请求类型偏好
        pattern["preferred_request_types"][request_type] += 1
        
        # 更新活跃时间
        current_hour = datetime.now().hour
        pattern["peak_hours"][current_hour] += 1
    
    def get_global_stats(self) -> Dict[str, Any]:
        """获取全局统计信息"""
        # 更新当前活跃会话数
        self.stats["active_sessions_count"] = len(self.active_sessions)
        
        # 计算额外统计信息
        total_requests = sum(len(history) for history in self.user_request_history.values())
        active_users = len([s for s in self.active_sessions.values() if self._is_session_valid(s)])
        
        enhanced_stats = {
            **self.stats,
            "total_requests_processed": total_requests,
            "active_users_count": active_users,
            "total_users_tracked": len(self.user_patterns),
            "average_requests_per_user": total_requests / max(len(self.user_patterns), 1),
            "memory_usage": {
                "active_sessions": len(self.active_sessions),
                "session_by_id": len(self.session_by_id),
                "user_patterns": len(self.user_patterns),
                "request_histories": len(self.user_request_history)
            }
        }
        
        return enhanced_stats
    
    def cleanup_old_data(self, days_to_keep: int = 7):
        """清理旧数据"""
        cutoff_time = time.time() - (days_to_keep * 24 * 3600)
        cleaned_users = 0
        
        # 清理旧的请求历史
        for user_id, history in self.user_request_history.items():
            original_length = len(history)
            # 保留最近的请求
            while history and history[0].timestamp < cutoff_time:
                history.popleft()
            
            if len(history) < original_length:
                cleaned_users += 1
        
        logger.info(f"清理了 {cleaned_users} 个用户的旧请求历史数据")

# 全局会话管理器实例
_global_session_manager = None

def get_session_manager() -> SessionManager:
    """获取全局会话管理器实例"""
    global _global_session_manager
    if _global_session_manager is None:
        import os
        timeout_minutes = int(os.getenv("SESSION_TIMEOUT_MINUTES", "60"))
        max_sessions = int(os.getenv("MAX_SESSIONS", "10000"))
        _global_session_manager = SessionManager(timeout_minutes, max_sessions)
    return _global_session_manager

# 便捷函数
def create_user_session(user_id: int, user_agent: Optional[str] = None, 
                       ip_address: Optional[str] = None) -> str:
    """便捷的会话创建函数"""
    session_manager = get_session_manager()
    return session_manager.create_session(user_id, user_agent, ip_address)

def get_user_session_info(user_id: int) -> Optional[Dict[str, Any]]:
    """便捷的用户会话信息获取函数"""
    session_manager = get_session_manager()
    session = session_manager.get_user_session(user_id)
    if session:
        return session_manager.get_session_summary(session.session_id)
    return None

def is_duplicate_request(user_id: int, request_data: Dict[str, Any]) -> bool:
    """便捷的重复请求检查函数"""
    session_manager = get_session_manager()
    return session_manager.check_duplicate_request(user_id, request_data)