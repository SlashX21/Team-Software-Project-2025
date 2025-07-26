# Loyalty FastAPI 项目

## 📦 项目说明
本项目是基于 FastAPI 和区块链的用户忠诚度积分系统。
- 用户注册时自动发放以太币。
- 用户可以获得积分。
- 用户可以兑换积分获取优惠券。

## 🚀 启动方式

1️⃣ 安装依赖：
```
pip install -r requirements.txt
```

2️⃣ 启动本地 Hardhat 节点：
```
cd loyalty-chain
npx hardhat node
```

3️⃣ 部署智能合约：
```
npx hardhat run scripts/deploy.js --network localhost
```

4️⃣ 启动 FastAPI：
```
cd loyalty-api
uvicorn app.main:app --reload
```

访问：http://127.0.0.1:8000/docs 查看接口文档。

## 🧪 测试脚本

```
#!/bin/bash

curl -X POST http://127.0.0.1:8000/register -H "Content-Type: application/json" -d '{"user_id": "testuser"}'

curl -X POST http://127.0.0.1:8000/award -H "Content-Type: application/json" -d '{"user_id": "testuser", "amount": 100, "reason": "购物奖励"}'

curl -X POST http://127.0.0.1:8000/points -H "Content-Type: application/json" -d "{\"user_id\": \"user123\"}"

curl -X POST http://127.0.0.1:8000/redeem -H "Content-Type: application/json" -d '{"user_id": "testuser"}'
```