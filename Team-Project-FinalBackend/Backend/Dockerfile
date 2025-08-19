# 后端Java服务Dockerfile
# 位置: Backend/Dockerfile

# 构建阶段
FROM maven:3.9.4-eclipse-temurin-17 AS build

WORKDIR /app

# 复制pom.xml文件 (父项目和子项目)
COPY pom.xml .
COPY Backend/pom.xml Backend/
COPY Allergen/pom.xml Allergen/
COPY common/pom.xml common/
COPY Ocr/pom.xml Ocr/
COPY Product/pom.xml Product/
COPY Recommendation/pom.xml Recommendation/
COPY User/pom.xml User/
COPY Loyalty/pom.xml Loyalty/

# 下载依赖（利用Docker缓存）
RUN mvn dependency:go-offline

# 复制源代码
COPY . .

# 构建项目
RUN mvn clean package -DskipTests

# 运行阶段
FROM eclipse-temurin:17-jre

WORKDIR /app

# 安装curl用于健康检查
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制jar文件
COPY --from=build /app/Backend/target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080/health || exit 1

# 启动命令
CMD ["java", "-jar", "app.jar"]