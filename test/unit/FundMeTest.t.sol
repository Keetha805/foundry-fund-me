//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        //REFACTORING, No hardcoded addresses
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // DeployFundMe(us)->FundMeTest->FundMe
        // assertEq(fundMe.i_owner(), address(this));
        // FundMeTest=>DeployFundMe(us)->FundMe
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // What can we do to work with addresses outside of our system? 3. Forked
    // 1. Unit: Testing a single function
    // 2. Integration: Testing multiple functions, how part of the code works with other parts of the code
    // 3. Forked: Testing on a forked network, a simulated real enviroment
    // 4. Staging: Testing on a live network (testnet or mainnet)

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    //testFail
    function testFailsWithoutEnoughETH() public {
        fundMe.fund();
    }

    //vm.expectRevert();
    function testFundFailsWithoutEnoughETHNoMessage() public {
        vm.expectRevert();
        fundMe.fund();
    }

    //vm.expectRevert(); with message
    function testFundFailsWithoutEnoughETHWithMessage() public {
        vm.expectRevert(bytes("You need to spend more ETH!"));
        fundMe.fund();
    }

    function testFundUpdatesFundeDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        //us => fundMeTest => fundMe
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        //us => fundMeTest => fundMe
        assertEq(fundMe.getFunder(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 1e18}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    uint256 constant GAS_PRICE = 1;

    function testWithdrawWithSingleFunder() public funded {
        //Arrage
        uint256 startingBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = (address(fundMe)).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasUsed: ", gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrage
        uint256 numberOfFunders = 10;
        for (uint256 i = 1; i < numberOfFunders; i++) {
            // address funder = makeAddr(i);
            // vm.prank(funder);
            // vm.deal(funder, STARTING_BALANCE);
            hoax(address(uint160(i)), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = (address(fundMe)).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingBalance, endingOwnerBalance);
    }

    function testCheaperWithdrawFromMultipleFunders() public funded {
        //Arrage
        uint256 numberOfFunders = 10;
        for (uint256 i = 1; i < numberOfFunders; i++) {
            // address funder = makeAddr(i);
            // vm.prank(funder);
            // vm.deal(funder, STARTING_BALANCE);
            hoax(address(uint160(i)), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = (address(fundMe)).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingBalance, endingOwnerBalance);
    }
}
