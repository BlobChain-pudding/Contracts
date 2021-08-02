pragma solidity >=0.5.0 <0.6.0;
import "./TokenFunctionality.sol";

contract ReviewFunctions is ReservationTokenFunctions {

    function _createReview (string memory _reviewContent, string memory _writer, bytes32 _reservationHash) private pure returns (Review memory) {
        Review memory review = Review(_reviewContent, _writer, _reservationHash);
        return review;
    }

    function _addReviewToRestaurant(Review memory _review, address _restAddress) private {
        Restaurant storage restaurant = addressToRestaurant[_restAddress];
        uint reviewIndex = restaurant.reviewsList.push(0) -1;
        restaurant.keyToReview[reviewIndex] = _review;

    }

    function _checkUserProof(bytes32 _reservationHash) private view {
        require(hashToToken[_reservationHash].exist == true);
        ReservationToken memory token = hashToToken[_reservationHash];
        require(token.visited == true);
        require(token.ownerAddress == msg.sender);
        require(addressToRestaurant[token.restaurantAddress].exist == true);
    }

    function postReview(string memory _reviewContent, string memory _writer, bytes32 _reservationHash) public onlyUser {
        _checkUserProof(_reservationHash);
        Review memory review = _createReview(_reviewContent, _writer, _reservationHash);
        ReservationToken memory token = hashToToken[_reservationHash];
        _addReviewToRestaurant(review, token.restaurantAddress);
        address userAddress = msg.sender;
        _handleTokenSubmitReview(_reservationHash, userAddress);
        emit ReviewSubmitted(msg.sender, token.restaurantAddress, review.reviewContent);
    }

    function retrieveReview(address _restaurantAddress, uint _retrievalIndex) public view returns (string memory, string memory, bytes32) {
        require(addressToRestaurant[_restaurantAddress].exist == true);
        Restaurant storage restaurant = addressToRestaurant[_restaurantAddress];
        uint reviewLength = restaurant.reviewsList.length;
        uint reviewIndex = reviewLength - _retrievalIndex -1;
        require(reviewIndex >=0);
        Review memory review = restaurant.keyToReview[reviewIndex];
        return (review.reviewContent, review.writer, review.tokenHash);
    }

}