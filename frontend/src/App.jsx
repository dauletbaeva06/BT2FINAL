import { useState } from "react";
import { ethers } from "ethers";
import tokenArtifact from "./abi/GovernanceToken.json";
import "./App.css";

const tokenAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

function App() {
  const [account, setAccount] = useState("");
  const [balance, setBalance] = useState("");
  const [govBalance, setGovBalance] = useState("");

  async function connectWallet() {
    if (!window.ethereum) {
      alert("MetaMask not installed");
      return;
    }

    const provider = new ethers.BrowserProvider(window.ethereum);

    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: "0x7A69" }],
    });

    await provider.send("eth_requestAccounts", []);

    const signer = await provider.getSigner();

    const address = await signer.getAddress();

    const ethBalance = await provider.getBalance(address);

    const network = await provider.getNetwork();
    console.log("Chain ID:", network.chainId.toString());

    const code = await provider.getCode(tokenAddress);
    console.log("Token address:", tokenAddress);
    console.log("Contract code:", code);

    const tokenContract = new ethers.Contract(
      tokenAddress,
      tokenArtifact.abi,
      provider
    );

    const tokenBalance = await tokenContract.balanceOf(address);

    setAccount(address);

    setBalance(ethers.formatEther(ethBalance));

    setGovBalance(
      ethers.formatUnits(tokenBalance, 18)
    );
  }

  return (
    <div className="container">
      <h1>DeFi Protocol Dashboard</h1>

      <button onClick={connectWallet}>
        Connect Wallet
      </button>

      <div className="card">
        <h2>Wallet</h2>

        <p>
          <strong>Address:</strong>
        </p>

        <p>{account}</p>

        <p>
          <strong>ETH Balance:</strong>
        </p>

        <p>{balance}</p>

        <p>
          <strong>GOV Balance:</strong>
        </p>

        <p>{govBalance}</p>
      </div>
    </div>
  );
}

export default App;