const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const contractAddress = "0x92812CdA22aF3485E33e0a589fB7960c24e1a34c";
  
  // Get the private key from .env
  const privateKey = process.env.PRIVATE_KEY;
  console.log("Private key from .env:", privateKey ? "✅ Found" : "❌ Not found");
  
  if (privateKey) {
    // Create account from private key
    const account = new ethers.Wallet(privateKey);
    console.log("Account from private key:", account.address);
  }
  
  // Get the contract factory
  const Loyalty = await ethers.getContractFactory("Loyalty");
  
  // Attach to the deployed contract
  const contract = Loyalty.attach(contractAddress);
  
  // Get the owner
  const owner = await contract.owner();
  console.log("Contract Owner:", owner);
  
  // Get the signer address
  const [signer] = await ethers.getSigners();
  console.log("Hardhat Signer:", signer.address);
  
  // Check if current signer is owner
  if (owner === signer.address) {
    console.log("✅ Hardhat signer IS the owner");
  } else {
    console.log("❌ Hardhat signer is NOT the owner");
  }
  
  // Check if private key account is owner
  if (privateKey) {
    const account = new ethers.Wallet(privateKey);
    if (owner === account.address) {
      console.log("✅ Private key account IS the owner");
    } else {
      console.log("❌ Private key account is NOT the owner");
      console.log("Private key account:", account.address);
      console.log("Contract owner:", owner);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 