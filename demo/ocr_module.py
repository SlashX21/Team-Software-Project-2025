import os
from dotenv import load_dotenv
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential

load_dotenv()

AZURE_ENDPOINT = os.getenv("AZURE_ENDPOINT")
AZURE_KEY = os.getenv("AZURE_KEY")

client = ImageAnalysisClient(
    endpoint=AZURE_ENDPOINT,
    credential=AzureKeyCredential(AZURE_KEY)
)

def extract_text_from_image(image_bytes: bytes) -> str:
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
