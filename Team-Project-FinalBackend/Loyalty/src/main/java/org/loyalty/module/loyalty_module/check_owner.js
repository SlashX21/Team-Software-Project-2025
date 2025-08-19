const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0x92812CdA22aF3485E33e0a589fB7960c24e1a34c";
  
  // Get the contract factory
  const Loyalty = await ethers.getContractFactory("Loyalty");
  
  // Attach to the deployed contract
  const contract = Loyalty.attach(contractAddress);
  
  // Get the owner
  const owner = await contract.owner();
  console.log("Contract Owner:", owner);
  
  // Get the signer address
  const [signer] = await ethers.getSigners();
  console.log("Current Signer:", signer.address);
  
  // Check if current signer is owner
  if (owner === signer.address) {
    console.log("✅ Current signer IS the owner - can award points!");
  } else {
    console.log("❌ Current signer is NOT the owner - cannot award points");
    console.log("You need to use the private key for address:", owner);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 