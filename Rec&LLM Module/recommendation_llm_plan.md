# 推荐算法与LLM部署开发档案 - Grocery Guardian

## 🎯 模块目标

构建智能推荐算法引擎和LLM评估系统，实现基于营养目标、过敏原约束和用户偏好的个性化商品推荐，并通过OpenAI GPT生成详细的推荐分析和健康建议。

## 🧠 推荐算法架构设计

### 多层过滤管道架构
```
输入商品/用户请求
    ↓
1. 硬过滤层 (Hard Filters)
   ├── 过敏原绝对过滤
   ├── 分类约束过滤
   └── 基础可用性检查
    ↓
2. 营养优化层 (Nutrition Optimization)
   ├── 营养目标权重计算
   ├── 营养成分评分
   └── 健康指标排序
    ↓
3. 协同过滤层 (Collaborative Filtering)
   ├── 用户-商品矩阵计算
   ├── 相似用户发现
   └── 购买模式分析
    ↓
4. 个性化权重层 (Personalization)
   ├── 用户偏好应用
   ├── 时间衰减因子
   └── 多样性平衡
    ↓
输出Top-K推荐结果
```

### 核心算法组件

#### 1. 硬过滤器 (Hard Filters)
```python
class HardFilters:
    def filter_allergens(self, products: List[dict], user_allergens: List[int]) -> List[dict]:
        """绝对过敏原过滤 - 0容忍度"""
        # 查询PRODUCT_ALLERGEN表
        # 排除包含用户过敏原的所有商品
        # 处理presence_type: contains > may_contain > traces
        
    def filter_by_category(self, products: List[dict], target_category: str, 
                          strict: bool = True) -> List[dict]:
        """商品分类过滤"""
        # 条形码扫描：严格同分类约束
        # 小票分析：可跨分类推荐
        
    def filter_availability(self, products: List[dict]) -> List[dict]:
        """基础可用性检查"""
        # 检查营养数据完整性
        # 排除异常价格商品
        # 验证商品有效性
```

#### 2. 营养优化评分器 (Nutrition Optimizer)
```python
class NutritionOptimizer:
    # 营养目标权重配置
    NUTRITION_STRATEGIES = {
        'lose_weight': {
            'energy_kcal_100g': -0.4,    # 低热量优先
            'fat_100g': -0.3,            # 低脂肪
            'sugars_100g': -0.3,         # 低糖分
            'proteins_100g': 0.2,        # 适量蛋白质
            'fiber_bonus': 0.3           # 高纤维加分
        },
        'gain_muscle': {
            'proteins_100g': 0.5,        # 高蛋白质优先
            'carbohydrates_100g': 0.2,   # 适量碳水
            'energy_kcal_100g': 0.3,     # 充足热量
            'fat_100g': 0.1,             # 适量脂肪
            'bcaa_bonus': 0.4            # 支链氨基酸加分
        },
        'maintain': {
            'balance_score': 0.4,        # 营养均衡
            'variety_score': 0.3,        # 营养多样性
            'natural_bonus': 0.3         # 天然成分加分
        }
    }
    
    def calculate_nutrition_score(self, product: dict, user_goal: str) -> float:
        """计算商品营养评分"""
        
    def compare_nutrition_improvement(self, original: dict, 
                                    alternative: dict, user_goal: str) -> dict:
        """计算营养改善度"""
        # 返回具体的营养指标对比
        # 热量减少/增加量
        # 蛋白质提升量
        # 有害成分降低量
        
    def calculate_health_impact_score(self, product: dict, user_profile: dict) -> float:
        """计算健康影响评分"""
        # 考虑用户年龄、性别、活动水平
        # BMR计算和营养需求匹配
        # 特殊健康状况考虑
```

