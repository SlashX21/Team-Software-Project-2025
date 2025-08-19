from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from web3 import Web3
from web3.exceptions import ContractLogicError
import os
from dotenv import load_dotenv
import json

# Load environment variables
load_dotenv()



app = FastAPI(
    title="Loyalty Points API",
    description="API for managing loyalty points using user IDs on Ethereum blockchain",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Web3 setup
SEPOLIA_URL = os.getenv("SEPOLIA_URL")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ADDRESS = "0x92812CdA22aF3485E33e0a589fB7960c24e1a34c"  # Updated contract with user IDs

# Nonce management for concurrent transactions
import threading
nonce_lock = threading.Lock()
current_nonce = None

# Contract ABI (updated for user IDs)
CONTRACT_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": True,
                "internalType": "string",
                "name": "userId",
                "type": "string"
            },
            {
                "indexed": False,
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "PointsAwarded",
        "type": "event"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": True,
                "internalType": "string",
                "name": "userId",
                "type": "string"
            },
            {
                "indexed": False,
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "indexed": False,
                "internalType": "string",
                "name": "barcode",
                "type": "string"
            }
        ],
        "name": "PointsRedeemed",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "userId",
                "type": "string"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "awardPoints",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "userId",
                "type": "string"
            }
        ],
        "name": "checkPoints",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "userId",
                "type": "string"
            }
        ],
        "name": "redeemPoints",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "userId",
                "type": "string"
            }
        ],
        "name": "userExists",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(SEPOLIA_URL))
contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=CONTRACT_ABI)

# Get account from private key
account = w3.eth.account.from_key(PRIVATE_KEY)
print(f"Account address: {account.address}")

# Get contract owner
owner = contract.functions.owner().call()
print(f"Contract owner: {owner}")

# Pydantic models
class AwardPointsRequest(BaseModel):
    user_id: str
    amount: int

class CheckPointsRequest(BaseModel):
    user_id: str

class RedeemPointsRequest(BaseModel):
    user_id: str

class TransactionResponse(BaseModel):
    success: bool
    transaction_hash: str
    message: str

class PointsResponse(BaseModel):
    user_id: str
    points: int

class BarcodeResponse(BaseModel):
    user_id: str
    barcode: str
    points_redeemed: int
    transaction_hash: str

class UserExistsResponse(BaseModel):
    user_id: str
    exists: bool

# Helper function to get account from private key
def get_account():
    if not PRIVATE_KEY:
        raise HTTPException(status_code=500, detail="Private key not configured")
    return w3.eth.account.from_key(PRIVATE_KEY)

# Helper function to send transaction
def send_transaction(transaction):
    account = get_account()
    
    # Create a new transaction dict with all required fields
    tx_dict = {
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address),
        'gas': 200000,
        'gasPrice': w3.eth.gas_price,
        'to': transaction.get('to'),
        'value': transaction.get('value', 0),
        'data': transaction.get('data')
    }
    
    signed_txn = w3.eth.account.sign_transaction(tx_dict, PRIVATE_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    return w3.to_hex(tx_hash)

def get_next_nonce():
    """Get the next nonce safely for concurrent transactions"""
    global current_nonce
    with nonce_lock:
        if current_nonce is None:
            current_nonce = w3.eth.get_transaction_count(account.address)
        else:
            current_nonce += 1
        return current_nonce

# Helper function to validate user ID
def validate_user_id(user_id: str):
    if not user_id or len(user_id.strip()) == 0:
        raise HTTPException(status_code=400, detail="User ID cannot be empty")
    if len(user_id) > 50:  # Reasonable limit for user ID length
        raise HTTPException(status_code=400, detail="User ID too long (max 50 characters)")
    return user_id.strip()

@app.get("/")
async def root():
    return {
        "message": "Loyalty Points API (User ID Based)",
        "contract_address": CONTRACT_ADDRESS,
        "network": "Sepolia",
        "version": "2.0.0"
    }

@app.get("/health")
async def health_check():
    try:
        # Check if we can connect to the blockchain
        latest_block = w3.eth.block_number
        return {
            "status": "healthy",
            "network": "Sepolia",
            "latest_block": latest_block,
            "contract_address": CONTRACT_ADDRESS,
            "version": "2.0.0"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

@app.post("/award-points", response_model=TransactionResponse)
async def award_points(request: AwardPointsRequest):
    try:
        # Validate user ID
        user_id = validate_user_id(request.user_id)
        
        # Validate amount
        if request.amount <= 0:
            raise HTTPException(status_code=400, detail="Amount must be greater than 0")
        
        # Build transaction
        transaction = contract.functions.awardPoints(user_id, request.amount).build_transaction({
            'from': account.address,
            'nonce': get_next_nonce(),
            'gas': 200000,
            'gasPrice': w3.eth.gas_price
        })

        # Sign transaction
        signed_txn = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY)
        
        # Send transaction
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        tx_hash_hex = w3.to_hex(tx_hash)
        
        # Wait for transaction to be mined
        print(f"Waiting for transaction {tx_hash_hex} to be mined...")
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash_hex)
        print(f"Transaction mined in block {tx_receipt.blockNumber}")
        
        # Check if transaction was successful
        if tx_receipt.status == 0:
            raise HTTPException(status_code=500, detail="Transaction failed on blockchain")
        
        # Verify points were actually awarded by checking the contract state
        actual_points = contract.functions.checkPoints(user_id).call()
        print(f"Points after awarding: {actual_points}")
        
        return TransactionResponse(
            success=True,
            transaction_hash=tx_hash_hex,
            message=f"Awarded {request.amount} points to user {user_id}. Actual points: {actual_points}"
        )
        
    except ContractLogicError as e:
        raise HTTPException(status_code=400, detail=f"Contract error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transaction failed: {str(e)}")

