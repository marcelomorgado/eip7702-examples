import { createWalletClient, http, parseEther, parseAbi, createPublicClient } from "viem";
import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { eip7702Actions } from "viem/experimental";

const ALICE_ADDRESS = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const ALICE_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const BOB_ADDRESS = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

const main = async () => {
  const account = privateKeyToAccount(ALICE_PK);

  const clients = {
    wallet: createWalletClient({ chain: anvil, transport: http(), account }).extend(eip7702Actions()),
    public: createPublicClient({ chain: anvil, transport: http() }),
  };

  const authorization = await clients.wallet.signAuthorization({
    contractAddress,
  });

  const codeBefore = await clients.public.getCode({ address: ALICE_ADDRESS });
  console.log(">>> Code before: ");
  console.log(codeBefore || "0x");

  const balanceBefore = await clients.public.getBalance({ address: BOB_ADDRESS });
  console.log(">>> Bob's balance before: ");
  console.log(balanceBefore);

  console.log(">>> Authorization:");
  console.log(authorization);

  const hash = await clients.wallet.writeContract({
    abi: parseAbi(["function execute((bytes data,address to,uint256 value)[])"]),
    address: clients.wallet.account.address,
    functionName: "execute",
    args: [
      [
        {
          data: "0x",
          to: BOB_ADDRESS,
          value: parseEther("1"),
        },
        {
          data: "0x",
          to: BOB_ADDRESS,
          value: parseEther("2"),
        },
      ],
    ],
    authorizationList: [authorization],
  });

  console.log(">>> Transaction hash:");
  console.log(hash);

  const codeAfter = await clients.public.getCode({ address: account.address });
  console.log(">>> Code after: ");
  console.log(codeAfter);

  const balanceAfter = await clients.public.getBalance({ address: BOB_ADDRESS });
  console.log(">>> Bob's balance after: ");
  console.log(balanceAfter);
};

main();