#### 3. 协同过滤算法 (Collaborative Filtering)
```python
class CollaborativeFilter:
    def __init__(self, min_interactions: int = 3, similarity_threshold: float = 0.6):
        self.min_interactions = min_interactions
        self.similarity_threshold = similarity_threshold
        
    def build_user_item_matrix(self, purchase_data: List[dict]) -> np.ndarray:
        """构建用户-商品交互矩阵"""
        # 基于PURCHASE_ITEM数据
        # 考虑quantity权重
        # 应用时间衰减因子
        
    def calculate_user_similarity(self, user_matrix: np.ndarray) -> np.ndarray:
        """计算用户相似度矩阵"""
        # 使用余弦相似度或皮尔逊相关系数
        # 处理稀疏矩阵优化
        
    def predict_user_preferences(self, target_user_id: int, 
                                candidate_products: List[str]) -> dict:
        """预测用户对候选商品的偏好度"""
        # 基于相似用户的购买行为
        # 加权平均计算偏好分数
        
    def apply_time_decay(self, interactions: List[dict], 
                        decay_factor: float = 0.95) -> List[dict]:
        """应用时间衰减因子"""
        # 近期购买权重更高
        # 指数衰减函数
```

#### 4. 内容过滤算法 (Content-Based Filtering)
```python
class ContentBasedFilter:
    def calculate_product_similarity(self, product1: dict, product2: dict) -> float:
        """计算商品内容相似度"""
        # 营养成分向量化
        # 成分文本相似度（TF-IDF）
        # 品牌和分类权重
        
    def build_nutrition_features(self, product: dict) -> np.ndarray:
        """构建营养特征向量"""
        # 标准化营养成分
        # 类别one-hot编码
        # 过敏原特征编码
        
    def recommend_similar_products(self, target_product: dict, 
                                  candidates: List[dict], top_k: int = 10) -> List[dict]:
        """基于内容相似度推荐"""
        # 计算目标商品与候选商品的相似度
        # 结合营养优化评分
        # 返回综合排序结果
```

## 🤖 LLM评估系统设计（Spring Boot兼容）

### OpenAI API集成架构（生产级设计）
```python
import asyncio
from typing import Dict, List, Optional
from dataclasses import dataclass
from enum import Enum

class LLMProvider(Enum):
    OPENAI = "openai"
    AZURE_OPENAI = "azure_openai"

@dataclass
class LLMConfig:
    """LLM配置类，支持多环境部署"""
    provider: LLMProvider
    api_key: str
    model: str = "gpt-3.5-turbo"
    max_tokens: int = 800
    temperature: float = 0.7
    timeout: int = 30
    retry_attempts: int = 3
    enable_fallback: bool = True
    cost_tracking: bool = True

class OpenAIClient:
    """OpenAI客户端，支持Spring Boot风格的错误处理"""
    
    def __init__(self, config: LLMConfig):
        self.config = config
        self.client = self._initialize_client()
        self.token_usage_stats = {"total_tokens": 0, "total_cost": 0.0}
        
    def _initialize_client(self):
        """初始化OpenAI客户端"""
        if self.config.provider == LLMProvider.OPENAI:
            from openai import OpenAI
            return OpenAI(api_key=self.config.api_key)
        else:
            # 预留Azure OpenAI支持
            pass
    
    async def generate_completion(self, prompt: str, 
                                config_override: Optional[Dict] = None) -> Dict:
        """异步生成AI回复，包含Spring Boot风格的错误处理"""
        
        # 合并配置
        effective_config = {
            "model": self.config.model,
            "max_tokens": self.config.max_tokens,
            "temperature": self.config.temperature,
            **(config_override or {})
        }
        
        # 重试机制
        for attempt in range(self.config.retry_attempts):
            try:
                response = await self._call_openai_api(prompt, effective_config)
                
                # 更新使用统计
                if self.config.cost_tracking:
                    self._update_usage_stats(response)
                
                return {
                    "success": True,
                    "content": response.choices[0].message.content,
                    "usage": response.usage.model_dump() if response.usage else {},
                    "model": response.model,
                    "attempt": attempt + 1
                }
                
            except Exception as e:
                if attempt == self.config.retry_attempts - 1:
                    # 最后一次尝试失败，返回Spring Boot风格的错误响应
                    return {
                        "success": False,
                        "error": {
                            "code": "LLM_API_ERROR",
                            "message": str(e),
                            "type": type(e).__name__,
                            "attempts": attempt + 1
                        },
                        "fallback_content": self._get_fallback_response() if self.config.enable_fallback else None
                    }
                
                # 等待后重试
                await asyncio.sleep(2 ** attempt)  # 指数退避
    
    def _get_fallback_response(self) -> str:
        """获取降级响应"""
        return "抱歉，AI分析服务暂时不可用。请稍后重试或查看基础推荐信息。"
    
    def estimate_token_cost(self, prompt: str, response: str = "") -> Dict:
        """估算API调用成本（支持成本控制）"""
        # GPT-3.5-turbo pricing (估算)
        input_tokens = len(prompt.split()) * 1.3  # 粗略估算
        output_tokens = len(response.split()) * 1.3
        
        # 价格（美元/1000 tokens）
        input_cost = (input_tokens / 1000) * 0.0015
        output_cost = (output_tokens / 1000) * 0.002
        
        return {
            "input_tokens": int(input_tokens),
            "output_tokens": int(output_tokens),
            "estimated_cost_usd": input_cost + output_cost,
            "model": self.config.model
        }
```

