"""
统一错误处理器
提供一致的错误处理、日志记录和用户友好的错误响应
"""

import logging
import traceback
import time
from typing import Dict, List, Optional, Any, Callable, Type
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
import asyncio

logger = logging.getLogger(__name__)

class ErrorCategory(Enum):
    """错误分类"""
    VALIDATION_ERROR = "validation_error"
    AI_SERVICE_ERROR = "ai_service_error"
    DATABASE_ERROR = "database_error"
    NETWORK_ERROR = "network_error"
    RATE_LIMIT_ERROR = "rate_limit_error"
    AUTHENTICATION_ERROR = "authentication_error"
    AUTHORIZATION_ERROR = "authorization_error"
    TIMEOUT_ERROR = "timeout_error"
    SYSTEM_ERROR = "system_error"
    UNKNOWN_ERROR = "unknown_error"

class ErrorSeverity(Enum):
    """错误严重程度"""
    LOW = "low"        # 用户可以继续操作
    MEDIUM = "medium"  # 影响部分功能
    HIGH = "high"      # 影响主要功能
    CRITICAL = "critical"  # 系统不可用

@dataclass
class ErrorContext:
    """错误上下文信息"""
    user_id: Optional[int] = None
    request_id: Optional[str] = None
    session_id: Optional[str] = None
    operation: Optional[str] = None
    request_data: Optional[Dict[str, Any]] = None
    timestamp: float = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = time.time()

