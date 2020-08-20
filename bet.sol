// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

contract Bet {
  // Addresses of each participant and arbitor [CHANGE ME BEFORE DEPLOYMENT]
  address public participantA = address(0x0);
  address public participantB = address(0x0);
  address public arbitor = address(0x0);

  // Don't change this, it will be set by the arbitor
  address public winner = address(0x0);

  // Allow ETH to be paid into contract
  receive() external payable {}
  fallback() external payable {}

  // Allow ERC223 to be paid into contract
  function tokenFallback (address from, uint value, bytes memory data) external {}

  function getSignaturePreimage(
    address winnerAddress
  ) public view returns (
    bytes memory
  ){
    // Sign winner address to prevent fraud
    // Sign contract address to prevent replay attacks

    return abi.encode(
      winnerAddress,
      this
    );
  }

  function setWinner(
    address winnerAddress,
    bytes memory countersignature
  ) external {
    address countersigner = ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(
          getSignaturePreimage(winnerAddress)
        )
      ),
      countersignature
    );

    // Require signature from both participants
    // (one participant signed the transaction
    // the other signed as countersigner)

    if (msg.sender == participantA) {
      require(countersigner == participantB || countersigner == arbitor);
    } else if (msg.sender == participantB) {
      require(countersigner == participantA || countersigner == arbitor);
    } else {
      revert();
    }

    winner = winnerAddress;
  }

  // Transfer ETH out
  function transferEth(
    address payable to,
    uint256 amount
  ) external {
    // Only winner can withdraw
    require(msg.sender == winner);

    // Transfer eth
    to.transfer(amount);
  }

  // Transfer tokens out 
  function transferToken(
    address to,
    uint256 amount,
    address tokenContractAddress
  ) external {
    // Only winner can withdraw
    require(msg.sender == winner);

    // Transfer tokens
    IERC20(tokenContractAddress).transfer(to, amount);
  }
}
