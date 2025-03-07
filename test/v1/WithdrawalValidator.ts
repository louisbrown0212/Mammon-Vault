import { ethers, waffle, artifacts } from "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
import { Artifact } from "hardhat/types";
import { expect } from "chai";
import { Signers } from "../../types";
import { PermissiveWithdrawalValidator } from "../../typechain";

const { deployContract } = waffle;

describe("Withdrawal Validator", function () {
  before(async function () {
    this.signers = {} as Signers;
    this.signers.admin = await ethers.getNamedSigner("admin");
  });

  describe("Permissive Withdrawal Validator", function () {
    beforeEach(async function () {
      const validatorArtifact: Artifact = await artifacts.readArtifact(
        "PermissiveWithdrawalValidator",
      );
      this.validator = <PermissiveWithdrawalValidator>(
        await deployContract(this.signers.admin, validatorArtifact, [4])
      );
    });

    it("should return the full withdrawal allowance", async function () {
      const uint256_max: BigNumber = BigNumber.from(2).pow(256).sub(1);
      const tokenAllowances: BigNumber[] = await this.validator.allowance();
      for (let i = 0; i < tokenAllowances.length; i++) {
        expect(tokenAllowances[i]).to.equal(uint256_max);
      }
    });
  });
});
