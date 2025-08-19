# Loyalty Points FastAPI Application

This is a FastAPI application that provides a REST API interface for the Loyalty Points smart contract deployed on Sepolia testnet.

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- Your `.env` file with Sepolia configuration (already set up)

### Installation

1. **Create and activate virtual environment:**
   ```bash
   python -m venv venv
   ./venv/Scripts/activate  # On Windows
   # or
   source venv/bin/activate  # On macOS/Linux
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Start the FastAPI server:**
   ```bash
   python app.py
   ```
   
       Or using uvicorn directly:
    ```bash
    uvicorn app:app --host 0.0.0.0 --port 8005 --reload
    ```

3. **Open the frontend:**
   - Open `frontend/index.html` in your web browser
   - Or serve it using a simple HTTP server:
     ```bash
     cd frontend
     python -m http.server 8080
     ```
   - Then visit `http://localhost:8080`

## 📚 API Endpoints

### Base URL: `http://localhost:8005`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API information |
| `/health` | GET | Health check |
| `/contract-info` | GET | Get contract information |
| `/award-points` | POST | Award points to a user (owner only) |
| `/check-points` | POST | Check points for a user |
| `/redeem-points` | POST | Redeem points and get barcode |

### API Documentation

Once the server is running, you can access:
- **Interactive API docs**: `http://localhost:8000/docs`
- **ReDoc documentation**: `http://localhost:8000/redoc`

## 🔧 Configuration

The application uses the same `.env` file as your Hardhat project:

```env
SEPOLIA_URL=https://sepolia.infura.io/v3/your_project_id
PRIVATE_KEY=your_private_key_here
```

**Important**: Make sure your wallet has some Sepolia ETH for gas fees.

## 📝 Usage Examples

### Award Points
```bash
 curl -X POST "http://localhost:8005/award-points" \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x1234567890123456789012345678901234567890",
    "amount": 100
  }'
```

### Check Points
```bash
 curl -X POST "http://localhost:8005/check-points" \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x1234567890123456789012345678901234567890"
  }'
```

### Redeem Points
```bash
 curl -X POST "http://localhost:8005/redeem-points" \
  -H "Content-Type: application/json" \
  -d '{
    "user_address": "0x1234567890123456789012345678901234567890"
  }'
```

## 🎯 Features

- **Full Smart Contract Integration**: All contract functions available via REST API
- **Transaction Management**: Automatic gas estimation and transaction signing
- **Event Parsing**: Extracts barcodes from blockchain events
- **Error Handling**: Comprehensive error handling and validation
- **CORS Support**: Ready for frontend integration
- **Health Monitoring**: Built-in health check endpoint
- **Interactive Documentation**: Auto-generated API docs with Swagger UI

## 🔒 Security Notes

- **Private Key**: Never expose your private key in production
- **Environment Variables**: Keep your `.env` file secure and never commit it
- **Network**: Currently configured for Sepolia testnet
- **Gas Fees**: Ensure your wallet has sufficient ETH for transactions

## 🚀 Production Deployment

For production deployment:

1. **Use environment variables** instead of `.env` file
2. **Implement proper authentication** (API keys, JWT tokens)
3. **Add rate limiting** to prevent abuse
4. **Use HTTPS** for all communications
5. **Monitor gas prices** and implement dynamic gas estimation
6. **Add logging** for transaction monitoring
7. **Implement retry logic** for failed transactions

## 🐛 Troubleshooting

### Common Issues

1. **"Private key not configured"**
   - Check your `.env` file has the correct `PRIVATE_KEY`

2. **"Invalid Ethereum address"**
   - Ensure addresses are valid Ethereum addresses (42 characters, starting with 0x)

3. **"Transaction failed"**
   - Check if your wallet has sufficient Sepolia ETH
   - Verify the contract address is correct
   - Check network connectivity

4. **"Contract error: Not owner"**
   - Only the contract owner can award points
   - Ensure you're using the correct private key

### Debug Mode

Run with debug logging:
```bash
 uvicorn app:app --host 0.0.0.0 --port 8005 --reload --log-level debug
```

## 📊 Contract Address

Your deployed contract address: `0x4009Cf4685EA85a86535f4d79F56d76D44e613C0`

You can view it on Sepolia Etherscan: https://sepolia.etherscan.io/address/0x4009Cf4685EA85a86535f4d79F56d76D44e613C0 