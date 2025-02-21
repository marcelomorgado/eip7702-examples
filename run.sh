#!/bin/bash

example=$1

if [ -z "$example" ]; then
  echo "Use: $0 <example>"
  echo -n "Available examples: "
  echo `ls ./examples | sed s/\.ts//g`
  exit
fi

if [ ! -e "examples/$example.ts" ]; then
  echo "example  '$example' not found"
  echo -n "Available examples: "
  echo `ls ./examples | sed s/\.ts//g`
  exit
fi

anvil --hardfork prague > anvil.log 2>&1 &
anvilPID=$!
sleep 2
echo ">>> Deploying contracts..."
forge create --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/BatchCallDelegation.sol:BatchCallDelegation --broadcast
forge create --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/StorageDelegation.sol:StorageDelegation --broadcast
forge create --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/StorageDelegation.sol:StorageDelegation --broadcast
forge create --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/ReceiveEthDelegation.sol:ReceiveEthDelegation --broadcast
npx ts-node examples/$example.ts
kill $anvilPID
