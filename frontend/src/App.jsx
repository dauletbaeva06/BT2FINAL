import { useState } from "react";
import { ethers } from "ethers";
import "./App.css";

function App() {
  const [account, setAccount] = useState("");
  const [balance, setBalance] = useState("");

  async function connectWallet() {
    if (!window.ethereum) {
      alert("MetaMask not installed");
      return;
    }

    const provider = new ethers.BrowserProvider(window.ethereum);

    const accounts = await provider.send("eth_requestAccounts", []);

    const signer = await provider.getSigner();

    const address = await signer.getAddress();

    const ethBalance = await provider.getBalance(address);

    setAccount(address);

    setBalance(ethers.formatEther(ethBalance));
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
      </div>
    </div>
  );
}

export default App;