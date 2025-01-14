 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title Custom NFT Contract (ERC721 compliant)
 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract CustomNft is ERC721, Ownable, ERC721URIStorage, ERC721Burnable{
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;

    address Owner;

    constructor() ERC721("Evolving Pandas Token", "EPT") {
      Owner = msg.sender;
    }

    // function _baseURI() internal pure override returns (string memory) {
    //     return "https://api.mnft.com/tokens/";
    // }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    mapping(address => bool) public whitelist;

    
    uint256 public openingTime;
    uint256 public closingTime;
    uint public mintRate = 0.001 ether;
    string public myTokenURI = "ipfs://QmSb9KiZKkST5p4cm1bSNJKbD2EtEvv9NmArULNqjoxwpm/";
    string public commonEndpoint = "commonURI";
    string public rareEndpoint = "rareURI";
    string public baseExtension = ".json";

    enum Stage {locked, presale, publicsale}
    Stage state;

    function uint2strk(uint256 _i) internal pure returns (string memory str) {
      if (_i == 0)
      {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0)
      {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0)
      {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
}

    function addToWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = true;
  }

  function TimedCrowdsale(uint256 _minutes) public onlyOwner{
    openingTime = block.timestamp;
    closingTime = block.timestamp + (_minutes * 60);
  }

    function addManyToWhitelist(address[] memory _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

    function checkStage() public view returns (Stage stage){
      if(block.timestamp < openingTime) {
        stage = Stage.locked;
        return stage;
      }
      else if(block.timestamp >= openingTime && block.timestamp <= closingTime) {
        stage = Stage.presale;
        return stage;
      }
      else if(block.timestamp >= closingTime) {
        stage = Stage.publicsale;
        return stage;
        }
    }

    function iswhitelisted(address xyz) public view returns (bool) {
      require(checkStage() == Stage.presale);
      if(whitelist[xyz]) return true;
      else return false;
    }

    modifier buffer(address abc) {
      require(openingTime != 0, "Not in state 1");
      require(checkStage() != Stage.locked,"Not in state 2");
      require((checkStage() == Stage.publicsale || iswhitelisted(abc)),"Not in state 2");
      _;
    }

    function random() public view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%10;
    }

    function safeMint(address to, uint _amtOfTokensToMint) public payable buffer(to){
        require(_amtOfTokensToMint < 8 && _amtOfTokensToMint > 0, "Input should be less than 8");
        require(msg.value == (_amtOfTokensToMint * mintRate), "send correct fee");
        for (uint i = 0; i < _amtOfTokensToMint; i++) {
          _tokenIdCounter.increment();
          uint256 tokenId = _tokenIdCounter.current();
          _safeMint(to, tokenId);
          string memory finalURI = uint2strk(tokenId);
          if(random() == 5) {
            finalURI = string(abi.encodePacked(rareEndpoint, finalURI, baseExtension));
          }
          else {
            finalURI = string(abi.encodePacked(commonEndpoint, finalURI, baseExtension));
          }
           _setTokenURI(tokenId, finalURI);
        }
    }

    function getMintFees(uint _amtOfTokensToMint) public view returns(uint){
      return (_amtOfTokensToMint * mintRate);
    }

    function reserveMint(address _owner, uint _reserveAmt) public onlyOwner{
      for (uint i = 0; i < _reserveAmt; i++) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_owner, tokenId);
        string memory finalURI = uint2strk(tokenId);
        finalURI = string(abi.encodePacked(commonEndpoint, finalURI, baseExtension));
        _setTokenURI(tokenId, finalURI);
        }
    }

    function giveAway(address winner, uint256 _tokenIdToGiveaway) public onlyOwner {
      safeTransferFrom(msg.sender, winner, _tokenIdToGiveaway);
    }

    function getMintedTknsAmt() public view returns(uint256) {
      uint256 currentItem = _tokenIdCounter.current();
      return currentItem;
    }
}