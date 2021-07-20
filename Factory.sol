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
        address ownerAddress;
        bool exist;
    }
    
    struct User {
        string userName;
        address userAddress;
        uint256 userTokenCount;
        bool exist;
    }

    mapping (bytes32 => ReservationToken) public hashToToken;
    mapping (address => Restaurant) public addressToRestaurant;
    mapping (address => User) public addressToUser;
    
    
    event TokenAdded(bytes32 tokenHash);
    event RestaurantAdded(string restaurantName, address senderAddress);
    event UserAdded(string userName, address userAddress);
    
    
    modifier onlyRestaurant() {
        require(addressToRestaurant[msg.sender].exist == true);
        _;
    }

    modifier onlyUser() {
        require(addressToUser[msg.sender].exist == true);
        _;
    }
    
    
    function _addRestaurant (string memory _restaurantName, address _senderAddress) private  {
        Restaurant memory newRestaurant;
        newRestaurant.restaurantName = _restaurantName;
        newRestaurant.restaurantAddress = _senderAddress;
        newRestaurant.exist = true;
        addressToRestaurant[_senderAddress] = newRestaurant;
        emit RestaurantAdded(_restaurantName, _senderAddress);
    }

    function _createReview (string memory _reviewContent, string memory _writer) internal pure returns (Review memory) {
        Review memory review = Review(_reviewContent, _writer);
        return review;
    }

    function _addReviewToRestaurant(Review memory _review, address _restAddress) internal {
        Restaurant storage restaurant = addressToRestaurant[_restAddress];
        uint reviewIndex = restaurant.reviewsList.push(0) -1;
        restaurant.reviewStruct[reviewIndex] = _review;

    }

    function _createReservationToken(string memory _restaurantName, address _restaurantAddress, uint256 _dateTime, uint _tableNo) internal pure returns (ReservationToken memory) {
        ReservationToken memory token = ReservationToken(_restaurantName, _restaurantAddress, _dateTime, _tableNo, _restaurantAddress, true);
        return token;
    }

    function _addToken(ReservationToken memory _reservationToken, bytes32 _tokenHash) internal {
        require(hashToToken[_tokenHash].exist == false);
        hashToToken[_tokenHash] = _reservationToken;
        emit TokenAdded(_tokenHash);
    }
    
    function _addUser(string memory _userName, address _userAddress) internal {
        User memory newUser;
        newUser.userName = _userName;
        newUser.userAddress = _userAddress;
        newUser.exist = true;
        addressToUser[_userAddress] = newUser;
        emit UserAdded(newUser.userName, newUser.userAddress);
    }
    
    function registerUser(string memory _userName) public returns (string memory, address) {
        require(addressToRestaurant[msg.sender].exist == false);
        require(addressToUser[msg.sender].exist == false);
        _addUser(_userName, msg.sender);
        User memory newUser = addressToUser[msg.sender];
        return (newUser.userName, newUser.userAddress);
        
    }

    function registerRestaurant(string memory _restaurantName) public returns (string memory, address){
        require(addressToRestaurant[msg.sender].exist == false);
        require(addressToUser[msg.sender].exist == false);
        _addRestaurant(_restaurantName, msg.sender);
        Restaurant memory newRestaurant = addressToRestaurant[msg.sender];
        return (newRestaurant.restaurantName, newRestaurant.restaurantAddress);
    }

    function createReservation(uint256 _dateTime, uint _tableNo) public onlyRestaurant() returns (bytes32) {
        Restaurant memory restaurant = addressToRestaurant[msg.sender];
        string memory restaurantName = restaurant.restaurantName;
        ReservationToken memory reservationToken = _createReservationToken(restaurantName, msg.sender, _dateTime, _tableNo);
        bytes32 tokenHash = keccak256(abi.encode(restaurantName, msg.sender, _dateTime, _tableNo));
        _addToken(reservationToken, tokenHash);
        return (tokenHash);
    }
    
    function testRetrieveRestaurant() public view returns (string memory, address) {
        Restaurant memory restaurant = addressToRestaurant[msg.sender];
        return (restaurant.restaurantName, restaurant.restaurantAddress);
    }
    
    function testRetrieveReservation(uint256 _dateTime, uint _tableNo) public view returns (string memory, address, uint256, uint, bytes32) {
        Restaurant memory restaurant = addressToRestaurant[msg.sender];
        string memory restaurantName = restaurant.restaurantName;
        bytes32 tokenHash = keccak256(abi.encode(restaurantName, msg.sender, _dateTime, _tableNo));
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