### Prompt工程策略

#### 1. 条形码扫描Prompt模板
```python
BARCODE_SCAN_PROMPT_TEMPLATE = """
你是一位专业的营养师和食品安全专家。用户扫描了一个商品，请为其提供个性化的替代品推荐分析。

用户画像：
- 年龄：{age}岁，性别：{gender}
- 身高：{height_cm}cm，体重：{weight_kg}kg
- 营养目标：{nutrition_goal_cn}
- 活动水平：{activity_level_cn}
- 过敏原：{allergens_list}
- 每日营养目标：热量{daily_calories}kcal，蛋白质{daily_protein}g

扫描的原商品：
- 商品名：{original_product_name}
- 品牌：{original_product_brand}
- 营养成分（每100g）：热量{original_calories}kcal，蛋白质{original_protein}g，脂肪{original_fat}g，碳水{original_carbs}g，糖分{original_sugar}g

推荐的替代品：
{recommended_products_details}

营养对比分析：
{nutrition_comparison}

请提供一份详细的个性化分析，包括：
1. 为什么推荐这些替代品（结合用户的营养目标和健康状况）
2. 具体的营养优势分析（量化对比数据）
3. 对用户健康目标的潜在影响
4. 具体的使用建议和注意事项

要求：
- 语言亲切专业，避免过于技术性的术语
- 提供具体的数字对比，突出改善程度
- 给出实用的行动建议
- 字数控制在300-500字
"""
```

#### 2. 小票分析Prompt模板
```python
RECEIPT_ANALYSIS_PROMPT_TEMPLATE = """
你是一位资深的营养咨询师。用户上传了一张购物小票，请对其购买习惯进行全面分析并提供改进建议。

用户画像：
- 基本信息：{age}岁{gender}，{height_cm}cm，{weight_kg}kg
- 营养目标：{nutrition_goal_cn}
- 已知过敏原：{allergens_list}
- 每日营养目标：{daily_nutrition_targets}

本次购买清单：
{purchased_items_analysis}

整体营养分析：
- 总热量估算：{total_estimated_calories}kcal
- 总蛋白质：{total_protein}g
- 总脂肪：{total_fat}g
- 总碳水：{total_carbs}g
- 营养目标匹配度：{goal_match_percentage}%

单品改进建议：
{item_replacement_suggestions}

请提供一份综合的购买习惯分析和改进建议，包括：
1. 整体购买模式评估（是否符合营养目标）
2. 营养结构分析（蛋白质、碳水、脂肪比例）
3. 具体的商品替换建议和理由
4. 长期饮食规划建议
5. 下次购物的重点关注事项

要求：
- 分析客观具体，建议实用可行
- 突出与用户目标的相关性
- 提供具体的改进方向和量化指标
- 语言友好鼓励，避免批评性语言
- 字数控制在400-600字
"""
```

#### 3. Prompt优化策略
```python
class PromptOptimizer:
    def personalize_language_style(self, user_profile: dict) -> dict:
        """根据用户特征调整语言风格"""
        # 年龄群体：年轻用户更活泼，中年用户更专业
        # 教育背景：调整专业术语使用程度
        # 健康意识：调整建议的激进程度
        
    def optimize_prompt_length(self, prompt: str, target_tokens: int = 1000) -> str:
        """优化Prompt长度，平衡信息量和成本"""
        
    def add_few_shot_examples(self, prompt_type: str) -> str:
        """添加少样本学习示例"""
        # 高质量的推荐分析示例
        # 提高输出一致性和质量
```

