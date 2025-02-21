import { createWalletClient, http, parseEther, parseAbi, createPublicClient } from "viem";
import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { eip7702Actions } from "viem/experimental";

const ALICE = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ALICE_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const BOB = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const STORAGE_DELEGATION_1 = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const STORAGE_DELEGATION_2 = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

const main = async () => {
  const account = privateKeyToAccount(ALICE_PK);

  const clients = {
    wallet: createWalletClient({ chain: anvil, transport: http(), account }).extend(eip7702Actions()),
    public: createPublicClient({ chain: anvil, transport: http() }),
  };

  const authorization1 = await clients.wallet.signAuthorization({
    contractAddress: STORAGE_DELEGATION_1,
  });

  const abi = parseAbi(["function set(uint256)", "function counter() view returns (uint256)", "function noop()"]);

  await clients.wallet.writeContract({
    abi,
    address: account.address,
    functionName: "set",
    args: [10n],
    authorizationList: [authorization1],
  });

  const counterBefore = await clients.public.readContract({
    abi,
    address: account.address,
    functionName: "counter",
  });

  console.log(">>> Counter before:");
  console.log(counterBefore);

  const authorization2 = await clients.wallet.signAuthorization({
    contractAddress: STORAGE_DELEGATION_2,
  });

  // TODO: See how delegate without using `writeContract`
  // await clients.wallet.sendTransaction({
  //   authorizationList: [authorization2],
  // });

  await clients.wallet.writeContract({
    abi,
    address: account.address,
    functionName: "noop",
    authorizationList: [authorization2],
  });

  const counterAfter = await clients.public.readContract({
    abi,
    address: account.address,
    functionName: "counter",
  });

  console.log(">>> Counter after:");
  console.log(counterAfter);
};

main();
