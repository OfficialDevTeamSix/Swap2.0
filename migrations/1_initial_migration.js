const MoonForce = artifacts.require("MoonForce");

module.exports = function (deployer) {
  deployer.deploy(
      MoonForce,
      '0x07Dce0028a9D8aBe907B8c11F8EA912FeaB27f03',
      '0x2E241fF5bee46DBf7E3b984D15388989b912F2A6',
      '0x2E241fF5bee46DBf7E3b984D15388989b912F2A6'
  );
};
