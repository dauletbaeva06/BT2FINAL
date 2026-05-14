import { useState } from "react";
import { ethers } from "ethers";

import tokenArtifact from "./abi/GovernanceToken.json";
import ammArtifact from "./abi/AMM.json";
import erc20Artifact from "./abi/MockERC20.json";

import "./App.css";

const govTokenAddress = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";
const tokenAAddress = "0x0165878A594ca255338adfa4d48449f69242Eb8F";
const tokenBAddress = "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853";
const ammAddress = "0x94099942864EA81cCF197E9D71ac53310b1468D8";

function App() {
  const [account, setAccount] = useState("");
  const [balance, setBalance] = useState("");
  const [govBalance, setGovBalance] = useState("");
  const [tokenABalance, setTokenABalance] = useState("");
  const [tokenBBalance, setTokenBBalance] = useState("");
  const [delegateAddress, setDelegateAddress] = useState("");
  const [swapAmount, setSwapAmount] = useState("");
  const [liquidityA, setLiquidityA] = useState("");
  const [liquidityB, setLiquidityB] = useState("");
  const [status, setStatus] = useState("");

  async function getProvider() {
    if (!window.ethereum) {
      alert("MetaMask not installed");
      return null;
    }

    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: "0x7A69" }],
    });

    return new ethers.BrowserProvider(window.ethereum);
  }

  async function connectWallet() {
    const provider = await getProvider();
    if (!provider) return;

    await provider.send("eth_requestAccounts", []);

    const signer = await provider.getSigner();
    const address = await signer.getAddress();

    const ethBalance = await provider.getBalance(address);

    const govToken = new ethers.Contract(govTokenAddress, tokenArtifact.abi, provider);
    const tokenA = new ethers.Contract(tokenAAddress, erc20Artifact.abi, provider);
    const tokenB = new ethers.Contract(tokenBAddress, erc20Artifact.abi, provider);

    const gov = await govToken.balanceOf(address);
    const tka = await tokenA.balanceOf(address);
    const tkb = await tokenB.balanceOf(address);

    setAccount(address);
    setBalance(ethers.formatEther(ethBalance));
    setGovBalance(ethers.formatUnits(gov, 18));
    setTokenABalance(ethers.formatUnits(tka, 18));
    setTokenBBalance(ethers.formatUnits(tkb, 18));
  }

  async function delegateVotes() {
    const provider = await getProvider();
    if (!provider) return;

    if (!delegateAddress) {
      alert("Enter delegate address");
      return;
    }

    const signer = await provider.getSigner();
    const govToken = new ethers.Contract(govTokenAddress, tokenArtifact.abi, signer);

    setStatus("Sending delegate transaction...");
    const tx = await govToken.delegate(delegateAddress);

    setStatus("Waiting for confirmation...");
    await tx.wait();

    setStatus("Delegation successful!");
    await connectWallet();
  }

  async function swapTokenAForTokenB() {
    const provider = await getProvider();
    if (!provider) return;

    if (!swapAmount) {
      alert("Enter swap amount");
      return;
    }

    const signer = await provider.getSigner();
    const tokenA = new ethers.Contract(tokenAAddress, erc20Artifact.abi, signer);
    const amm = new ethers.Contract(ammAddress, ammArtifact.abi, signer);

    const amountIn = ethers.parseUnits(swapAmount, 18);

    setStatus("Approving TokenA...");
    const approveTx = await tokenA.approve(ammAddress, amountIn);
    await approveTx.wait();

    setStatus("Swapping TokenA for TokenB...");
    const swapTx = await amm.swapToken0ForToken1(amountIn, 1);
    await swapTx.wait();

    setStatus("Swap successful!");
    await connectWallet();
  }

  async function addLiquidity() {
    const provider = await getProvider();
    if (!provider) return;

    if (!liquidityA || !liquidityB) {
      alert("Enter both token amounts");
      return;
    }

    const signer = await provider.getSigner();

    const tokenA = new ethers.Contract(tokenAAddress, erc20Artifact.abi, signer);
    const tokenB = new ethers.Contract(tokenBAddress, erc20Artifact.abi, signer);
    const amm = new ethers.Contract(ammAddress, ammArtifact.abi, signer);

    const amountA = ethers.parseUnits(liquidityA, 18);
    const amountB = ethers.parseUnits(liquidityB, 18);

    setStatus("Approving TokenA...");
    const approveA = await tokenA.approve(ammAddress, amountA);
    await approveA.wait();

    setStatus("Approving TokenB...");
    const approveB = await tokenB.approve(ammAddress, amountB);
    await approveB.wait();

    setStatus("Adding liquidity...");
    const tx = await amm.addLiquidity(amountA, amountB, 1);
    await tx.wait();

    setStatus("Liquidity added successfully!");
    await connectWallet();
  }

  return (
    <div className="container">
      <h1>DeFi Protocol Dashboard</h1>

      <button onClick={connectWallet}>Connect Wallet</button>

      <div className="card">
        <h2>Wallet</h2>

        <p><strong>Address:</strong></p>
        <p>{account}</p>

        <p><strong>ETH Balance:</strong></p>
        <p>{balance}</p>

        <p><strong>GOV Balance:</strong></p>
        <p>{govBalance}</p>

        <p><strong>TokenA Balance:</strong></p>
        <p>{tokenABalance}</p>

        <p><strong>TokenB Balance:</strong></p>
        <p>{tokenBBalance}</p>
      </div>

      <div className="card">
        <h2>Governance</h2>

        <input
          type="text"
          placeholder="Delegate address"
          value={delegateAddress}
          onChange={(e) => setDelegateAddress(e.target.value)}
        />

        <button onClick={delegateVotes}>Delegate Votes</button>
      </div>

      <div className="card">
        <h2>Swap</h2>

        <input
          type="text"
          placeholder="Amount of TokenA"
          value={swapAmount}
          onChange={(e) => setSwapAmount(e.target.value)}
        />

        <button onClick={swapTokenAForTokenB}>
          Swap TokenA → TokenB
        </button>
      </div>

      <div className="card">
        <h2>Deposit Liquidity</h2>

        <input
          type="text"
          placeholder="Amount of TokenA"
          value={liquidityA}
          onChange={(e) => setLiquidityA(e.target.value)}
        />

        <input
          type="text"
          placeholder="Amount of TokenB"
          value={liquidityB}
          onChange={(e) => setLiquidityB(e.target.value)}
        />

        <button onClick={addLiquidity}>
          Add Liquidity
        </button>
      </div>

      <div className="card">
        <h2>Status</h2>
        <p>{status}</p>
      </div>
    </div>
  );
}

export default App;