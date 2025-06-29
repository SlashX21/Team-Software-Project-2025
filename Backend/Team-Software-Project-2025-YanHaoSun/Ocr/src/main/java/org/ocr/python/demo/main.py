import os
from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from fastapi.requests import Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from dotenv import load_dotenv

from ocr_module import extract_text_from_image
from gpt_module import extract_products_from_text
from barcode_module import extract_barcodes_from_image

load_dotenv("ocr_config.env")
API_TOKEN = os.getenv("API_TOKEN")

class BarcodeRequest(BaseModel):
    barcode: str

app = FastAPI()
security = HTTPBearer()

app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != API_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/scan")
async def scan_receipt(
    file: UploadFile = File(...),
    credentials: HTTPAuthorizationCredentials = Depends(verify_token),
):
    image_bytes = await file.read()
    ocr_text = extract_text_from_image(image_bytes)
    products = extract_products_from_text(ocr_text)
    return {"products": products}


@app.post("/barcode")
async def scan_barcode(
    request: BarcodeRequest,
    credentials: HTTPAuthorizationCredentials = Depends(verify_token),
):
    # 接收前端识别出的条码字符串
    # 这里可以添加条码处理逻辑，比如查询商品信息等
    return {"barcode": request.barcode, "message": "Barcode received successfully"}
