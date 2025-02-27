# EIP-7702 Examples

This repository provides a small collection of examples demonstrating usage of
[EIP-7702](https://eips.ethereum.org/EIPS/eip-7702).

> [!WARNING]
> Do not use in production. These contracts are for demonstration purposes only.

The examples cover some scenarios like storage handling, delegating to proxy contract, upgrading delegations, simple
ownership and others.

## Getting Started

1. Clone this repository

```bash
git clone https://github.com/marcelomorgado/eip-7702-examples.git

```

2. Install dependencies

```bash
bun install
```

3. Run [viem](https://viem.sh/experimental/eip7702) [examples](./examples/)

```bash
./run.sh <example>
```

4. Run [foundry](https://book.getfoundry.sh/cheatcodes/sign-delegation) examples

```bash
forge t
```
