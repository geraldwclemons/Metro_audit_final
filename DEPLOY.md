# Deployment

Basic deployment:
```bash
source .env

forge script script/deploy-core.s.sol:CoreDeployer --rpc-url ${RPC_FANTOM_TESTNET_URL} --private-key ${PRIVATE_KEY} --slow --broadcast

```

```bash
forge script script/arbitrum/deploy-core.s.sol:CoreDeployer --rpc-url ${RPC_ARBITRUM_URL} --private-key ${PRIVATE_KEY} --with-gas-price 100000000 --gas-price 100000000 --slow --broadcast --etherscan-api-key ${ARBISCAN_API_KEY} --verify
```


With verifying:

```
source .env

forge script script/deploy-core.s.sol:CoreDeployer --rpc-url ${RPC_FANTOM_TESTNET_URL} --private-key ${PRIVATE_KEY} --slow --broadcast --verify --etherscan-api-key ${ZKEVM_POLYSCAN_API_KEY}

```

forge verify-contract --chain-id 1101 --num-of-optimizations 800 \
--compiler-version v0.8.10+commit.fc410830 0xd47885EDA0A0b4ec79E5C37379e8D2e1d0B39017 \
lib\openzeppelin-contracts\contracts\proxy\transparent\ProxyAdmin.sol:ProxyAdmin --watch


forge verify-contract --chain-id 250 --num-of-optimizations 800 \
--compiler-version v0.8.10+commit.fc410830 0xE1D84B09969E34cD0C23836Ab30bDa31da422eB7 lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin --watch

forge script script/fantom/deploy-core.s.sol:CoreDeployer --rpc-url ${RPC_FANTOM_URL} --private-key ${PRIVATE_KEY} --slow --with-gas-price 5300
0000000 --gas-price 53000000000 --etherscan-api-key ${FTMSCAN_API_KEY}


# Sonic 


forge verify-contract --chain-id 146 --num-of-optimizations 800 \
--compiler-version v0.8.10+commit.fc410830 0x53AA092b8e3a0AeD4a5BCa43Ae0827947E193429 \
--constructor-args $(cast abi-encode "constructor(address)" "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38") \
src/VaultFactory:VaultFactory  --watch

forge verify-contract --chain-id 146 --num-of-optimizations 800 \
--compiler-version v0.8.10+commit.fc410830 0xb2d40bcb0b838e878914a5f1bdc7f5eae0199fda \
--constructor-args $(cast abi-encode "constructor(address,uint256)" "0x197d40B36677248E82939f96930bf4E7Fe8aD1c2" "51") \
src/Strategy.sol:Strategy  --watch --etherscan-api-key ${SONICSCAN_API_KEY}

forge verify-contract --chain-id 146 --num-of-optimizations 800 \
--compiler-version v0.8.10+commit.fc410830 0x19d815667267d46254574e62647c2f500449a387 \
--constructor-args $(cast abi-encode "constructor(address)" "0x197d40B36677248E82939f96930bf4E7Fe8aD1c2") \
src/OracleRewardVault.sol:OracleRewardVault  --watch --etherscan-api-key ${SONICSCAN_API_KEY}


forge verify-contract --chain-id 146 --num-of-optimizations 800 \
--compiler-version v0.8.10+commit.fc410830 0x4541cda311AB72420743D03f8f45b42C858046DC \
lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin  --watch --etherscan-api-key ${SONICSCAN_API_KEY}

