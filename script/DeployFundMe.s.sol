//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        //Anything before startBroadcast is not send as a real tx == no gas cost
        HelperConfig helperConfig = new HelperConfig();
        (address priceFeed /*address anotherPriceFeed*/, ) = helperConfig
            .activeNetworkConfig();
        //After startBroadcast, real tx == gas cost
        vm.startBroadcast(); // => owner of fundme == msg.sender
        // FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);//Still just sepolia, needs forking
        FundMe fundMe = new FundMe(priceFeed); //Using Mocks
        vm.stopBroadcast();
        return fundMe;
    }
}
