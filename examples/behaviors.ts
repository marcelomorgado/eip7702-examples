import { createWalletClient, http, parseEther, parseAbi, createPublicClient } from "viem";
import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { eip7702Actions } from "viem/experimental";

const ALICE_PK = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const BOB_PK = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const BATCH_CALL_DELEGATION = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const RECEIVE_ETH_DELEGATION = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";

const main = async () => {
  const alice = createWalletClient({ chain: anvil, transport: http(), account: privateKeyToAccount(ALICE_PK) }).extend(
    eip7702Actions(),
  );
  const bob = createWalletClient({ chain: anvil, transport: http(), account: privateKeyToAccount(BOB_PK) });

  const publicClient = createPublicClient({ chain: anvil, transport: http() });

  const authorization1 = await alice.signAuthorization({
    contractAddress: BATCH_CALL_DELEGATION,
  });

  const codeBefore = await publicClient.getCode({ address: alice.account.address });
  console.log(">>> Code before: ");
  console.log(codeBefore || "0x");

  console.log(">>> Bob's balance before: ");
  console.log(await publicClient.getBalance({ address: bob.account.address }));

  console.log(">>> Authorization (1):");
  console.log(authorization1);

  const abi = parseAbi(["function execute((bytes data,address to,uint256 value)[])", "function noop()"]);

  const hash = await alice.writeContract({
    abi,
    address: alice.account.address,
    functionName: "execute",
    args: [
      [
        {
          data: "0x",
          to: bob.account.address,
          value: parseEther("1"),
        },
      ],
    ],
    authorizationList: [authorization1],
  });

  console.log(">>> Transaction hash:");
  console.log(hash);

  const codeAfter = await publicClient.getCode({ address: alice.account.address });
  console.log(">>> Code after: ");
  console.log(codeAfter);

  console.log(">>> Bob's balance after batching: ");
  console.log(await publicClient.getBalance({ address: bob.account.address }));

  try {
    await bob.sendTransaction({
      to: alice.account.address,
      value: parseEther("1"),
    });
  } catch {
    console.log(">>> Sending ETH to alice reverts because contract doesn't implement the receive() function");
  }

  // TODO: See how delegate without using `writeContract`
  // await clients.wallet.sendTransaction({
  //   authorizationList: [authorization2],
  // });

  const authorization2 = await alice.signAuthorization({
    contractAddress: RECEIVE_ETH_DELEGATION,
  });

  console.log(">>> Authorization (2):");
  console.log(authorization2);

  await alice.sendTransaction({
    abi,
    address: alice.account.address,
    functionName: "noop",
    authorizationList: [authorization2],
  });

  await bob.sendTransaction({
    to: alice.account.address,
    value: parseEther("1"),
  });

  console.log(">>> Bob's balance after sending ETH back: ");
  console.log(await publicClient.getBalance({ address: bob.account.address }));
};

main();
