import os
from dotenv import load_dotenv
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential

# 加载OCR配置文件
load_dotenv("ocr_config.env")

AZURE_ENDPOINT = os.getenv("AZURE_ENDPOINT")
AZURE_KEY = os.getenv("AZURE_KEY")

# 只有在Azure配置存在时才创建客户端
client = None
if AZURE_ENDPOINT and AZURE_KEY:
    client = ImageAnalysisClient(
        endpoint=AZURE_ENDPOINT,
        credential=AzureKeyCredential(AZURE_KEY)
    )

def extract_text_from_image(image_bytes: bytes) -> str:
    if not client:
        # 如果没有Azure配置，返回模拟的OCR结果
        return "模拟OCR结果：这是一张小票图片的文本内容\n商品1: 苹果 $2.99\n商品2: 香蕉 $1.50\n总计: $4.49"
    
    result = client.analyze(
        image_data=image_bytes,
        visual_features=[VisualFeatures.READ],
        language="en"
    )
    # 拼接识别的每一行
    lines = []
    for block in result.read.blocks:
        for line in block.lines:
            lines.append(line.text)
    return "\n".join(lines)
