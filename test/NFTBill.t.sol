// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

import 'src/NFTBill.sol';
import 'src/interfaces/IMetadata.sol';
import 'src/OffchainMetadata.sol';
import './utils/mocks/MockERC20.sol';

contract NFTBillTest is Test {
    NFTBill bill;
    MockERC20 coin;
    address w1nt3r = 0x1E79b045Dc29eAe9fdc69673c9DCd7C53E5E159D;
    address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    bytes32 constant PERMIT_TYPEHASH =
        keccak256(
            'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
        );

    function setUp() public {
        vm.deal(w1nt3r, 10 ether);
        OffchainMetadata meta = new OffchainMetadata();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(meta),
            address(this),
            ''
        );

        bill = new NFTBill(IMetadata(address(proxy)));
        coin = new MockERC20();
        coin.mint(w1nt3r, 10 ether);
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

    function testDepositCoinWithPermit() public {
        uint256 privateKey = 0xCAFE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    coin.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner, // owner
                            address(bill), // spender
                            1 ether, // value
                            0,
                            block.timestamp // deadline
                        )
                    )
                )
            )
        );

        coin.mint(owner, 10 ether);
        vm.prank(owner);
        bill.depositWithPermit(
            address(coin),
            1 ether,
            block.timestamp,
            v,
            r,
            s
        );
        assertEq(coin.balanceOf(owner), 9 ether);
        assertEq(coin.balanceOf(address(bill)), 1 ether);

        // Test withdrawal
        uint256 id = (uint256(uint160(address(coin))) << 96) | uint256(1 ether);
        assertEq(bill.balanceOf(owner, id), 1);

        vm.prank(owner);
        bill.safeTransferFrom(owner, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(coin.balanceOf(vitalik), 1 ether);
    }

    function testFailDepositCoinWithPermitReplayAttack() public {
        uint256 privateKey = 0xCAFE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    coin.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner, // owner
                            address(bill), // spender
                            1 ether, // value
                            0,
                            block.timestamp // deadline
                        )
                    )
                )
            )
        );

        coin.mint(owner, 10 ether);
        vm.prank(owner);
        bill.depositWithPermit(
            address(coin),
            1 ether,
            block.timestamp,
            v,
            r,
            s
        );
        bill.depositWithPermit(
            address(coin),
            1 ether,
            block.timestamp,
            v,
            r,
            s
        );
    }

    function testDepositCoinWithPermitFuzzing(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 10 ether);
        uint256 privateKey = 0xCAFE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    coin.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner, // owner
                            address(bill), // spender
                            amount, // value
                            0,
                            block.timestamp // deadline
                        )
                    )
                )
            )
        );

        coin.mint(owner, 10 ether);

        vm.prank(owner);
        bill.depositWithPermit(
            address(coin),
            uint96(amount),
            block.timestamp,
            v,
            r,
            s
        );
        assertEq(coin.balanceOf(owner), 10 ether - amount);
        assertEq(coin.balanceOf(address(bill)), amount);

        uint256 id = (uint256(uint160(address(coin))) << 96) | uint256(amount);
        assertEq(bill.balanceOf(owner, id), 1);

        vm.prank(owner);
        bill.safeTransferFrom(owner, vitalik, id, 1, '');

        vm.prank(vitalik);
        bill.withdraw(id);
        assertEq(coin.balanceOf(vitalik), amount);
    }
}
