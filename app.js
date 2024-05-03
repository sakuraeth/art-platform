import React, { useState, useEffect, useCallback, useMemo } from 'react';
import Web3 from 'web3';
import { ethers } from 'ethers';
import ArtAuctionABI from './ArtAuctionABI.json';

const ArtAuctionApp = () => {
  const [web3, setWeb3] = useState(null);
  const [currentAccount, setCurrentAccount] = useState(null);
  const [artAuctionContract, setArtAuctionContract] = useState(null);
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

    const web3Instance = new Web3(window.ethereum);
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const accounts = await web3Instance.eth.getAccounts();

      if (!accounts.length) {
        setError('No accounts found. Make sure MetaMask is logged in.');
        return;
      }

      const networkId = await web3Instance.eth.net.getId();
      const artAuctionData = ArtAuctionABI.networks[networkId];

      if (!artAuctionData) {
        console.error('ArtAuction contract not deployed to detected network.');
        setError('ArtAuction contract not deployed to detected network.');
        return;
      }

      const artAuction = new web3Instance.eth.Contract(ArtAuctionABI.abi, artAuctionData.address);
      setWeb3(web3Instance);
      setCurrentAccount(accounts[0]);
      setArtAuctionContract(artAuction);
      loadAuctions(artAuction);
    } catch (error) {
      console.error('Failed to connect to MetaMask:', error);
      setError('Failed to connect to MetaMask. ' + error.message);
    }
  };

  const loadAuctions = useCallback(async (contract) => {
    try {
      const auctionsLoaded = await contract.methods.getActiveAuctions().call();
      setAuctions(auctionsLoaded);
    } catch (error) {
      console.error('Failed to load auctions:', error);
      setError('Failed to load auctions. ' + error.message);
    }
  }, []);

  const placeBid = useCallback(async (auctionId, bidAmount) => {
    if (!artAuctionContract) {
      setError('Art Auction Contract is not loaded.');
      return;
    }

    const amountWei = web3.utils.toWei(bidAmount.toString(), 'ether');
    try {
      await artAuctionContract.methods.placeBid(auctionId).send({ from: currentAccount, value: amountWei });
      console.log('Bid placed successfully.');
      loadAuctions(artAuctionContract);
    } catch (error) {
      console.error('Error placing bid: ', error);
      setError('Error placing bid. ' + error.message);
    }
  }, [artAuctionContract, currentAccount, web3, loadAuctions]);

  const fromWei = useCallback((value) => {
    return web3 ? web3.utils.fromWei(value.toString(), 'ether') : '';
  }, [web3]);

  const isUserConnected = useMemo(() => !!currentAccount, [currentAccount]);

  return (
    <div>
      <h1>Art Auctions</h1>
      {error && <p style={{ color: 'red' }}>Error: {error}</p>}
      {isUserConnected ? (
        <div>
          <h2>Auctions</h2>
          <ul>
            {auctions.map((auction, index) => (
              <li key={index}>
                Art: {auction.artName} | Minimum Bid: {fromWei(auction.minBid)} ETH
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