@app.post("/check-points", response_model=PointsResponse)
async def check_points(request: CheckPointsRequest):
    try:
        # Validate user ID
        user_id = validate_user_id(request.user_id)
        
        # Call contract function
        points = contract.functions.checkPoints(user_id).call()
        print(f"Checking points for user {user_id}: {points}")
        
        return PointsResponse(
            user_id=user_id,
            points=points
        )
        
    except Exception as e:
        print(f"Error checking points: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to check points: {str(e)}")

@app.post("/redeem-points", response_model=BarcodeResponse)
async def redeem_points(request: RedeemPointsRequest):
    try:
        # Validate user ID
        user_id = validate_user_id(request.user_id)
        
        # Check current points
        current_points = contract.functions.checkPoints(user_id).call()
        if current_points == 0:
            raise HTTPException(status_code=400, detail="No points to redeem")
        
        # Build transaction
        transaction = contract.functions.redeemPoints(user_id).build_transaction({
            'from': account.address,
            'nonce': get_next_nonce(),
            'gas': 200000,
            'gasPrice': w3.eth.gas_price
        })

        # Sign transaction
        signed_txn = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY)
        
        # Send transaction
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        tx_hash_hex = w3.to_hex(tx_hash)
        
        # Wait for transaction to be mined
        print(f"Waiting for redeem transaction {tx_hash_hex} to be mined...")
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash_hex)
        print(f"Redeem transaction mined in block {tx_receipt.blockNumber}")
        
        # Check if transaction was successful
        if tx_receipt.status == 0:
            raise HTTPException(status_code=500, detail="Redeem transaction failed on blockchain")
        
        # Find the PointsRedeemed event
        barcode = ""
        print(f"Looking for PointsRedeemed event in {len(tx_receipt.logs)} logs...")
        
        for i, log in enumerate(tx_receipt.logs):
            try:
                print(f"Processing log {i}: {log}")
                decoded_log = contract.events.PointsRedeemed().process_log(log)
                print(f"Decoded log: {decoded_log}")
                if decoded_log['args']['userId'] == user_id:
                    barcode = decoded_log['args']['barcode']
                    print(f"Found barcode: {barcode}")
                    break
            except Exception as e:
                print(f"Error processing log {i}: {e}")
                continue
        
        # If we couldn't get barcode from event, generate it manually
        if not barcode:
            print("Could not extract barcode from event, generating manually...")
            barcode = f"BAR-{user_id}-{current_points}"
            print(f"Generated barcode: {barcode}")
        
        return BarcodeResponse(
            user_id=user_id,
            barcode=barcode,
            points_redeemed=current_points,
            transaction_hash=tx_hash_hex
        )
        
    except ContractLogicError as e:
        raise HTTPException(status_code=400, detail=f"Contract error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transaction failed: {str(e)}")

@app.post("/user-exists", response_model=UserExistsResponse)
async def check_user_exists(request: CheckPointsRequest):
    try:
        # Validate user ID
        user_id = validate_user_id(request.user_id)
        
        # Call contract function
        exists = contract.functions.userExists(user_id).call()
        
        return UserExistsResponse(
            user_id=user_id,
            exists=exists
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check user existence: {str(e)}")

@app.get("/contract-info")
async def get_contract_info():
    try:
        owner = contract.functions.owner().call()
        return {
            "contract_address": CONTRACT_ADDRESS,
            "owner": owner,
            "network": "Sepolia",
            "block_number": w3.eth.block_number,
            "version": "2.0.0"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get contract info: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8005) 