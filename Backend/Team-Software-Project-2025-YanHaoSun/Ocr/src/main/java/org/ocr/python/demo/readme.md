好的，以下是你需要交给 Java 后端的简洁 **使用教程**（即运行 FastAPI 服务 + 如何调用接口）：

---

## OCR + Barcode FastAPI 服务

###  1. 安装依赖

Python 3.8+。进入项目目录，运行：

```bash
pip install -r requirements.txt
```

---

###  2. 设置环境变量

创建 `.env`，填写：

```
OPENAI_API_KEY=你的OpenAI Key
API_TOKEN=自定义的API访问令牌
```

---

### 3. 启动服务

在终端运行：

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

服务默认运行在 `http://localhost:8000`

---

##  鉴权方式

所有接口都要求加上 token，格式如下：

```http
Authorization: Bearer <你的API_TOKEN>
```

---

##  接口调用方式

###  1. POST `/scan`（上传小票图片）

* **请求类型**：`multipart/form-data`
* **参数**：`file`（图片文件）

示例（cURL）：

```bash
curl -X POST http://localhost:8000/scan \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -F "file=@receipt.jpg"
```

---

###  2. POST `/barcode`（上传条码字符串）

* **请求类型**：`application/json`
* **参数**：`{ "barcode": "1234567890123" }`

示例：

```bash
curl -X POST http://localhost:8000/barcode \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"barcode": "1234567890123"}'
```

---

##  前端演示页面

浏览器访问：

```
http://localhost:8000
```

可进行扫码和上传演示。

---