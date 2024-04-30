import React, { useState, useEffect, useCallback } from 'react';
import Web3 from 'web3';
import { ethers } from 'ethers';
import ArtAuctionABI from './ArtAuctionABI.json';

const ArtAuctionApp = () => {
  const [web3Data, setWeb3Data] = useState({
    web3: null,
    provider: null,
    artAuctionContract: null,
    currentAccount: null,
  });
  const [auctions, setAuctions] = useState([]);

  useEffect(() => {
    loadBlockchainData();
  }, []);

  const loadBlockchainData = async () => {
    if (window.ethereum) {
      const web3 = new Web3(window.ethereum);
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      try {
        await window.ethereum.enable();
        const accounts = await web3.eth.getAccounts();
        if (accounts.length > 0) {
          const networkId = await web3.eth.net.getId();
          const artAuctionData = ArtAuctionABI.networks[networkId];
          if (artAuctionData) {
            const artAuction = new web3.eth.Contract(ArtAuctionABI.abi, artAuctionData.address);
            setWeb3Data({
              web3,
              provider,
              artAuctionContract: artAuction,
              currentAccount: accounts[0],
            });
            loadAuctions(artAuction);
          } else {
            console.error('ArtAuction contract not deployed to detected network.');
          }
        }
      } catch (error) {
        console.error('Could not connect to wallet', error);
      }
    } else {
      console.log('Please install MetaMask!');
    }
  };

  const loadAuctions = async (contract) => {
    const auctions = await contract.methods.getActiveAuctions().call();
    setAuctions(auctions);
  };

  const placeBid = useCallback(async (auctionId, bidAmount) => {
    if (!web3Data.artAuctionContract) return;
    const amountWei = web3Data.web3.utils.toWei(bidAmount.toString(), 'ether');
    try {
      await web3Data.artAuctionContract.methods.placeBid(auctionId).send({ from: web3Data.currentAccount, value: amountWei });
      console.log('Bid placed successfully');
      loadAuctions(web3Data.artAuctionContract);
    } catch (error) {
      console.error('Error placing bid: ', error.message);
    }
  }, [web3Data]);

  return (
    <div>
      <h1>Art Auctions</h1>
      {web3Data.currentAccount ? (
        <div>
          <h2>Auctions</h2>
          <ul>
            {auctions.map((auction, index) => (
              <li key={index}>
                Art: {auction.artName} | Minimum Bid: {web3Data.web3.utils.fromWei(auction.minBid.toString(), 'ether')} ETH
                <button onClick={() => placeBid(auction.id, auction.minBid)}>Place a Bid</button>
              </li>
            ))}
          </ul>
        </div>
      ) : (
        <p>Please connect to MetaMask to interact with the auctions.</p>
      )}
    </div>
  );
};

export default ArtAuctionApp;