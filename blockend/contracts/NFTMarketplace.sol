// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Internal import for NFT openzeppelin contracts
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold;
    uint256 listingPrice = 0.015 ether;
    address payable owner;
    mapping(uint256 => MarketItem) private idMarketItem;
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Let create "CREATE NFT TOKEN" function
    function createToken(
        string memory _tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(
            price >= listingPrice,
            "Price must be greater than listing price"
        );
        require(_exists(tokenId), "Token id does not exist");
        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    //Function for resale token
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "Only owner can resale token"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    //FUNCTION CREATEMARKETSALE
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;
        // uint256 listingPrice = getListingPrice();
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        require(idMarketItem[tokenId].sold == false, "Item already sold");

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        _itemSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        idMarketItem[tokenId].seller.transfer(msg.value);
    }

    //GETTING UNSOLD NFT DATA
    function getUnsoldNFT() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current() - _itemSold.current();
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    //PURCHASED ITEM
    function fetchMyNFt() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner==msg.sender){
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i=0;i<totalCount;i++){
           if(idMarketItem[i+1].owner==msg.sender){
             uint256 currentId = i+1;
            MarketItem storage currentItem = idMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;}
        }
        return items;
    }

    //Single user items
    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].seller==msg.sender){
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);    
        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].seller==msg.sender){
                uint256 currentId = i+1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
