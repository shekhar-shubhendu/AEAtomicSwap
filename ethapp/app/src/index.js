import Web3 from "web3";
// import AE from "@aeternity/aepp-sdk";
// import ContractCompilerAPI from '@aeternity/aepp-sdk/es/contract/compiler'

import Ae from '@aeternity/aepp-sdk/es/ae/universal' // or other flavor

import atomicSwapArtifact from "../../build/contracts/AtomicSwap.json";

const App = {
  web3: null,
  participant: null,
  initiator: null,
  meta: null,
  walletPath: '',
  aeClient: null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = atomicSwapArtifact.networks[networkId];
      this.meta = new web3.eth.Contract(
        atomicSwapArtifact.abi,
        deployedNetwork.address,
      );

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.participant = accounts[1];
      this.initiator = accounts[2];

      // this.refreshBalance();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  initClient: async function() {
    return Ae({ url, process, keypair, internalUrl, compilerUrl, forceCompatibility, nativeMode, networkId, accounts });
  },

  initiate: async function() {
    // AE.Ae.compile();
    const { initiate } = this.meta.methods;
    const d1 = new Date (), d2 = new Date ( d1 );
    d2.setMinutes ( d1.getMinutes() + 10 );
    const ttl = d2.getTime();
    const secretHash = this.web3.utils.keccak256("secret111");
    await initiate().call(ttl, secretHash, this.participant);
  },

};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
