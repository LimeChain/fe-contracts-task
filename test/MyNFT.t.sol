// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../src/contracts/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public nft;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public minter = address(0x3);

    function setUp() public {
        nft = new MyNFT();
        nft.grantRole(nft.MINTER_ROLE(), minter);
    }

    function testNFTMetadata() public view {
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    function testMintingNFT() public {
        vm.prank(minter);
        uint256 tokenId = nft.mint(alice, "ipfs://token-uri");

        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(nft.tokenURI(tokenId), "ipfs://token-uri");
    }

    function testUnauthorizedMintReverts() public {
        vm.expectRevert();
        nft.mint(alice, "ipfs://token-uri");
    }

    function testSafeTransferNFT() public {
        vm.prank(minter);
        uint256 tokenId = nft.mint(bob, "ipfs://token-uri");

        assertEq(nft.ownerOf(tokenId), bob);

        vm.prank(bob);
        nft.safeTransferFrom(bob, alice, tokenId);

        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function testSupportsInterface() public view {
        assertTrue(nft.supportsInterface(type(IAccessControl).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC721).interfaceId));
    }
}
