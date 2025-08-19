from web3 import Web3
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Web3 setup
SEPOLIA_URL = os.getenv("SEPOLIA_URL")
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ADDRESS = "0x92812CdA22aF3485E33e0a589fB7960c24e1a34c"

# Contract ABI (simplified)
CONTRACT_ABI = [
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

# Check if account is owner
if account.address.lower() == owner.lower():
    print("✅ Account IS the owner!")
    
    # Try to award points
    try:
        # Build transaction
        transaction = contract.functions.awardPoints("1001", 100).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 200000,
            'gasPrice': w3.eth.gas_price
        })
        
        # Sign transaction
        signed_txn = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY)
        
        # Send transaction
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        print(f"✅ Transaction sent! Hash: {w3.to_hex(tx_hash)}")
        
    except Exception as e:
        print(f"❌ Error awarding points: {e}")
        import traceback
        traceback.print_exc()
else:
    print("❌ Account is NOT the owner")
    print(f"Account: {account.address}")
    print(f"Owner: {owner}") 