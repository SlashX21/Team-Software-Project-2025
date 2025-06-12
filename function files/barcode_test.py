import os
os.environ['DYLD_LIBRARY_PATH'] = '/opt/homebrew/opt/zbar/lib'

from pyzbar.pyzbar import decode
from PIL import Image

img = Image.open("test_barcode.png")
results = decode(img)

if results:
    for r in results:
        print( r.type)
        print(r.data.decode("utf-8"))
else:
    print("nothing")
