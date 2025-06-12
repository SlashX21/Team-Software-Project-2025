import os
os.environ['DYLD_LIBRARY_PATH'] = '/opt/homebrew/opt/zbar/lib'
import cv2
from pyzbar.pyzbar import decode
import webbrowser
import time
import collections

cap = cv2.VideoCapture(0)

#
recent_barcodes = collections.deque(maxlen=5)
last_confirmed = None

def is_stable_barcode(decoded_value):
    recent_barcodes.append(decoded_value)
    return recent_barcodes.count(decoded_value) >= 3

while True:
    success, frame = cap.read()
    if not success:
        break

    barcodes = decode(frame)

    for barcode in barcodes:
        barcode_data = barcode.data.decode("utf-8")

        if barcode_data != last_confirmed and is_stable_barcode(barcode_data):
            webbrowser.open(f"https://world.openfoodfacts.org/product/{barcode_data}")
            last_confirmed = barcode_data
            time.sleep(2)

    cv2.imshow("Barcode Scanner", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
