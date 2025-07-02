window.addEventListener('DOMContentLoaded', () => {
  const codeReader = new ZXing.BrowserMultiFormatReader();
  const videoElement = document.getElementById('barcode-video');
  const resultDisplay = document.getElementById('barcodeResult');
  const tokenInput = document.getElementById('tokenInput');
  const startScanBtn = document.getElementById('startScanBtn');

  let isScanning = false;
  let recentBarcodes = [];
  let lastConfirmed = null;

  function isStableBarcode(newCode) {
    recentBarcodes.push(newCode);
    if (recentBarcodes.length > 5) {
      recentBarcodes.shift();
    }

    const counts = recentBarcodes.reduce((acc, code) => {
      acc[code] = (acc[code] || 0) + 1;
      return acc;
    }, {});

    for (const code in counts) {
      if (counts[code] >= 3 && code !== lastConfirmed) {
        lastConfirmed = code;
        return code;
      }
    }
    return null;
  }

  startScanBtn.addEventListener('click', () => {
    if (isScanning) return;

    codeReader
      .listVideoInputDevices()
      .then(videoInputDevices => {
        if (videoInputDevices.length === 0) {
          resultDisplay.textContent = "No camera found.";
          return;
        }

        const firstCameraId = videoInputDevices[0].deviceId;
        isScanning = true;

        codeReader.decodeFromVideoDevice(firstCameraId, videoElement, (result, err) => {
          if (result) {
            const stable = isStableBarcode(result.text);
            resultDisplay.textContent = `Scanning... ${result.text}`;

            if (!stable) return;

            const token = tokenInput.value.trim();
            if (!token) {
              alert("Please enter API token first.");
              return;
            }

            resultDisplay.textContent = "Sending request...";

            fetch('/barcode', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
              },
              body: JSON.stringify({ barcode: stable })
            })
              .then(res => res.json())
              .then(data => {
                resultDisplay.textContent = data.barcode || "No result";
              })
              .catch(err => {
                console.error(err);
                resultDisplay.textContent = "Error sending barcode";
              });

            codeReader.reset();
            isScanning = false;
          }
        });
      })
      .catch(err => {
        console.error("Camera error:", err);
        resultDisplay.textContent = "Camera error";
      });
  });

  // OCR upload section
  const analyzeBtn = document.getElementById('analyzeBtn');
  const receiptInput = document.getElementById('receiptInput');
  const ocrResultList = document.getElementById('ocrResultList');

  analyzeBtn.addEventListener('click', () => {
    const token = tokenInput.value.trim();
    if (!token) {
      alert("Please enter API token first.");
      return;
    }

    const file = receiptInput.files[0];
    if (!file) return alert('Please select a receipt image.');

    const formData = new FormData();
    formData.append('file', file);

    fetch('/scan', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    })
      .then(res => res.json())
      .then(data => {
        ocrResultList.innerHTML = '';
        if (data.products && data.products.length > 0) {
          data.products.forEach(p => {
            const li = document.createElement('li');
            li.textContent = `${p.name} x${p.quantity}`;
            ocrResultList.appendChild(li);
          });
        } else {
          ocrResultList.innerHTML = '<li>No products found.</li>';
        }
      })
      .catch(err => {
        console.error('OCR error:', err);
        ocrResultList.innerHTML = '<li>Error occurred.</li>';
      });
  });
});
