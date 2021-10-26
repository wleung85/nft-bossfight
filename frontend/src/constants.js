const CONTRACT_ADDRESS = '0x63251335281e50dC0943CF8A5e31586E1C9D506f';

const transformCharacterData = (characterData) => {
  return {
    name: characterData.name,
    imageURI: 'https://cloudflare-ipfs.com/ipfs/' + characterData.imageURI,
    hp: characterData.hp.toNumber(),
    maxHp: characterData.maxHp.toNumber(),
    attackDamage: characterData.attackDamage.toNumber(),
  };
};

export { CONTRACT_ADDRESS, transformCharacterData };