### LLM响应处理系统（Spring Boot风格）
```python
from pydantic import BaseModel, Field
from typing import Dict, List, Optional
import json
import re
from datetime import datetime

class LLMAnalysisResult(BaseModel):
    """LLM分析结果，与Java DTO兼容"""
    summary: str = Field(..., description="个性化推荐摘要")
    nutritionAnalysis: str = Field(..., alias="nutrition_analysis", description="详细营养分析")
    healthImpact: str = Field(..., alias="health_impact", description="健康影响评估")
    actionSuggestions: List[str] = Field(..., alias="action_suggestions", description="行动建议列表")
    confidenceScore: float = Field(..., alias="confidence_score", description="分析置信度")
    generatedAt: str = Field(default_factory=lambda: datetime.now().isoformat(), alias="generated_at")
    
    class Config:
        allow_population_by_field_name = True

class LLMResponseProcessor:
    """LLM响应处理器，支持结构化输出和错误处理"""
    
    def __init__(self):
        self.quality_keywords = {
            "high_quality": ["具体数据", "营养成分", "健康建议", "科学依据"],
            "medium_quality": ["推荐", "建议", "改善", "优化"],
            "low_quality": ["可能", "或许", "大概", "一般来说"]
        }
    
    def parse_recommendation_analysis(self, llm_response: str, 
                                    context: Dict) -> LLMAnalysisResult:
        """解析LLM推荐分析响应，返回结构化结果"""
        
        if not llm_response or llm_response.strip() == "":
            return self._create_fallback_analysis(context)
        
        try:
            # 尝试提取结构化信息
            sections = self._extract_analysis_sections(llm_response)
            action_suggestions = self._extract_action_suggestions(llm_response)
            confidence_score = self._calculate_confidence_score(llm_response)
            
            return LLMAnalysisResult(
                summary=sections.get("summary", ""),
                nutrition_analysis=sections.get("nutrition_analysis", ""),
                health_impact=sections.get("health_impact", ""),
                action_suggestions=action_suggestions,
                confidence_score=confidence_score
            )
            
        except Exception as e:
            # 错误处理：返回基础分析结果
            return self._create_error_recovery_analysis(llm_response, str(e))
    
    def _extract_analysis_sections(self, response: str) -> Dict[str, str]:
        """提取分析的各个部分"""
        sections = {
            "summary": "",
            "nutrition_analysis": "",
            "health_impact": ""
        }
        
        # 使用正则表达式提取结构化内容
        patterns = {
            "summary": r"(?:总结|摘要|概述)[：:](.*?)(?=\n|$)",
            "nutrition_analysis": r"(?:营养分析|营养对比|营养优势)[：:](.*?)(?=\n\n|\n(?:[1-9]|总结|建议))",
            "health_impact": r"(?:健康影响|健康效果|健康建议)[：:](.*?)(?=\n\n|\n(?:[1-9]|总结|建议))"
        }
        
        for key, pattern in patterns.items():
            match = re.search(pattern, response, re.DOTALL)
            if match:
                sections[key] = match.group(1).strip()
        
        # 如果没有找到结构化内容，使用段落分割
        if not any(sections.values()):
            paragraphs = [p.strip() for p in response.split('\n\n') if p.strip()]
            if len(paragraphs) >= 3:
                sections["summary"] = paragraphs[0]
                sections["nutrition_analysis"] = paragraphs[1]
                sections["health_impact"] = paragraphs[2]
            else:
                sections["summary"] = response[:200] + "..." if len(response) > 200 else response
        
        return sections
    
    def _extract_action_suggestions(self, response: str) -> List[str]:
        """提取行动建议"""
        suggestions = []
        
        # 查找编号列表
        numbered_pattern = r"^\d+\.\s*(.+)$"
        bullet_pattern = r"^[•·-]\s*(.+)$"
        
        lines = response.split('\n')
        for line in lines:
            line = line.strip()
            
            # 检查编号列表
            match = re.match(numbered_pattern, line)
            if match:
                suggestions.append(match.group(1).strip())
                continue
            
            # 检查项目符号列表
            match = re.match(bullet_pattern, line)
            if match:
                suggestions.append(match.group(1).strip())
        
        # 如果没有找到列表，尝试提取包含建议关键词的句子
        if not suggestions:
            suggestion_keywords = ["建议", "推荐", "应该", "可以考虑", "尝试"]
            sentences = re.split(r'[。！？]', response)
            
            for sentence in sentences:
                sentence = sentence.strip()
                if any(keyword in sentence for keyword in suggestion_keywords):
                    if len(sentence) > 10 and len(sentence) < 100:
                        suggestions.append(sentence)
        
        return suggestions[:5]  # 最多返回5个建议
    
    def _calculate_confidence_score(self, response: str) -> float:
        """计算分析置信度"""
        score = 0.5  # 基础分数
        
        # 包含具体数据的加分
        if re.search(r'\d+\s*[gG克]', response) or re.search(r'\d+\s*[kcal|卡路里]', response):
            score += 0.2
        
        # 包含专业术语的加分
        professional_terms = ["蛋白质", "碳水化合物", "维生素", "矿物质", "膳食纤维"]
        professional_count = sum(1 for term in professional_terms if term in response)
        score += min(professional_count * 0.1, 0.3)
        
        # 包含比较分析的加分
        if "相比" in response or "对比" in response or "比较" in response:
            score += 0.1
        
        # 响应长度适中的加分
        response_length = len(response)
        if 200 <= response_length <= 800:
            score += 0.1
        elif response_length < 100 or response_length > 1200:
            score -= 0.1
        
        return max(0.1, min(1.0, score))  # 限制在0.1-1.0之间
    
    def _create_fallback_analysis(self, context: Dict) -> LLMAnalysisResult:
        """创建降级分析结果"""
        return LLMAnalysisResult(
            summary="基于营养数据的基础推荐分析",
            nutrition_analysis="推荐商品在营养成分上有所改善，请参考具体数值对比。",
            health_impact="建议的替代品可能对您的健康目标有积极影响。",
            action_suggestions=["查看推荐商品的详细营养信息", "咨询营养师获取专业建议"],
            confidence_score=0.3
        )
    
    def _create_error_recovery_analysis(self, original_response: str, error: str) -> LLMAnalysisResult:
        """创建错误恢复分析结果"""
        return LLMAnalysisResult(
            summary="AI分析处理中遇到问题，提供基础推荐信息",
            nutrition_analysis=original_response[:200] + "..." if len(original_response) > 200 else original_response,
            health_impact="请参考推荐商品的营养数据进行判断。",
            action_suggestions=["查看推荐商品详情", "稍后重试获取完整分析"],
            confidence_score=0.2
        )
    
    def validate_response_quality(self, analysis: LLMAnalysisResult) -> Dict:
        """验证LLM响应质量"""
        quality_metrics = {
            "completeness": 0.0,
            "specificity": 0.0,
            "actionability": 0.0,
            "overall_quality": "low"
        }
        
        # 完整性检查
        required_fields = [analysis.summary, analysis.nutritionAnalysis, analysis.healthImpact]
        non_empty_fields = sum(1 for field in required_fields if field and len(field.strip()) > 10)
        quality_metrics["completeness"] = non_empty_fields / len(required_fields)
        
        # 具体性检查（包含数字和具体建议）
        all_content = f"{analysis.summary} {analysis.nutritionAnalysis} {analysis.healthImpact}"
        specific_indicators = len(re.findall(r'\d+', all_content)) + len(analysis.actionSuggestions)
        quality_metrics["specificity"] = min(specific_indicators / 10, 1.0)
        
        # 可操作性检查
        quality_metrics["actionability"] = min(len(analysis.actionSuggestions) / 3, 1.0)
        
        # 综合质量评估
        overall_score = (quality_metrics["completeness"] + 
                        quality_metrics["specificity"] + 
                        quality_metrics["actionability"]) / 3
        
        if overall_score >= 0.8:
            quality_metrics["overall_quality"] = "high"
        elif overall_score >= 0.5:
            quality_metrics["overall_quality"] = "medium"
        else:
            quality_metrics["overall_quality"] = "low"
        
        return quality_metrics
    
    def apply_safety_filters(self, analysis: LLMAnalysisResult) -> LLMAnalysisResult:
        """应用安全过滤器，确保医疗免责声明"""
        
        # 检查是否包含医疗声明
        medical_keywords = ["治疗", "诊断", "疾病", "药物", "医生"]
        all_content = f"{analysis.summary} {analysis.nutritionAnalysis} {analysis.healthImpact}"
        
        if any(keyword in all_content for keyword in medical_keywords):
            # 添加免责声明
            disclaimer = "注意：以上建议仅供参考，不能替代专业医疗建议。如有健康问题，请咨询医生。"
            analysis.healthImpact = f"{analysis.healthImpact}\n\n{disclaimer}"
        
        return analysis
```

