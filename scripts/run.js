const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  const gameContract = await gameContractFactory.deploy(
    ["Anakin", "Obi-Wan", "Yoda"],       // Names
    ["https://i.imgflip.com/1nes3t.jpg?a453672", // Images
    "https://nyc3.digitaloceanspaces.com/memecreator-cdn/media/__processed__/de5/template-hello-there-1519-0c6db91aec9c.jpeg", 
    "https://pbs.twimg.com/media/E1SsP89XMAAmyu_.jpg"],
    [100, 200, 180],                    // HP values
    [100, 50, 75]                       // Attack damage values
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn;
  // We only have three characters.
  // an NFT w/ the character at index 2 of our array.
  txn = await gameContract.mintCharacterNFT(2);
  await txn.wait();

  // Get the value of the NFT's URI.
  let returnedTokenUri = await gameContract.tokenURI(1);
  console.log("Token URI:", returnedTokenUri);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();