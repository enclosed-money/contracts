// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'src/NFTBill.sol';
import 'src/Metadata.sol';
import 'src/OffchainMetadata.sol';
import 'forge-std/Test.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract ShibaCoin is ERC20 {
    constructor() ERC20('Shiba Inu', 'SHIB') {
        _mint(0x1E79b045Dc29eAe9fdc69673c9DCd7C53E5E159D, 10 ether);
    }
}

contract NFTBillTest is Test {
    NFTBill bill;
    ShibaCoin coin;
    address w1nt3r = 0x1E79b045Dc29eAe9fdc69673c9DCd7C53E5E159D;
    address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    function setUp() public {
        vm.deal(w1nt3r, 10 ether);
        OffchainMetadata meta = new OffchainMetadata();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(meta),
            address(this),
            ''
        );

        bill = new NFTBill(MetadataURI(address(proxy)));
        coin = new ShibaCoin();
    }

    function testDepositEther() public {
        vm.prank(w1nt3r);
        bill.deposit{value: 1 ether}();

        uint256 id = uint256(1 ether);
        assertEq(bill.balanceOf(w1nt3r, id), 1);

        vm.prank(w1nt3r);
        bill.safeTransferFrom(w1nt3r, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(vitalik.balance, 1 ether);
    }

    function testDepositEther(address user, uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= type(uint96).max);
        vm.assume(user != address(0));

        vm.prank(user);
        vm.deal(user, amount);
        bill.deposit{value: amount}();

        uint256 id = uint256(amount);
        assertEq(bill.balanceOf(user, id), 1);

        vm.prank(user);
        bill.safeTransferFrom(user, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(vitalik.balance, amount);
    }

    function testDepositCoin() public {
        vm.prank(w1nt3r);
        coin.approve(address(bill), 1 ether);

        vm.prank(w1nt3r);
        bill.deposit(address(coin), 1 ether);
        assertEq(coin.balanceOf(w1nt3r), 9 ether);
        assertEq(coin.balanceOf(address(bill)), 1 ether);

        uint256 id = (uint256(uint160(address(coin))) << 96) | uint256(1 ether);
        assertEq(bill.balanceOf(w1nt3r, id), 1);

        vm.prank(w1nt3r);
        bill.safeTransferFrom(w1nt3r, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(coin.balanceOf(vitalik), 1 ether);
    }

    function testDepositCoin(address user, uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 10 ether);
        vm.assume(user != address(0));

        vm.prank(user);
        coin.approve(address(bill), amount);

        deal(address(coin), user, 10 ether);
        vm.prank(user);
        bill.deposit(address(coin), uint96(amount));
        assertEq(coin.balanceOf(user), 10 ether - amount);
        assertEq(coin.balanceOf(address(bill)), amount);

        uint256 id = (uint256(uint160(address(coin))) << 96) | uint256(amount);
        assertEq(bill.balanceOf(user, id), 1);

        vm.prank(user);
        bill.safeTransferFrom(user, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(coin.balanceOf(vitalik), amount);
    }

    function testUri() public {
        assertEq(bill.uri(1), '');
    }
}