## ⚡ 推荐引擎主控制器

### 统一推荐接口
```python
class RecommendationEngine:
    def __init__(self, db_manager: DatabaseManager, llm_client: OpenAIClient):
        self.db = db_manager
        self.llm = llm_client
        self.hard_filters = HardFilters()
        self.nutrition_optimizer = NutritionOptimizer()
        self.collaborative_filter = CollaborativeFilter()
        self.content_filter = ContentBasedFilter()
        
    async def recommend_alternatives(self, request: BarcodeRecommendationRequest) -> RecommendationResponse:
        """条形码扫描推荐主流程"""
        # 1. 获取原商品和用户信息
        original_product = self.db.get_product_by_barcode(request.barcode)
        user_profile = self.db.get_user_profile(request.user_id)
        user_allergens = self.db.get_user_allergens(request.user_id)
        
        # 2. 执行多层过滤
        candidates = self.db.get_products_by_category(original_product['category'])
        
        # 硬过滤
        safe_products = self.hard_filters.filter_allergens(candidates, user_allergens)
        safe_products = self.hard_filters.filter_by_category(safe_products, 
                                                           original_product['category'])
        
        # 营养优化
        scored_products = []
        for product in safe_products:
            nutrition_score = self.nutrition_optimizer.calculate_nutrition_score(
                product, user_profile['nutrition_goal'])
            health_score = self.nutrition_optimizer.calculate_health_impact_score(
                product, user_profile)
            scored_products.append((product, nutrition_score + health_score))
        
        # 协同过滤
        collaborative_scores = self.collaborative_filter.predict_user_preferences(
            request.user_id, [p[0]['barcode'] for p in scored_products])
        
        # 综合评分和排序
        final_recommendations = self._combine_scores_and_rank(
            scored_products, collaborative_scores, top_k=5)
        
        # 3. LLM分析生成
        llm_analysis = await self._generate_llm_analysis(
            original_product, final_recommendations, user_profile)
        
        # 4. 构建响应
        return self._build_recommendation_response(
            original_product, final_recommendations, llm_analysis)
    
    async def analyze_receipt_recommendations(self, request: ReceiptRecommendationRequest) -> ReceiptAnalysisResponse:
        """小票分析推荐主流程"""
        # 1. 批量获取购买商品信息
        purchased_products = []
        for item in request.purchased_items:
            product = self.db.get_product_by_barcode(item['barcode'])
            if product:
                purchased_products.append({
                    'product': product,
                    'quantity': item['quantity'],
                    'unit_price': item['unit_price']
                })
        
        # 2. 逐商品推荐分析
        item_recommendations = []
        for item in purchased_products:
            alternatives = await self.recommend_alternatives(
                BarcodeRecommendationRequest(
                    barcode=item['product']['barcode'],
                    user_id=request.user_id
                ))
            item_recommendations.append({
                'original_item': item,
                'alternatives': alternatives.recommendations[:3]  # 取前3个
            })
        
        # 3. 整体营养分析
        overall_nutrition = self._analyze_overall_nutrition(
            purchased_products, self.db.get_user_profile(request.user_id))
        
        # 4. LLM综合分析
        receipt_insights = await self._generate_receipt_insights(
            purchased_products, item_recommendations, overall_nutrition)
        
        return self._build_receipt_analysis_response(
            item_recommendations, overall_nutrition, receipt_insights)
```

