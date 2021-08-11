pragma solidity >=0.5.0 <0.6.0;

import "./Factory.sol";

contract ReservationTokenFunctions is Factory{

    // Public function to retrieve the total number of outstandingReservations owned by the User Struct associated by the provided public address
    function balanceOf(address _userAddress) public view returns (uint256) {
        User memory user = addressToUser[_userAddress];
        uint256 outstandingReservations = user.outstandingReservations;
        return outstandingReservations;
    }

    // Public function to retrieve the ownerAddress of the ReservationToken associated by the provided token hash
    function ownerOf(bytes32 _tokenId) public view returns (address) {
        ReservationToken memory token = hashToToken[_tokenId];
        address ownerAddress = token.ownerAddress;
        return ownerAddress;
    }

    // Private Helper function to remove an element from an array
    function _removeFromList(uint index, bytes32[] storage _array)  private {
        if (index >= _array.length) return;

        for (uint i = index; i<_array.length-1; i++){
            _array[i] = _array[i+1];
        }
        delete _array[_array.length-1];
        _array.length--;
    }

    // Private Helper function to remove a ReservationToken from a Restaurant Struct after the Customer has used the ReservationToken
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
    
    // Private Helper function to remove a ReservationToken from a User Struct
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

    // Private Helper function to transfer ownership of a ReservationToken from a Restaurant to a User Struct
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

    // Private Helper function to burn a Proof-of-Visitation by transferring the ownership of the Token back to the Restaurant and removing its hash from the User Struct
    function _removeUserToken(address _user, address _restaurantAddress, bytes32 _tokenHash) private {
        ReservationToken storage token = hashToToken[_tokenHash];
        token.ownerAddress = _restaurantAddress;
        _removeReservationFromUser(_user, _tokenHash);
    }

    // Private Helper function to handle the transfer of reservation tokens
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

    // Private Helper function to generate the Proof-of-Visitation after the customer shows up for this reservation
    function _generateProofOfVisitation(bytes32 _reservationHash) private {
        ReservationToken storage token = hashToToken[_reservationHash];
        token.visited = true;
        User storage user = addressToUser[token.ownerAddress];
        user.outstandingReservations --;
    }

    // Internal Helper function to handle the token transfer process after the Customer submits a review
    function _handleTokenSubmitReview(bytes32 _reservationHash, address _userAddress) internal {
        ReservationToken memory token = hashToToken[_reservationHash];
        _transfer(_userAddress, token.restaurantAddress, _reservationHash);
    }

    // Public function to be called to accept a Reservation request from the Customer and transfer ownership of the ReservationToken to that Customer. Only callable by Restaurants
    function acceptReservation(bytes32 _reservationHash, address _userAddress) public onlyRestaurant() {
        require(hashToToken[_reservationHash].exist == true); //check that reservation token exist
        require(addressToUser[_userAddress].exist == true); //check that user exist
        require(hashToToken[_reservationHash].ownerAddress == msg.sender); //check that token is owned by restaurant
        require(hashToToken[_reservationHash].restaurantAddress == msg.sender); //ensure that the token is for this restaurant
        _transfer(msg.sender, _userAddress, _reservationHash);
    }
    
    // Public function to be called to confirm the visitation of a customer with a ReservationToken and generate the Proof-of-Visitation for the Customer. Only callable by Restaurants
    function visitedRestaurant(bytes32 _reservationHash, address _userAddress) public onlyRestaurant() {
        require(hashToToken[_reservationHash].exist == true); //check that reservation token exist
        require(addressToUser[_userAddress].exist == true); //check that user exist
        require(hashToToken[_reservationHash].ownerAddress == _userAddress); //check that user currently owns token
        require(hashToToken[_reservationHash].restaurantAddress == msg.sender); //check that calling restaurant created this token
        _generateProofOfVisitation(_reservationHash);
        _removeReservationFromRestaurant(msg.sender, _reservationHash);
    }

    // Public function to be called to get the no-show scores of a Customer. Returns the outstandingReservations and totalReservations of the User Struct associated by the provided public address
    function getUserScore(address _userAddress) public view returns(uint, uint) {
        require(addressToUser[_userAddress].exist == true); // Check that the user exist
        User memory user = addressToUser[_userAddress];
        uint total = user.totalReservations;
        uint outstanding = user.outstandingReservations;
        return (outstanding, total);
    }

}