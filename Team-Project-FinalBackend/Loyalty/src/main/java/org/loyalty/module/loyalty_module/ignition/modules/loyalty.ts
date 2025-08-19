import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LoyaltyModule = buildModule("LoyaltyModule", (m) => {
  const loyalty = m.contract("Loyalty"); // 无构造参数

  return { loyalty };
});

export default LoyaltyModule;
