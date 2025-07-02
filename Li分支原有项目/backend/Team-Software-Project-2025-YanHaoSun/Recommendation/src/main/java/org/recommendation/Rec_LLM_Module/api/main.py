from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
import time
import sys
from datetime import datetime
from loguru import logger

from .endpoints import router
from .models import ApiResponse

# 配置Loguru结构化日志
def setup_logging():
    """配置结构化日志"""
    log_level = os.getenv("LOG_LEVEL", "INFO")
    environment = os.getenv("ENVIRONMENT", "development")
    
    # 移除默认的logger
    logger.remove()
    
    # 控制台日志格式
    console_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )
    
    # 文件日志格式（JSON结构化）
    file_format = (
        "{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {name}:{function}:{line} | {message}"
    )
    
    # 添加控制台输出
    logger.add(
        sys.stderr,
        format=console_format,
        level=log_level,
        colorize=True,
        backtrace=True,
        diagnose=True
    )
    
    # 在生产环境添加文件日志
    if environment == "production":
        logger.add(
            "/var/log/grocery-guardian/recommendation-service.log",
            format=file_format,
            level=log_level,
            rotation="100 MB",
            retention="30 days",
            compression="gz",
            serialize=True  # JSON格式
        )
    elif environment == "development":
        logger.add(
            "logs/recommendation-service.log",
            format=file_format,
            level="DEBUG",
            rotation="50 MB",
            retention="7 days"
        )

# 初始化日志
setup_logging()

# 创建FastAPI应用实例
app = FastAPI(
    title="Grocery Guardian API",
    description="智能营养推荐系统API - 基于商品扫描和小票分析的健康选择推荐服务",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# 配置CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境中应该限制具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加请求处理时间中间件
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# 全局异常处理器
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception handler caught: {exc}")
    return JSONResponse(
        status_code=500,
        content=ApiResponse(
            success=False,
            message="Internal server error",
            error={
                "code": "INTERNAL_ERROR",
                "message": str(exc),
                "details": {"path": str(request.url)}
            },
            timestamp=datetime.now().isoformat()
        ).dict()
    )

# 健康检查端点
@app.get("/health", response_model=ApiResponse)
async def health_check():
    """
    标准健康检查端点
    符合DEVELOPMENT_STANDARDS.md要求，返回JSON格式: {"status": "ok"}
    """
    try:
        # 检查数据库连接（如果配置了）
        db_status = "ok"
        try:
            # 这里可以添加数据库连接检查
            pass
        except Exception as e:
            logger.warning(f"Database health check failed: {e}")
            db_status = "warning"
        
        # 检查OpenAI API连接
        openai_status = "ok"
        openai_key = os.getenv("OPENAI_API_KEY")
        if not openai_key or openai_key == "test_key":
            openai_status = "not_configured"
        
        health_data = {
            "status": "ok",
            "version": "1.0.0",
            "environment": os.getenv("ENVIRONMENT", "development"),
            "timestamp": datetime.now().isoformat(),
            "services": {
                "database": db_status,
                "openai": openai_status
            },
            "uptime": f"{time.time() - app.state.start_time:.2f}s" if hasattr(app.state, 'start_time') else "unknown"
        }
        
        logger.info("Health check completed successfully")
        
        return ApiResponse(
            success=True,
            message="Grocery Guardian Recommendation Service is healthy",
            data=health_data,
            timestamp=datetime.now().isoformat()
        )
    
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return ApiResponse(
            success=False,
            message="Health check failed",
            error={
                "code": "HEALTH_CHECK_ERROR",
                "message": str(e)
            },
            timestamp=datetime.now().isoformat()
        )

# 根路径
@app.get("/", response_model=ApiResponse)
async def root():
    """根路径"""
    return ApiResponse(
        success=True,
        message="Welcome to Grocery Guardian API",
        data={
            "description": "智能营养推荐系统API",
            "version": "1.0.0",
            "endpoints": {
                "barcode_recommendation": "/recommendations/barcode",
                "receipt_analysis": "/recommendations/receipt",
                "health_check": "/health",
                "documentation": "/docs"
            }
        },
        timestamp=datetime.now().isoformat()
    )

# 包含路由
app.include_router(router, prefix="", tags=["recommendations"])

# 启动事件
@app.on_event("startup")
async def startup_event():
    """应用启动事件"""
    app.state.start_time = time.time()
    environment = os.getenv("ENVIRONMENT", "development")
    
    logger.info(
        "Grocery Guardian Recommendation Service starting up",
        extra={
            "service": "recommendation",
            "version": "1.0.0",
            "environment": environment,
            "port": os.getenv("PYTHON_API_PORT", "8001")
        }
    )
    
    # 检查必要的环境变量
    required_env_vars = ["DB_USERNAME", "DB_PASSWORD", "DB_NAME"]
    missing_vars = [var for var in required_env_vars if not os.getenv(var)]
    
    if missing_vars:
        logger.warning(f"Missing environment variables: {missing_vars}")
    
    # 检查OpenAI配置
    if not os.getenv("OPENAI_API_KEY"):
        logger.warning("OPENAI_API_KEY not configured - AI features may not work")
    
    logger.success("Service startup completed successfully")

# 关闭事件
@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭事件"""
    uptime = time.time() - app.state.start_time if hasattr(app.state, 'start_time') else 0
    
    logger.info(
        "Grocery Guardian Recommendation Service shutting down",
        extra={
            "service": "recommendation",
            "uptime_seconds": uptime
        }
    )
    
    # 这里可以添加清理资源的逻辑
    logger.success("Service shutdown completed")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)