pragma solidity >=0.5.0 <0.6.0;
pragma experimental ABIEncoderV2;


contract Factory{
    
    /*
    /////// Custom Struct to store the details for the Restaurant ///////
    restaurantName: Actual name of the restaurant
    restaurantAddress: Public address of the restaurant
    reviewsList: A list of index to be used as keys for the keyToReview mapping
    keyToReview: An integer to Review struct mapping to store the reviews posted about this restaurant
    reservationHashs: An array to store the hash of the ReservationTokens owned by this restaurant
    exist: Boolean to indicate if this Struct exist in the Blockchain
    */
    struct Restaurant {
        string restaurantName;
        address restaurantAddress;
        uint[] reviewsList;
        mapping (uint => Review) keyToReview;
        bytes32[] reservationHashs;
        bool exist;
        
    }


    /*
    /////// Custom Struct to store the details for the Review ///////
    reviewContent: String of the review written
    writer: String userName of the customer who posted the review
    tokenHash: Bytes32 hash of the ReservationToken assigned to this Review
    */
    struct Review {
        string reviewContent;
        string writer;
        bytes32 tokenHash;
    }


    /*
    /////// Custom Struct to store the details for the ReservationToken ///////
    restaurantName: Actual name of the restaurant
    restaurantAddress: Public address of the restaurant
    dateTime: Integer to store the Unix time format of the reservation slot
    tableNo: Integer to store the table number for this reservation
    pax: Integer to store the total number of occupancy for this table
    ownerAddress: Address of the current owner of this ReservationToken
    visited: Boolean to indicate owner's Proof-of-Visitation
    accepted: Boolean to indicate if this ReservationToken has been reserved
    exist: Boolean to indicate if this Struct exist in the Blockchain
    */
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


     /*
    /////// Custom Struct to store the details for the Customer ///////
    userName: String representation of the Customer's chosen username
    userAddress: Public address of the Customer
    outstandingReservations: Integer of the total number of reservations this Customer have not fulfilled 
    totalReseervations: Integer of the total number of reservations this Customer has reserved
    reservationHashs: An array to store the hash of the ReservationTokens owned by this Customer
    exits: Boolean to indicate if this Struct exist in the blockchain
    */
    struct User {
        string userName;
        address userAddress;
        uint256 outstandingReservations;
        uint256 totalReservations;
        bytes32[] reservationHashs;
        bool exist;
    }


    /*
    //////// Mappings ////////
    hashToToken: Mapping to store all the ReservationTokens using its keccak256 hash as the key
    addressToRestaurant: Mapping to store all the Restaurant Struct using its public address as the key
    addressToUser: Mapping to store all the User Struct using its public address as the key
    */
    mapping (bytes32 => ReservationToken) public hashToToken;
    mapping (address => Restaurant) public addressToRestaurant;
    mapping (address => User) public addressToUser;
    
    //// Events //////
    event TokenAdded(bytes32 tokenHash);
    event RestaurantAdded(string restaurantName, address senderAddress);
    event UserAdded(string userName, address userAddress);
    event ReviewSubmitted(address userAddress, address restaurantAddress, string reviewContent);
    event ReturnScore(uint outstanding, uint total);
    
    /*
    //////// Modifiers ////////
    onlyRestaurant: Only allows function to proceed if the msg.sender is a key to an existing Restaurant Struct in the addressToRestaurant mapping
    onlyUser: Only allows function to proceed if the msg.sender is a key to an existing User Struct in the addressToUser mapping
    */
    modifier onlyRestaurant() {
        require(addressToRestaurant[msg.sender].exist == true);
        _;
    }

    modifier onlyUser() {
        require(addressToUser[msg.sender].exist == true);
        _;
    }
    
    
    // Private Helper function to create a Restaurant Struct and store it in the addressToRestaurant mapping
    function _addRestaurant (string memory _restaurantName, address _senderAddress) private  {
        Restaurant memory newRestaurant;
        newRestaurant.restaurantName = _restaurantName;
        newRestaurant.restaurantAddress = _senderAddress;
        newRestaurant.exist = true;
        addressToRestaurant[_senderAddress] = newRestaurant;
        emit RestaurantAdded(_restaurantName, _senderAddress);
    }

    // Private Helper function to create a ReservationToken and return it 
    function _createReservationToken(string memory _restaurantName, address _restaurantAddress, uint256 _dateTime, uint _tableNo, uint _pax) private pure returns (ReservationToken memory) {
        ReservationToken memory token = ReservationToken(_restaurantName, _restaurantAddress, _dateTime, _tableNo, _pax,  _restaurantAddress, false, false, true);
        return token;
    }

    // Private Helper function to check if the ReservationToken exist using its hash, and if it does not, add it to the hashToToken mapping
    function _addToken(ReservationToken memory _reservationToken, bytes32 _tokenHash) private {
        require(hashToToken[_tokenHash].exist == false); //Check that the reservation token does not already exist
        hashToToken[_tokenHash] = _reservationToken;
        emit TokenAdded(_tokenHash);
    }

    // Private Helper function to create a User Struct and store it in the addressToUser mapping    
    function _addUser(string memory _userName, address _userAddress) private {
        User memory newUser;
        newUser.userName = _userName;
        newUser.userAddress = _userAddress;
        newUser.exist = true;
        addressToUser[_userAddress] = newUser;
        emit UserAdded(newUser.userName, newUser.userAddress);
    }

    // Public function to be called to register a new user to the blockchain    
    function registerUser(string memory _userName) public returns (string memory, address) {
        require(addressToRestaurant[msg.sender].exist == false); //check that the msg sender is not an existing Restaurant
        require(addressToUser[msg.sender].exist == false); //check that the msg sender is not an existing User
        _addUser(_userName, msg.sender);
        User memory newUser = addressToUser[msg.sender];
        return (newUser.userName, newUser.userAddress);
        
    }

    // Public function to be called to register a new Restaurant to the blockchain
    function registerRestaurant(string memory _restaurantName) public returns (string memory, address){
        require(addressToRestaurant[msg.sender].exist == false); //check that the msg sender is not an existing Restaurant
        require(addressToUser[msg.sender].exist == false); //check that the msg sender is not an existing User
        _addRestaurant(_restaurantName, msg.sender);
        Restaurant memory newRestaurant = addressToRestaurant[msg.sender];
        return (newRestaurant.restaurantName, newRestaurant.restaurantAddress);
    }

    // Public function to be called to create a new ReservationToken. Only callable by Restaurants
    function createReservation(uint256 _dateTime, uint _tableNo, uint _pax) public onlyRestaurant() returns (bytes32) {
        Restaurant storage restaurant = addressToRestaurant[msg.sender];
        string memory restaurantName = restaurant.restaurantName;
        ReservationToken memory reservationToken = _createReservationToken(restaurantName, msg.sender, _dateTime, _tableNo, _pax);
        bytes32 tokenHash = keccak256(abi.encode(restaurantName, msg.sender, _dateTime, _tableNo)); // Get the token hash using the restaurantName, public address, time slot and table number
        _addToken(reservationToken, tokenHash);
        restaurant.reservationHashs.push(tokenHash);
        return tokenHash;
    }
    
    // Public function to be called to retrieve the array of reservationHashs owned by the User Struct associated by the given public address
    function getUserReservationsAll(address _userAddress) public view returns (bytes32[] memory) {
        User memory user = addressToUser[_userAddress];
        bytes32[] memory reservationList = user.reservationHashs;
        return reservationList;
    }


    // Public function to be called to retrieve the array of reservationHashs owned by the Restaurant Struct associated by the given public address
    function getRestaurantReservationsAll(address _restaurantAddress) public view returns (bytes32[] memory) {
        Restaurant memory restaurant = addressToRestaurant[_restaurantAddress];
        bytes32[] memory reservationList = restaurant.reservationHashs;
        return reservationList;
    }
    

    // Public function to be called to retrieve the details of the Restaurant Struct associated by the given public address
    function retrieveRestaurant(address _restaurantAddress) public view returns (string memory, address, bool, uint[] memory) {
        Restaurant memory restaurant = addressToRestaurant[_restaurantAddress];
        return (restaurant.restaurantName, restaurant.restaurantAddress, restaurant.exist, restaurant.reviewsList);
    }
    

}