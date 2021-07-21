pragma solidity >=0.5.0 <0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721.sol";
import "./Factory.sol";

contract ReservationTokenFunctions is Factory, ERC721 {

    function balanceOf(address _userAddress) public view returns (uint256) {
        User memory user = addressToUser[_userAddress];
        uint256 outstandingReservations = user.outstandingReservations;
        return outstandingReservations;
    }

    function ownerOf(bytes32 _tokenId) public view returns (address) {
        ReservationToken memory token = hashToToken[_tokenId];
        address ownerAddress = token.ownerAddress;
        return ownerAddress;
    }

    function _giveUserToken(address _userAddress, bytes32 _tokenHash) private {
        ReservationToken storage token = hashToToken[_tokenHash];
        token.ownerAddress = _userAddress;
        User storage user = addressToUser[_userAddress];
        user.outstandingReservations++;
    }

    function _removeUserToken(address _userAddress, address _restaurantAddress, bytes32 _tokenHash) private {
        ReservationToken storage token = hashToToken[_tokenHash];
        token.ownerAddress = _restaurantAddress;
    }

    function _transfer(address _from, address _to, bytes32 _tokenHash) private {
        if (addressToUser[_to].exist == true) {
            _giveUserToken(_to, _tokenHash);
        }
        else if (addressToRestaurant[_to].exist == true) {
            _removeUserToken(_from, _to, _tokenHash);
        } 
        else {
            revert();
        }
    }

    function _generateProofOfVisitation(bytes32 _reservationHash) private {
        ReservationToken storage token = hashToToken[_reservationHash];
        token.visited = true;
        User storage user = addressToUser[token.ownerAddress];
        user.outstandingReservations --;
    }

    function _handleTokenSubmitReview(bytes32 _reservationHash) internal {
        ReservationToken memory token = hashToToken[_reservationHash];
        _transfer[msg.sender, token.restaurantAddress, _reservationHash];
    }

    function acceptReservation(bytes32 _reservationHash, address _userAddress) public onlyRestaurant() {
        require(hashToToken[_reservationHash].exist == true); //check that reservation token exist
        require(addressToUser[_userAddress].exist == true); //check that user exist
        require(hashToToken[_reservationHash].ownerAddress == msg.sender); //check that token is owned by restaurant
        _transfer(msg.sender, _userAddress, _reservationHash);
    }
    
    function visitedRestaurant(bytes32 _reservationHash, address _userAddress) public onlyRestaurant() {
        require(hashToToken[_reservationHash].exist == true); //check that reservation token exist
        require(addressToUser[_userAddress].exist == true); //check that user exist
        require(hashToToken[_reservationHash].ownerAddress == _userAddress); //check that user currently owns token
        require(hashToToken[_reservationHash].restaurantAddress == msg.sender); //check that calling restaurant created this token
        _generateProofOfVisitation(_reservationHash);
    }

    

    
    
    function testPrintTokenOwnership(bytes32 _reservationHash) public view returns (address) {
        ReservationToken memory token = hashToToken[_reservationHash];
        return token.ownerAddress;
    }
    
    function testPrintOutstandingReservations(address _userAddress) public view returns (uint) {
        User memory user = addressToUser[_userAddress];
        return user.outstandingReservations;
    }
}