### 性能优化策略
```python
class PerformanceOptimizer:
    def __init__(self):
        self.cache = {}  # 简单内存缓存
        self.similarity_matrix_cache = None
        
    def cache_frequent_queries(self, query_key: str, result: any, ttl: int = 1800):
        """缓存频繁查询结果"""
        # 商品信息缓存30分钟
        # 用户偏好缓存1小时
        # 推荐结果缓存15分钟
        
    def precompute_similarity_matrices(self):
        """预计算商品相似度矩阵"""
        # 启动时计算常用商品间的相似度
        # 减少实时计算开销
        
    def batch_nutrition_scoring(self, products: List[dict], user_goal: str) -> List[float]:
        """批量营养评分计算"""
        # 向量化计算提高效率
        # 避免重复数据库查询
        
    def async_llm_calling(self, prompts: List[str]) -> List[str]:
        """异步批量LLM调用"""
        # 并发处理多个LLM请求
        # 实现请求去重和缓存
```

## 📊 算法评估指标

### 推荐质量指标
```python
class RecommendationEvaluator:
    def calculate_nutrition_improvement_rate(self, original: dict, 
                                           recommended: List[dict]) -> float:
        """计算营养改善率"""
        # 推荐商品相比原商品的营养指标改善程度
        
    def measure_allergen_safety_rate(self, recommendations: List[dict], 
                                   user_allergens: List[int]) -> float:
        """测量过敏原安全率"""
        # 必须达到100%安全率
        
    def evaluate_diversity_score(self, recommendations: List[dict]) -> float:
        """评估推荐多样性"""
        # 避免推荐过于相似的商品
        # 品牌、价格、营养成分的多样性
        
    def calculate_user_goal_alignment(self, recommendations: List[dict], 
                                    user_goal: str) -> float:
        """计算与用户目标的匹配度"""
        # 减脂用户：低热量商品比例
        # 增肌用户：高蛋白商品比例
        # 维持用户：营养均衡程度
```

