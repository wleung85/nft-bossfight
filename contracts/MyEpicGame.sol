// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Import chainlink for randomness
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Helper we wrote to encode in Base64
import "./libraries/Base64.sol";

import "hardhat/console.sol";

// Inherit ERC721, which is the standard NFT contract!
contract MyEpicGame is ERC721, VRFConsumerBase {

  bytes32 internal keyHash;
  uint256 internal fee;

  uint256 private randomResult;
  uint256 private constant ATTACK_IN_PROGRESS = 106;
  uint256 private constant OUT_OF_LINK = 100;

  // stores a mapping between requestID of the random request and the user
  mapping(bytes32 => address) private s_rollers;
  // stores the result of the roll
  mapping(address => uint256) private s_results;

  event BossAttacked(bytes32 indexed requestId, address indexed roller);

  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;        
    uint hp;
    uint maxHp;
    uint attackDamage;
    uint critChance;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  CharacterAttributes[] defaultCharacters;

  // mapping tokenId -> NFTs attributes
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

  struct BigBoss {
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }

  BigBoss public bigBoss;

  // Mapping from an address -> NFT's tokenId
  mapping(address => uint256) public nftHolders;

  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);

   /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * LINK token address:                0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */

  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    uint[] memory characterCritChance,
    string memory bossName,
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage
  )
    ERC721("Heroes", "HERO")
    VRFConsumerBase(
      0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
      0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token
    )
  {
    keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)

    // Initialize the boss. Save it to our global "bigBoss" state variable.
    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage
    });

    console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

    // Loop through all the characters, and save their values in our contract so
    // we can use them later when we mint our NFTs.
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i],
        critChance: characterCritChance[i]
      }));

      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
    }

    // Increment tokenIds so first NFT has an ID of 1
    _tokenIds.increment();
  }

  function mintCharacterNFT(uint _characterIndex) external {
    // Get current tokenId (starts at 1 since we incremented in the constructor).
    uint256 newItemId = _tokenIds.current();

    // Assigns the tokenId to the caller's wallet address.
    _safeMint(msg.sender, newItemId);

    // We map the tokenId => their character attributes. More on this in
    // the lesson below.
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].hp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage,
      critChance: defaultCharacters[_characterIndex].critChance
    });

    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    // Keep an easy way to see who owns what NFT.
    nftHolders[msg.sender] = newItemId;

    // Increment the tokenId for the next person that uses it.
    _tokenIds.increment();

    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);
    string memory strCritChance = Strings.toString(charAttributes.critChance);

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "This is an NFT that lets people play in the game Metaverse Slayer!", "image": "ipfs://',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'}, {"display_type": "boost_number", "trait_type": "Crit Chance", "value": ',strCritChance,'} ]}'
          )
        )
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
    
    return output;
  }

  function attackBoss() public returns (bytes32 requestId) {
    // Get the state of the player's NFT.
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    CharacterAttributes memory player = nftHolderAttributes[nftTokenIdOfPlayer];
    console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
    console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);

    // Make sure the player has more than 0 HP.
    require (
      player.hp > 0,
      "Error: character must have HP to attack boss."
    );

    // Make sure the boss has more than 0 HP.
    require (
      bigBoss.hp > 0,
      "Error: boss must have HP to attack boss."
    );

    require(
      s_results[msg.sender] != ATTACK_IN_PROGRESS,
      "Previous attack in progress."
    );

    require(
      LINK.balanceOf(address(this)) >= fee,
      "Out of LINK, refill contract."
    );

    // Allow player to attack boss.
    requestId = requestRandomness(keyHash, fee);
    s_results[msg.sender] = ATTACK_IN_PROGRESS;
    console.log("Player attacking boss -- requesting randomness");
    emit BossAttacked(requestId, msg.sender);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    uint256 critRoll = randomness % 100 + 1;
    address playerAddr = s_rollers[requestId];
    s_results[playerAddr] = critRoll;

    // Get the state of the player's NFT.
    uint256 nftTokenIdOfPlayer = nftHolders[playerAddr];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
    uint256 playerDmg = player.attackDamage;

    if (s_results[playerAddr] < player.critChance) {
      playerDmg *= 2;
    }

    if (bigBoss.hp < playerDmg) {
      bigBoss.hp = 0;
    } else {
      bigBoss.hp = bigBoss.hp - playerDmg;
    }
    console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);

    // Allow boss to attack player.
    if (bigBoss.hp > 0) {
      if (player.hp < bigBoss.attackDamage) {
        player.hp = 0;
      } else {
        player.hp = player.hp - bigBoss.attackDamage;
      }

      console.log("Boss attacked player. New player hp: %s", player.hp);
    }

    emit AttackComplete(bigBoss.hp, player.hp);
    
  }

  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
    // Get the tokenId of the user's character NFT
    uint256 userNftTokenId = nftHolders[msg.sender];
    // If the user has a tokenId in the map, return thier character.
    if (userNftTokenId > 0) {
      return nftHolderAttributes[userNftTokenId];
    }
    // Else, return an empty character.
    else {
      CharacterAttributes memory emptyStruct;
      return emptyStruct;
    }
  }

  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }

  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }
}