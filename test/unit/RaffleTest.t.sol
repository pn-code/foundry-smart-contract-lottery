// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = address(1);
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        // Deconstructing properties from our active config...
        (entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit, link) =
            helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /**
     * enterRaffle
     */

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle__NotEnoughETH.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    function testRaffleToEmitEnteredRaffleEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));

        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCannotEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Move time forward
        vm.warp(block.timestamp + interval + 1);

        // Set block number
        vm.roll(block.number + 1);

        // At this point, we should be in a calculating state...

        // Perform Upkeep
        raffle.performUpkeep("");

        // Test for revert
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    /**
     * checkUpkeep
     */

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange

        // Move time forward
        vm.warp(block.timestamp + interval + 1);
        // Set block number
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // performUpkeep puts the raffle in a calculating state
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Here we do not warp the time, so we can test if no time has passed
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange

        // Player enters the raffle correctly + balance is added to raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Time requirement is met
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Raffle state is open by default

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }
}