### LLM质量评估
```python
class LLMQualityEvaluator:
    def evaluate_analysis_accuracy(self, llm_response: str, 
                                 nutrition_facts: dict) -> float:
        """评估分析准确性"""
        # 检查营养数据引用的准确性
        # 验证计算结果的正确性
        
    def measure_personalization_degree(self, response: str, 
                                     user_profile: dict) -> float:
        """测量个性化程度"""
        # 是否充分考虑用户特征
        # 建议的针对性强度
        
    def assess_actionability_score(self, response: str) -> float:
        """评估建议的可操作性"""
        # 建议是否具体可行
        # 是否提供了明确的行动步骤
```

## 🔧 实施步骤清单

### Phase 1: 核心推荐算法开发
- [ ] 实现硬过滤器（过敏原、分类、可用性）
- [ ] 开发营养优化评分算法
- [ ] 构建商品相似度计算方法
- [ ] 实现基础的内容过滤推荐

### Phase 2: 协同过滤系统
- [ ] 设计用户-商品交互矩阵构建
- [ ] 实现用户相似度计算算法
- [ ] 开发偏好预测和评分机制
- [ ] 集成时间衰减和权重调整

### Phase 3: LLM集成开发
- [ ] 配置OpenAI API客户端
- [ ] 设计和优化Prompt模板
- [ ] 实现异步LLM调用机制
- [ ] 开发响应解析和验证系统

### Phase 4: 推荐引擎整合
- [ ] 构建统一的推荐控制器
- [ ] 实现多算法评分融合策略
- [ ] 开发条形码和小票扫描流程
- [ ] 集成LLM分析生成功能

### Phase 5: 性能优化
- [ ] 实现结果缓存机制
- [ ] 优化数据库查询性能
- [ ] 预计算相似度矩阵
- [ ] 实现异步和并发处理

### Phase 6: 质量保证和测试
- [ ] 开发推荐质量评估指标
- [ ] 实现LLM响应质量验证
- [ ] 创建A/B测试框架
- [ ] 建立监控和日志系统

## 🎯 性能和质量目标

### 性能指标
- **推荐响应时间**: <2秒（端到端）
- **LLM调用成功率**: >99%
- **数据库查询优化**: 单次查询<100ms
- **系统并发能力**: 支持10个同时请求

### 质量指标
- **过敏原安全率**: 100%（零容忍）
- **营养改善率**: >80%的推荐商品营养指标优于原商品
- **用户目标匹配度**: >85%
- **推荐多样性**: 品牌和类型覆盖度>70%

### 成本控制
- **LLM Token优化**: 单次推荐平均消耗<800 tokens
- **API调用频率**: 合理的缓存策略减少重复调用
- **资源使用**: 内存占用<500MB，CPU使用<50%