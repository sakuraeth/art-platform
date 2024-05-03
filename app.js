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
  const [error, setError] = useState('');

  useEffect(() => {
    loadBlockchainData();
  }, []);

  const loadBlockchainData = async () => {
    setError('');
    if (!window.ethereum) {
      console.log('Ethereum wallet (like MetaMask) is not installed.');
      setError('Ethereum wallet (like MetaMask) is not installed.');
      return;
    }

    const web3 = new Web3(window.ethereum);
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const accounts = await web3.eth.getAccounts();

      if (!accounts.length) {
        setError('No accounts found. Make sure MetaMask is logged in.');
        return;
      }

      const networkId = await web3.eth.net.getId();
      const artAuctionData = ArtAuctionABI.networks[networkId];

      if (!artAuctionData) {
        console.error('ArtAuction contract not deployed to detected network.');
        setError('ArtAuction contract not deployed to detected network.');
        return;
      }

      const artAuction = new web3.eth.Contract(ArtAuctionABI.abi, artAuctionData.address);
      setWeb3Data({
        web3,
        provider,
        artAuctionContract: artAuction,
        currentAccount: accounts[0],
      });
      loadAuctions(artAuction);
    } catch (error) {
      console.error('Failed to connect to MetaMask:', error);
      setError('Failed to connect to MetaMask. ' + error.message);
    }
  };

  const loadAuctions = async (contract) => {
    try {
      const auctionsLoaded = await contract.methods.getActiveAuctions().call();
      setAuctions(auctionsLoaded);
    } catch (error) {
      console.error('Failed to load auctions:', error);
      setError('Failed to load auctions. ' + error.message);
    }
  };

  const placeBid = useCallback(async (auctionId, bidAmount) => {
    if (!web3Data.artAuctionContract) {
      setError('Art Auction Contract is not loaded.');
      return;
    }

    const amountWei = web3Data.web3.utils.toWei(bidAmount.toString(), 'ether');

    try {
      await web3Data.artAuctionContract.methods.placeBid(auctionId).send({ from: web3Data.currentAccount, value: amountWei });
      console.log('Bid placed successfully.');
      loadAuctions(web3Data.artAuctionContract);
    } catch (error) {
      console.error('Error placing bid: ', error);
      setError('Error placing bid. ' + error.message);
    }
  }, [web3Data]);

  return (
    <div>
      <h1>Art Auctions</h1>
      {error && <p style={{ color: 'red' }}>Error: {error}</p>}
      {web3Data.currentAccount ? (
        <div>
          <h2>Auctions</h2>
          <ul>
            {auctions.map((auction, index) => (
              <li key={index}>
                Art: {auction.artName} | Minimum Bid: {web3Data.web3.utils.fromWei(auction.minBid.toString(), 'ether')} ETH
                <button onClick={() => placeBid(auction.id, auction.minBid)}>Place Bid</button>
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