// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}
