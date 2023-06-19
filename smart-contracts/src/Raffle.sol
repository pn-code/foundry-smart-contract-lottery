// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title A sample Raffle Contract
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    error Raffle__NotEnoughETH();

    uint256 private immutable i_entranceFee;
    address payable [] private s_players;

    /** Events */
    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee; 
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETH();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {}

    /** Getter Functions */

    function getEntranceFee() external view returns(uint256) {

    }
}
