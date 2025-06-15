from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential

endpoint = "https://grocery-guardian.cognitiveservices.azure.com/"
key = "5z4tnEk8kh4lyZhjHqILQo5CM6KztQxDJqfflelhHUf6BwtLid7FJQQJ99BFACmepeSXJ3w3AAAFACOG1l7i"

client = ImageAnalysisClient(
    endpoint=endpoint,
    credential=AzureKeyCredential(key)
)

with open("1.jpg", "rb") as f:
    image_data = f.read()

# reads text from images
result = client.analyze(
    image_data=image_data,
    visual_features=[VisualFeatures.READ], 
    language="en" 
)

for block in result.read.blocks:
    for line in block.lines:
        print(line.text)
