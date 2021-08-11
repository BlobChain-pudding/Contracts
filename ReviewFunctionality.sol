pragma solidity >=0.5.0 <0.6.0;
import "./TokenFunctionality.sol";

contract ReviewFunctions is ReservationTokenFunctions {

    // Private Helper function to create a Review Struct
    function _createReview (string memory _reviewContent, string memory _writer, bytes32 _reservationHash) private pure returns (Review memory) {
        Review memory review = Review(_reviewContent, _writer, _reservationHash);
        return review;
    }

    // Private Helper function to post and save a review under the respective Restaurant Struct
    function _addReviewToRestaurant(Review memory _review, address _restAddress) private {
        Restaurant storage restaurant = addressToRestaurant[_restAddress];
        uint reviewIndex = restaurant.reviewsList.push(0) -1;
        restaurant.keyToReview[reviewIndex] = _review;

    }

    // Private Helper function to check the Proof-of-Visitation submitted by the customer 
    function _checkUserProof(bytes32 _reservationHash) private view {
        require(hashToToken[_reservationHash].exist == true); // Check that the ReservationToken  / Proof-of-Visitation exists
        ReservationToken memory token = hashToToken[_reservationHash];
        require(token.visited == true); // Check that the User has visisted the Restaurant
        require(token.ownerAddress == msg.sender); // Check that the User who called this function is the owner of the Proof-of-Visitation
        require(addressToRestaurant[token.restaurantAddress].exist == true); // Check that the Restaurant associated to this Proof-of-Visitation is a valid and existing Restaurant
    }

    // Public function to be called when a Customer wants to post a review for a restaurant. Only callable by Customers
    function postReview(string memory _reviewContent, string memory _writer, bytes32 _reservationHash) public onlyUser {
        _checkUserProof(_reservationHash); // Check that the user submits a valid Proof-of-Visitation
        Review memory review = _createReview(_reviewContent, _writer, _reservationHash);
        ReservationToken memory token = hashToToken[_reservationHash];
        _addReviewToRestaurant(review, token.restaurantAddress);
        address userAddress = msg.sender;
        _handleTokenSubmitReview(_reservationHash, userAddress);
        emit ReviewSubmitted(msg.sender, token.restaurantAddress, review.reviewContent);
    }

    // Public function to be called to retrieve the reviews of a particular restaurant. 
    function retrieveReview(address _restaurantAddress, uint _retrievalIndex) public view returns (string memory, string memory, bytes32) {
        require(addressToRestaurant[_restaurantAddress].exist == true); // Check that the Restaurant exists 
        Restaurant storage restaurant = addressToRestaurant[_restaurantAddress];
        uint reviewLength = restaurant.reviewsList.length;
        uint reviewIndex = reviewLength - _retrievalIndex -1;
        require(reviewIndex >=0); // Check that the review retrievalIndex is not negative
        Review memory review = restaurant.keyToReview[reviewIndex];
        return (review.reviewContent, review.writer, review.tokenHash);
    }

}