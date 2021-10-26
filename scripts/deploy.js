const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  const gameContract = await gameContractFactory.deploy(                     
    ["Anakin", "Obi-Wan", "Yoda"],       // Names
    ["Qmcw1c6rs6shDaNnYjYr1ZMGTm3oXJGNeDXpavq9hwpGeq", // Images
    "QmfNcuBEho8x41BwJ58xgBcr9UjPrEW8UShT4xJGjNMwjd", 
    "QmfXnFyQWqYWuWpches45CKGgUyMR94U9USoNjVtpzr8Jx"],
    [100, 200, 180],                    // HP values
    [100, 50, 65],                      // Attack damage values
    [25, 35, 100],                      // Crit chance values
    "Palpatine",
    "QmRtTwh3xppeE5hqHqmdwZL21aVruRiLtgXtSHQXokn8SM",
    10000,
    20
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  // let txn;
  // // We only have three characters.
  // // an NFT w/ the character at index 2 of our array.
  // txn = await gameContract.mintCharacterNFT(2);
  // await txn.wait();

  // // Get the value of the NFT's URI.
  // let returnedTokenUri = await gameContract.tokenURI(1);
  // console.log("Token URI:", returnedTokenUri);

  // txn = await gameContract.attackBoss();
  // await txn.wait();

  // txn = await gameContract.attackBoss();
  // await txn.wait();

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