@dataclass
class ErrorInfo:
    """错误信息"""
    category: ErrorCategory
    severity: ErrorSeverity
    code: str
    message: str
    user_message: str
    details: Dict[str, Any]
    context: ErrorContext
    suggestions: List[str]
    retry_after: Optional[int] = None  # 秒数
    fallback_available: bool = False
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式"""
        return {
            "error": {
                "category": self.category.value,
                "severity": self.severity.value,
                "code": self.code,
                "message": self.message,
                "user_message": self.user_message,
                "details": self.details,
                "retry_after": self.retry_after,
                "fallback_available": self.fallback_available,
                "suggestions": self.suggestions,
                "timestamp": datetime.fromtimestamp(self.context.timestamp).isoformat(),
                "request_id": self.context.request_id
            }
        }

class ErrorHandler:
    """统一错误处理器"""
    
    def __init__(self):
        # 错误统计
        self.error_stats = {
            "total_errors": 0,
            "errors_by_category": {category.value: 0 for category in ErrorCategory},
            "errors_by_severity": {severity.value: 0 for severity in ErrorSeverity},
            "recent_errors": [],  # 最近100个错误
            "error_trends": {}  # 错误趋势分析
        }
        
        # 错误模式识别
        self.error_patterns = {}
        
        # 自定义错误处理器
        self.custom_handlers = {}  # exception_type -> handler_function
    
    def register_custom_handler(self, exception_type: Type[Exception], 
                               handler: Callable[[Exception, ErrorContext], ErrorInfo]):
        """注册自定义错误处理器"""
        self.custom_handlers[exception_type] = handler
        logger.info(f"注册自定义错误处理器: {exception_type.__name__}")
    
    def handle_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理错误"""
        try:
            # 检查是否有自定义处理器
            for exception_type, handler in self.custom_handlers.items():
                if isinstance(error, exception_type):
                    error_info = handler(error, context)
                    self._record_error(error_info)
                    return error_info
            
            # 使用默认处理器
            error_info = self._classify_and_handle_error(error, context)
            self._record_error(error_info)
            return error_info
            
        except Exception as handler_error:
            # 错误处理器本身出错
            logger.error(f"错误处理器异常: {handler_error}")
            return self._create_fallback_error_info(error, context)
    
    def _classify_and_handle_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """分类并处理错误"""
        error_type = type(error).__name__
        error_message = str(error).lower()
        
        # AI服务错误
        if self._is_ai_service_error(error, error_message):
            return self._handle_ai_service_error(error, context)
        
        # 数据库错误
        elif self._is_database_error(error, error_message):
            return self._handle_database_error(error, context)
        
        # 网络错误
        elif self._is_network_error(error, error_message):
            return self._handle_network_error(error, context)
        
        # 速率限制错误
        elif self._is_rate_limit_error(error, error_message):
            return self._handle_rate_limit_error(error, context)
        
        # 认证错误
        elif self._is_authentication_error(error, error_message):
            return self._handle_authentication_error(error, context)
        
        # 超时错误
        elif self._is_timeout_error(error, error_message):
            return self._handle_timeout_error(error, context)
        
        # 验证错误
        elif self._is_validation_error(error, error_message):
            return self._handle_validation_error(error, context)
        
        # 系统错误
        else:
            return self._handle_system_error(error, context)
    
    def _is_ai_service_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为AI服务错误"""
        ai_keywords = ['openai', 'azure', 'api', 'model', 'completion', 'llm']
        return any(keyword in error_message for keyword in ai_keywords) or \
               'openai' in type(error).__module__.lower()
    
    def _handle_ai_service_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理AI服务错误"""
        error_message = str(error).lower()
        
        if "rate limit" in error_message or "429" in error_message:
            return ErrorInfo(
                category=ErrorCategory.RATE_LIMIT_ERROR,
                severity=ErrorSeverity.MEDIUM,
                code="AI_RATE_LIMIT_EXCEEDED",
                message=f"AI服务速率限制: {str(error)}",
                user_message="AI服务繁忙，请稍后重试",
                details={"original_error": str(error), "service": "AI"},
                context=context,
                suggestions=["等待1-2分钟后重试", "如果问题持续，请联系技术支持"],
                retry_after=60,
                fallback_available=True
            )
        
        elif "invalid api key" in error_message or "401" in error_message:
            return ErrorInfo(
                category=ErrorCategory.AUTHENTICATION_ERROR,
                severity=ErrorSeverity.HIGH,
                code="AI_AUTH_ERROR",
                message=f"AI服务认证失败: {str(error)}",
                user_message="AI服务配置错误，请联系技术支持",
                details={"original_error": str(error), "service": "AI"},
                context=context,
                suggestions=["联系技术支持检查API配置"],
                fallback_available=True
            )
        
        elif "timeout" in error_message:
            return ErrorInfo(
                category=ErrorCategory.TIMEOUT_ERROR,
                severity=ErrorSeverity.MEDIUM,
                code="AI_TIMEOUT",
                message=f"AI服务响应超时: {str(error)}",
                user_message="AI服务响应超时，请重试",
                details={"original_error": str(error), "service": "AI"},
                context=context,
                suggestions=["重新尝试请求", "简化输入内容"],
                retry_after=30,
                fallback_available=True
            )
        
        else:
            return ErrorInfo(
                category=ErrorCategory.AI_SERVICE_ERROR,
                severity=ErrorSeverity.MEDIUM,
                code="AI_SERVICE_ERROR",
                message=f"AI服务错误: {str(error)}",
                user_message="AI分析服务暂时不可用",
                details={"original_error": str(error), "service": "AI"},
                context=context,
                suggestions=["稍后重试", "查看推荐结果的基础信息"],
                retry_after=120,
                fallback_available=True
            )
    
    def _is_database_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为数据库错误"""
        db_keywords = ['database', 'connection', 'mysql', 'postgresql', 'sql', 'pymysql']
        return any(keyword in error_message for keyword in db_keywords) or \
               any(keyword in type(error).__module__.lower() for keyword in ['sql', 'mysql', 'db'])
    
    def _handle_database_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理数据库错误"""
        error_message = str(error).lower()
        
        if "connection" in error_message:
            return ErrorInfo(
                category=ErrorCategory.DATABASE_ERROR,
                severity=ErrorSeverity.HIGH,
                code="DATABASE_CONNECTION_ERROR",
                message=f"数据库连接失败: {str(error)}",
                user_message="数据服务暂时不可用，请稍后重试",
                details={"original_error": str(error), "operation": context.operation},
                context=context,
                suggestions=["稍后重试", "如果问题持续，请联系技术支持"],
                retry_after=60,
                fallback_available=False
            )
        
        elif "timeout" in error_message:
            return ErrorInfo(
                category=ErrorCategory.TIMEOUT_ERROR,
                severity=ErrorSeverity.MEDIUM,
                code="DATABASE_TIMEOUT",
                message=f"数据库操作超时: {str(error)}",
                user_message="数据操作超时，请重试",
                details={"original_error": str(error), "operation": context.operation},
                context=context,
                suggestions=["重新尝试", "简化查询条件"],
                retry_after=30,
                fallback_available=False
            )
        
        else:
            return ErrorInfo(
                category=ErrorCategory.DATABASE_ERROR,
                severity=ErrorSeverity.HIGH,
                code="DATABASE_ERROR",
                message=f"数据库错误: {str(error)}",
                user_message="数据服务错误，请稍后重试",
                details={"original_error": str(error), "operation": context.operation},
                context=context,
                suggestions=["稍后重试", "联系技术支持"],
                retry_after=60,
                fallback_available=False
            )
    
    def _is_network_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为网络错误"""
        network_keywords = ['connection', 'network', 'socket', 'dns', 'host', 'unreachable']
        return any(keyword in error_message for keyword in network_keywords) and \
               not self._is_database_error(error, error_message)
    
    def _handle_network_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理网络错误"""
        return ErrorInfo(
            category=ErrorCategory.NETWORK_ERROR,
            severity=ErrorSeverity.MEDIUM,
            code="NETWORK_ERROR",
            message=f"网络连接错误: {str(error)}",
            user_message="网络连接异常，请检查网络后重试",
            details={"original_error": str(error)},
            context=context,
            suggestions=["检查网络连接", "稍后重试"],
            retry_after=30,
            fallback_available=True
        )
    
    def _is_rate_limit_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为速率限制错误"""
        return "rate limit" in error_message or "429" in error_message or \
               "too many requests" in error_message
    
    def _handle_rate_limit_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理速率限制错误"""
        return ErrorInfo(
            category=ErrorCategory.RATE_LIMIT_ERROR,
            severity=ErrorSeverity.MEDIUM,
            code="RATE_LIMIT_EXCEEDED",
            message=f"请求频率过高: {str(error)}",
            user_message="请求过于频繁，请稍后重试",
            details={"original_error": str(error), "user_id": context.user_id},
            context=context,
            suggestions=["等待1-2分钟后重试", "减少请求频率"],
            retry_after=60,
            fallback_available=True
        )
    
    def _is_authentication_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为认证错误"""
        auth_keywords = ['unauthorized', '401', 'authentication', 'invalid api key', 'access denied']
        return any(keyword in error_message for keyword in auth_keywords)
    
    def _handle_authentication_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理认证错误"""
        return ErrorInfo(
            category=ErrorCategory.AUTHENTICATION_ERROR,
            severity=ErrorSeverity.HIGH,
            code="AUTH_ERROR",
            message=f"认证失败: {str(error)}",
            user_message="服务认证失败，请联系技术支持",
            details={"original_error": str(error)},
            context=context,
            suggestions=["联系技术支持", "检查服务配置"],
            fallback_available=False
        )
    
    def _is_timeout_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为超时错误"""
        return "timeout" in error_message or isinstance(error, asyncio.TimeoutError)
    
    def _handle_timeout_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理超时错误"""
        return ErrorInfo(
            category=ErrorCategory.TIMEOUT_ERROR,
            severity=ErrorSeverity.MEDIUM,
            code="REQUEST_TIMEOUT",
            message=f"请求超时: {str(error)}",
            user_message="请求处理超时，请重试",
            details={"original_error": str(error), "operation": context.operation},
            context=context,
            suggestions=["重新尝试", "简化请求内容", "检查网络连接"],
            retry_after=30,
            fallback_available=True
        )
    
    def _is_validation_error(self, error: Exception, error_message: str) -> bool:
        """判断是否为验证错误"""
        validation_keywords = ['validation', 'invalid', 'required', 'format', 'schema']
        return any(keyword in error_message for keyword in validation_keywords) or \
               'ValidationError' in type(error).__name__
    
    def _handle_validation_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理验证错误"""
        return ErrorInfo(
            category=ErrorCategory.VALIDATION_ERROR,
            severity=ErrorSeverity.LOW,
            code="VALIDATION_ERROR",
            message=f"数据验证失败: {str(error)}",
            user_message="请求数据格式不正确，请检查输入",
            details={"original_error": str(error), "request_data": context.request_data},
            context=context,
            suggestions=["检查输入数据格式", "参考API文档", "联系技术支持"],
            fallback_available=False
        )
    
    def _handle_system_error(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """处理系统错误"""
        return ErrorInfo(
            category=ErrorCategory.SYSTEM_ERROR,
            severity=ErrorSeverity.HIGH,
            code="SYSTEM_ERROR",
            message=f"系统错误: {str(error)}",
            user_message="系统错误，请稍后重试或联系技术支持",
            details={
                "original_error": str(error),
                "error_type": type(error).__name__,
                "traceback": traceback.format_exc()
            },
            context=context,
            suggestions=["稍后重试", "如果问题持续，请联系技术支持"],
            retry_after=120,
            fallback_available=False
        )
    
    def _create_fallback_error_info(self, error: Exception, context: ErrorContext) -> ErrorInfo:
        """创建降级错误信息"""
        return ErrorInfo(
            category=ErrorCategory.UNKNOWN_ERROR,
            severity=ErrorSeverity.CRITICAL,
            code="ERROR_HANDLER_FAILURE",
            message=f"错误处理器异常: {str(error)}",
            user_message="系统遇到未知错误，请联系技术支持",
            details={"original_error": str(error)},
            context=context,
            suggestions=["联系技术支持"],
            fallback_available=False
        )
    
    def _record_error(self, error_info: ErrorInfo):
        """记录错误信息"""
        # 更新统计
        self.error_stats["total_errors"] += 1
        self.error_stats["errors_by_category"][error_info.category.value] += 1
        self.error_stats["errors_by_severity"][error_info.severity.value] += 1
        
        # 记录最近错误
        self.error_stats["recent_errors"].append({
            "timestamp": error_info.context.timestamp,
            "category": error_info.category.value,
            "severity": error_info.severity.value,
            "code": error_info.code,
            "user_id": error_info.context.user_id,
            "operation": error_info.context.operation
        })
        
        # 保持最近错误列表大小
        if len(self.error_stats["recent_errors"]) > 100:
            self.error_stats["recent_errors"] = self.error_stats["recent_errors"][-100:]
        
        # 日志记录
        log_level = self._get_log_level(error_info.severity)
        logger.log(log_level, 
                  f"错误处理 - {error_info.code}: {error_info.message} "
                  f"(用户: {error_info.context.user_id}, 操作: {error_info.context.operation})")
    
    def _get_log_level(self, severity: ErrorSeverity) -> int:
        """根据严重程度获取日志级别"""
        level_mapping = {
            ErrorSeverity.LOW: logging.INFO,
            ErrorSeverity.MEDIUM: logging.WARNING,
            ErrorSeverity.HIGH: logging.ERROR,
            ErrorSeverity.CRITICAL: logging.CRITICAL
        }
        return level_mapping.get(severity, logging.ERROR)
    
    def get_error_statistics(self) -> Dict[str, Any]:
        """获取错误统计信息"""
        # 计算错误趋势
        recent_errors = self.error_stats["recent_errors"]
        now = time.time()
        
        # 最近1小时错误数
        errors_last_hour = len([e for e in recent_errors if now - e["timestamp"] < 3600])
        
        # 最近24小时错误数
        errors_last_day = len([e for e in recent_errors if now - e["timestamp"] < 86400])
        
        return {
            **self.error_stats,
            "error_trends": {
                "errors_last_hour": errors_last_hour,
                "errors_last_day": errors_last_day,
                "average_errors_per_hour": errors_last_day / 24
            },
            "generated_at": datetime.now().isoformat()
        }
    
    def get_error_patterns(self) -> Dict[str, Any]:
        """分析错误模式"""
        recent_errors = self.error_stats["recent_errors"]
        
        # 按用户分组的错误
        user_errors = {}
        for error in recent_errors:
            user_id = error.get("user_id")
            if user_id:
                if user_id not in user_errors:
                    user_errors[user_id] = []
                user_errors[user_id].append(error)
        
        # 按操作分组的错误
        operation_errors = {}
        for error in recent_errors:
            operation = error.get("operation", "unknown")
            if operation not in operation_errors:
                operation_errors[operation] = []
            operation_errors[operation].append(error)
        
        return {
            "user_error_patterns": {
                user_id: len(errors) 
                for user_id, errors in user_errors.items()
            },
            "operation_error_patterns": {
                operation: len(errors)
                for operation, errors in operation_errors.items()
            },
            "most_common_errors": self._get_most_common_errors(recent_errors)
        }
    
    def _get_most_common_errors(self, errors: List[Dict], limit: int = 5) -> List[Dict]:
        """获取最常见的错误"""
        error_counts = {}
        for error in errors:
            code = error["code"]
            if code not in error_counts:
                error_counts[code] = {"count": 0, "latest": error}
            error_counts[code]["count"] += 1
            if error["timestamp"] > error_counts[code]["latest"]["timestamp"]:
                error_counts[code]["latest"] = error
        
        # 按频率排序
        sorted_errors = sorted(error_counts.items(), key=lambda x: x[1]["count"], reverse=True)
        
        return [
            {
                "code": code,
                "count": data["count"],
                "latest_occurrence": data["latest"]
            }
            for code, data in sorted_errors[:limit]
        ]

# 全局错误处理器实例
_global_error_handler = None

def get_error_handler() -> ErrorHandler:
    """获取全局错误处理器实例"""
    global _global_error_handler
    if _global_error_handler is None:
        _global_error_handler = ErrorHandler()
    return _global_error_handler

# 便捷函数
def handle_exception(error: Exception, context: ErrorContext = None) -> ErrorInfo:
    """便捷的异常处理函数"""
    if context is None:
        context = ErrorContext()
    
    error_handler = get_error_handler()
    return error_handler.handle_error(error, context)

def create_error_context(user_id: int = None, request_id: str = None, 
                        operation: str = None, **kwargs) -> ErrorContext:
    """便捷的错误上下文创建函数"""
    return ErrorContext(
        user_id=user_id,
        request_id=request_id,
        operation=operation,
        **kwargs
    )