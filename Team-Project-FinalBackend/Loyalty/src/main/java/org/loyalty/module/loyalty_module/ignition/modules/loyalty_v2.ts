import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LoyaltyV2Module = buildModule("LoyaltyV2Module", (m) => {
  const loyalty = m.contract("Loyalty"); // Updated contract with user IDs

  return { loyalty };
});

export default LoyaltyV2Module; 