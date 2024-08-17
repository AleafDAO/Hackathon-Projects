// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.13;

// import "forge-std/Script.sol";
// import "src/NFT.sol";
// import "src/Token.sol";
// import "src/Admin.sol";
// import "src/Tools/IsAdmin.sol";

// contract TRY is Script {
//     function run() external {
//         vm.startBroadcast();

//         address isAdminAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
//         address nftAddress = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
//         address tokenAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
//         address adminAddress = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

//         IsAdmin isAdmin = IsAdmin(isAdminAddress);
//         NFT nft = NFT(nftAddress);
//         Token token = Token(payable(tokenAddress));
//         Admin admin = Admin(adminAddress);

//         token.mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,100000);

//         admin.buy(0);
//         admin.rent(1,10);

//         vm.stopBroadcast();

//     }
// }