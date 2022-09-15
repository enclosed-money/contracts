// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'src/NFTBill.sol';
import 'src/interfaces/IMetadata.sol';
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

        bill = new NFTBill(IMetadata(address(proxy)));
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

    function testDepositEther(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 10 ether);

        vm.prank(w1nt3r);
        bill.deposit{value: amount}();

        uint256 id = uint256(amount);
        assertEq(bill.balanceOf(w1nt3r, id), 1);

        vm.prank(w1nt3r);
        bill.safeTransferFrom(w1nt3r, vitalik, id, 1, '');

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

    function testDepositCoin(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 10 ether);

        vm.prank(w1nt3r);
        coin.approve(address(bill), amount);

        vm.prank(w1nt3r);
        bill.deposit(address(coin), uint96(amount));
        assertEq(coin.balanceOf(w1nt3r), 10 ether - amount);
        assertEq(coin.balanceOf(address(bill)), amount);

        uint256 id = (uint256(uint160(address(coin))) << 96) | uint256(amount);
        assertEq(bill.balanceOf(w1nt3r, id), 1);

        vm.prank(w1nt3r);
        bill.safeTransferFrom(w1nt3r, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(coin.balanceOf(vitalik), amount);
    }

    function testUri() public {
        assertEq(bill.uri(1), '');
    }

    function testWithdrawTo() public {
        vm.prank(w1nt3r);
        bill.deposit{value: 1 ether}();
        uint256 id = uint256(1 ether);
        assertEq(bill.balanceOf(w1nt3r, id), 1);
        vm.prank(w1nt3r);
        bill.withdrawTo(vitalik, id);
        assertEq(vitalik.balance, 1 ether);
    }

    function testWithdrawToCoin() public {
        vm.prank(w1nt3r);
        coin.approve(address(bill), 1 ether);

        vm.prank(w1nt3r);
        bill.deposit(address(coin), 1 ether);
        assertEq(coin.balanceOf(w1nt3r), 9 ether);
        assertEq(coin.balanceOf(address(bill)), 1 ether);

        uint256 id = (uint256(uint160(address(coin))) << 96) | uint256(1 ether);
        assertEq(bill.balanceOf(w1nt3r, id), 1);

        vm.prank(w1nt3r);
        bill.withdrawTo(vitalik, id);
        assertEq(coin.balanceOf(vitalik), 1 ether);
    }
}
