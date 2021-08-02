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

    function _removeFromList(uint index, bytes32[] storage _array)  private {
        if (index >= _array.length) return;

        for (uint i = index; i<_array.length-1; i++){
            _array[i] = _array[i+1];
        }
        delete _array[_array.length-1];
        _array.length--;
    }


    function _removeReservationFromRestaurant(address _restaurantAddress, bytes32 _reservationHash) private {
        Restaurant storage restaurant = addressToRestaurant[_restaurantAddress];
        bytes32[] storage reservationList = restaurant.reservationHashs;
        for (uint i=0;i<reservationList.length;i++) {
            if (_reservationHash ==reservationList[i]) {
                _removeFromList(i, reservationList);
                break;
            }
        }
    }
    
    function _removeReservationFromUser(address _userAddress, bytes32 _reservationHash) private {
        User storage user = addressToUser[_userAddress];
        bytes32[] storage reservationList = user.reservationHashs;
        for (uint i=0;i<reservationList.length;i++) {
            if (_reservationHash ==reservationList[i]) {
                _removeFromList(i, reservationList);
                break;
            }
        }
        
    }

    function _giveUserToken(address _restaurantAddress, address _userAddress, bytes32 _tokenHash) private {
        ReservationToken storage token = hashToToken[_tokenHash];
        User storage user = addressToUser[_userAddress];
        Restaurant storage restaurant = addressToRestaurant[token.restaurantAddress];

        token.ownerAddress = _userAddress;
        token.accepted = true;

        user.reservationHashs.push(_tokenHash);
        user.outstandingReservations++;
        user.totalReservations++;
    }

    function _removeUserToken(address _user, address _restaurantAddress, bytes32 _tokenHash) private {
        ReservationToken storage token = hashToToken[_tokenHash];
        token.ownerAddress = _restaurantAddress;
        _removeReservationFromUser(_user, _tokenHash);
    }

    function _transfer(address _from, address _to, bytes32 _tokenHash) private {
        if (addressToRestaurant[_from].exist == true) {
            _giveUserToken(_from, _to, _tokenHash);
        }
        else if (addressToRestaurant[_to].exist == true) {
            _removeUserToken( _from, _to, _tokenHash);
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

    function _handleTokenSubmitReview(bytes32 _reservationHash, address _userAddress) internal {
        ReservationToken memory token = hashToToken[_reservationHash];
        _transfer(_userAddress, token.restaurantAddress, _reservationHash);
    }

    function acceptReservation(bytes32 _reservationHash, address _userAddress) public onlyRestaurant() {
        require(hashToToken[_reservationHash].exist == true); //check that reservation token exist
        require(addressToUser[_userAddress].exist == true); //check that user exist
        require(hashToToken[_reservationHash].ownerAddress == msg.sender); //check that token is owned by restaurant
        require(hashToToken[_reservationHash].restaurantAddress == msg.sender); //ensure that the token is for this restaurant
        _transfer(msg.sender, _userAddress, _reservationHash);
    }
    
    function visitedRestaurant(bytes32 _reservationHash, address _userAddress) public onlyRestaurant() {
        require(hashToToken[_reservationHash].exist == true); //check that reservation token exist
        require(addressToUser[_userAddress].exist == true); //check that user exist
        require(hashToToken[_reservationHash].ownerAddress == _userAddress); //check that user currently owns token
        require(hashToToken[_reservationHash].restaurantAddress == msg.sender); //check that calling restaurant created this token
        _generateProofOfVisitation(_reservationHash);
        _removeReservationFromRestaurant(msg.sender, _reservationHash);
    }

    function getUserScore(address _userAddress) public view returns(uint, uint) {
        require(addressToUser[_userAddress].exist == true);
        User memory user = addressToUser[_userAddress];
        uint total = user.totalReservations;
        uint outstanding = user.outstandingReservations;
        return (outstanding, total);
    }

}