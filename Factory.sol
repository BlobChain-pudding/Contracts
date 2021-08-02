pragma solidity >=0.5.0 <0.6.0;
pragma experimental ABIEncoderV2;


contract Factory{
    

    struct Restaurant {
        string restaurantName;
        address restaurantAddress;
        uint[] reviewsList;
        mapping (uint => Review) keyToReview;
        bytes32[] reservationHashs;
        bool exist;
        
    }


    struct Review {
        string reviewContent;
        string writer;
        bytes32 tokenHash;
    }

    struct ReservationToken {
        string restaurantName;
        address restaurantAddress;
        uint256 dateTime;
        uint tableNo;
        uint pax;
        address ownerAddress;
        bool visited;
        bool accepted;
        bool exist;
    }
    
    struct User {
        string userName;
        address userAddress;
        uint256 outstandingReservations;
        uint256 totalReservations;
        bytes32[] reservationHashs;
        bool exist;
    }


    mapping (bytes32 => ReservationToken) public hashToToken;
    mapping (address => Restaurant) public addressToRestaurant;
    mapping (address => User) public addressToUser;
    
    
    event TokenAdded(bytes32 tokenHash);
    event RestaurantAdded(string restaurantName, address senderAddress);
    event UserAdded(string userName, address userAddress);
    event ReviewSubmitted(address userAddress, address restaurantAddress, string reviewContent);
    event ReturnScore(uint outstanding, uint total);
    
    
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

    function _createReservationToken(string memory _restaurantName, address _restaurantAddress, uint256 _dateTime, uint _tableNo, uint _pax) private pure returns (ReservationToken memory) {
        ReservationToken memory token = ReservationToken(_restaurantName, _restaurantAddress, _dateTime, _tableNo, _pax,  _restaurantAddress, false, false, true);
        return token;
    }

    function _addToken(ReservationToken memory _reservationToken, bytes32 _tokenHash) private {
        require(hashToToken[_tokenHash].exist == false);
        hashToToken[_tokenHash] = _reservationToken;
        emit TokenAdded(_tokenHash);
    }
    
    function _addUser(string memory _userName, address _userAddress) private {
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

    function createReservation(uint256 _dateTime, uint _tableNo, uint _pax) public onlyRestaurant() returns (bytes32) {
        Restaurant storage restaurant = addressToRestaurant[msg.sender];
        string memory restaurantName = restaurant.restaurantName;
        ReservationToken memory reservationToken = _createReservationToken(restaurantName, msg.sender, _dateTime, _tableNo, _pax);
        bytes32 tokenHash = keccak256(abi.encode(restaurantName, msg.sender, _dateTime, _tableNo));
        _addToken(reservationToken, tokenHash);
        restaurant.reservationHashs.push(tokenHash);
        return tokenHash;
    }
    
    function getUserReservationsAll(address _userAddress) public view returns (bytes32[] memory) {
        User memory user = addressToUser[_userAddress];
        bytes32[] memory reservationList = user.reservationHashs;
        return reservationList;
    }


    function getRestaurantReservationsAll(address _restaurantAddress) public view returns (bytes32[] memory) {
        Restaurant memory restaurant = addressToRestaurant[_restaurantAddress];
        bytes32[] memory reservationList = restaurant.reservationHashs;
        return reservationList;
    }
    

    function retrieveRestaurant(address _restaurantAddress) public view returns (string memory, address, bool, uint[] memory) {
        Restaurant memory restaurant = addressToRestaurant[_restaurantAddress];
        return (restaurant.restaurantName, restaurant.restaurantAddress, restaurant.exist, restaurant.reviewsList);
    }
    

}