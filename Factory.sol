pragma solidity >=0.5.0 <0.6.0;
pragma experimental ABIEncoderV2;


contract Factory{
    

    struct Restaurant {
        string restaurantName;
        address restaurantAddress;
        uint[] reviewsList;
        mapping (uint => Review) reviewStruct;
        bool exist;
        
    }


    struct Review {
        string reviewContent;
        string writer;
    }

    struct ReservationToken {
        string restaurantName;
        address restaurantAddress;
        uint256 dateTime;
        uint tableNo;
        bool exist;
    }
    
    struct User {
        string userName;
        address userAddress;
        uint[] userTokens;
        mapping (uint => ReservationToken) tokenStruct;
        bool exist;
    }

    mapping (bytes32 => ReservationToken) public hashToToken;
    mapping (address => Restaurant) public addressToRestaurant;
    mapping (address => User) public addressToUser;
    
    
    event TokenAdded(bytes32 tokenHash);
    event RestaurantAdded(string restaurantName, address senderAddress);
    event UserAdded(string userName, address userAddress);

    function _addRestaurant (string memory _restaurantName, address senderAddress) private  {
        Restaurant memory newRestaurant;
        newRestaurant.restaurantName = _restaurantName;
        newRestaurant.restaurantAddress = senderAddress;
        newRestaurant.exist = true;
        //Restaurant memory newRestaurant = Restaurant(_restaurantName, senderAddress, Review[](0), true);
        addressToRestaurant[senderAddress] = newRestaurant;
        emit RestaurantAdded(_restaurantName, msg.sender);
    }

    function _createReview (string memory _reviewContent, string memory _writer) internal returns (Review memory) {
        Review memory review = Review(_reviewContent, _writer);
        return review;
    }

    function _addReviewToRestaurant(Review memory _review, address restAddress) internal {
        Restaurant storage restaurant = addressToRestaurant[restAddress];
        uint numberOfReviews = restaurant.reviewsList.length;
        restaurant.reviewsList.push(numberOfReviews);
        restaurant.reviewStruct[numberOfReviews] = _review;

    }

    function _createReservationToken(string memory _restaurantName, address restaurantAddress, uint256 dateTime, uint tableNo) internal returns (ReservationToken memory) {
        ReservationToken memory token = ReservationToken(_restaurantName, restaurantAddress, dateTime, tableNo, true);
        return token;
    }

    function _addToken(ReservationToken memory _reservationToken, bytes32 tokenHash) internal {
        require(hashToToken[tokenHash].exist == false);
        hashToToken[tokenHash] = _reservationToken;
        emit TokenAdded(tokenHash);
    }
    
    function _addUser(string memory _userName, address userAddress) internal {
        User memory newUser;
        newUser.userName = _userName;
        newUser.userAddress = userAddress;
        newUser.exist = true;
        addressToUser[userAddress] = newUser;
        emit UserAdded(newUser.userName, newUser.userAddress);
    }
    
    function registerUser(string memory _userName) public return (string memory, address) {
        require(addressToRestaurant[msg.sender].exist == false);
        require(addressToUser[msg.sender].exist == false);
        _addUser(_userName, msg.sender)
        User memory newUser = addressToUser[msg.sender];
        return (newUser.userName, newUser.userAddress)
        
    }

    function registerRestaurant(string memory _restaurantName) public returns (string memory, address){
        require(addressToRestaurant[msg.sender].exist == false);
        require(addressToUser[msg.sender].exist == false);
        _addRestaurant(_restaurantName, msg.sender);
        Restaurant memory newRestaurant = addressToRestaurant[msg.sender];
        return (newRestaurant.restaurantName, newRestaurant.restaurantAddress);
    }

    function createReservation(uint256 dateTime, uint tableNo) public returns (bytes32) {
        require(addressToRestaurant[msg.sender].exist == true);
        Restaurant memory restaurant = addressToRestaurant[msg.sender];
        string memory restaurantName = restaurant.restaurantName;
        ReservationToken memory reservationToken = _createReservationToken(restaurantName, msg.sender, dateTime, tableNo);
        bytes32 tokenHash = keccak256(abi.encode(restaurantName, msg.sender, dateTime, tableNo));
        _addToken(reservationToken, tokenHash);
        return (tokenHash);
    }
    
    function testRetrieveRestaurant() public view returns (string memory, address) {
        Restaurant memory restaurant = addressToRestaurant[msg.sender];
        return (restaurant.restaurantName, restaurant.restaurantAddress);
    }
    
    function testRetrieveReservation(uint256 dateTime, uint tableNo) public view returns (string memory, address, uint256, uint, bytes32) {
        Restaurant memory restaurant = addressToRestaurant[msg.sender];
        string memory restaurantName = restaurant.restaurantName;
        bytes32 tokenHash = keccak256(abi.encode(restaurantName, msg.sender, dateTime, tableNo));
        if (hashToToken[tokenHash].exist == false) {
            string memory result = "False";
            return (result, msg.sender, 0 , 0, tokenHash);
        }
        else {
            ReservationToken memory token = hashToToken[tokenHash];
            return (token.restaurantName, token.restaurantAddress, token.dateTime, token.tableNo, tokenHash);
        }
        
    }


}