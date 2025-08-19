from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import time
from datetime import datetime

from .endpoints import router
from .models import ApiResponse

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

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
    allow_origins=["*"],  # 开发环境允许所有来源
    allow_credentials=False,  # 设为False以支持通配符origins
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
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
    """健康检查端点"""
    return ApiResponse(
        success=True,
        message="Grocery Guardian API is running",
        data={
            "status": "healthy",
            "version": "1.0.0",
            "timestamp": datetime.now().isoformat()
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
    logger.info("Grocery Guardian API starting up...")
    # 这里可以添加数据库连接初始化等启动逻辑

# 关闭事件
@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Grocery Guardian API shutting down...")
    # 这里可以添加清理资源的逻辑

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)