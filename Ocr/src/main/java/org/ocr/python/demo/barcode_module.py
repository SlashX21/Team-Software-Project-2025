import io
import os
os.environ['DYLD_LIBRARY_PATH'] = '/opt/homebrew/opt/zbar/lib'
from PIL import Image
from pyzbar.pyzbar import decode
from fastapi import UploadFile


def extract_barcodes_from_image(image_bytes: bytes) -> list:
    image = Image.open(io.BytesIO(image_bytes))
    decoded_objects = decode(image)
    barcodes = [obj.data.decode("utf-8") for obj in decoded_objects]
    return barcodes