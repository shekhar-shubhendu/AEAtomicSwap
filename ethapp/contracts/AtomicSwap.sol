pragma solidity ^0.5.11;

contract AtomicSwap {

    enum State { Empty, Initiator, Participant }

    struct Swap {
        uint initTimestamp;
        uint refundTime;
        bytes32 hashedSecret;
        bytes32 secret;
        address payable initiator;
        address payable participant;
        uint256 value;
        bool emptied;
        State state;
    }

    mapping(bytes32 => Swap) public swaps;

	event Refunded(uint _refundTime);
    event Redeemed(uint _redeemTime);
    event Participated(
        address _initiator,
        address _participator,
        bytes32 _hashedSecret,
        uint256 _value
    );
	event Initiated(
		uint _initTimestamp,
    	uint _refundTime,
    	bytes32 _hashedSecret,
    	address _participant,
    	address _initiator,
		uint256 _funds
	);

	modifier isRefundable(bytes32 _hashedSecret) {
	    require(block.timestamp > swaps[_hashedSecret].initTimestamp + swaps[_hashedSecret].refundTime);
	    require(swaps[_hashedSecret].emptied == false);
	    _;
	}

	modifier isRedeemable(bytes32 _hashedSecret, bytes32 _secret) {
	    require(keccak256(toBytes(_secret)) == _hashedSecret);
		require(block.timestamp < swaps[_hashedSecret].initTimestamp + swaps[_hashedSecret].refundTime);
	    require(swaps[_hashedSecret].emptied == false);
	    _;
	}

	modifier isInitiator(bytes32 _hashedSecret) {
	    require(msg.sender == swaps[_hashedSecret].initiator);
	    _;
	}

	modifier isNotInitiated(bytes32 _hashedSecret) {
	    require(swaps[_hashedSecret].state == State.Empty);
	    _;
	}

    // function stringToBytes(string memory source) public pure returns (bytes memory result){
    // bytes memory tempEmptyStringTest = bytes(source);
    //     if (tempEmptyStringTest.length == 0) {
    //         return 0x0;
    //     }

    //     assembly {
    //         result := mload(add(source, 32))
    //     }
    // }
 
    // function calculateRipemdHash(string memory _secret) public pure returns(string memory) {
    //     return ripemd160(toBytes(stringToBytes(_secret)));
    // }

    function toBytes(bytes32 _data) public pure returns(bytes memory) {
        return abi.encode(_data);
    }

	function initiate (uint _refundTime, bytes32 _hashedSecret, address payable _participant)
	    public
        payable
	    isNotInitiated(_hashedSecret)
	{
	    swaps[_hashedSecret].refundTime = _refundTime;
	    swaps[_hashedSecret].initTimestamp = block.timestamp;
	    swaps[_hashedSecret].hashedSecret = _hashedSecret;
	    swaps[_hashedSecret].participant = _participant;
	    swaps[_hashedSecret].initiator = msg.sender;
        swaps[_hashedSecret].state = State.Initiator;
        swaps[_hashedSecret].value = msg.value;
		emit Initiated(
			swaps[_hashedSecret].initTimestamp,
    		_refundTime,
    		_hashedSecret,
    		_participant,
    		msg.sender,
		 	msg.value
		);
	}

    function participate(uint _refundTime, bytes32 _hashedSecret, address payable _initiator)
        public
        payable
        isNotInitiated(_hashedSecret)
    {
        swaps[_hashedSecret].refundTime = _refundTime;
	    swaps[_hashedSecret].initTimestamp = block.timestamp;
        swaps[_hashedSecret].participant = msg.sender;
        swaps[_hashedSecret].initiator = _initiator;
        swaps[_hashedSecret].value = msg.value;
        swaps[_hashedSecret].hashedSecret = _hashedSecret;
        swaps[_hashedSecret].state = State.Participant;
        emit Participated(_initiator,msg.sender,_hashedSecret,msg.value);
    }
	
	function redeem(bytes32 _secret, bytes32 _hashedSecret)
        public
	    isRedeemable(_hashedSecret, _secret)
	{
        if(swaps[_hashedSecret].state == State.Participant){
            swaps[_hashedSecret].initiator.transfer(swaps[_hashedSecret].value);
        }
        if(swaps[_hashedSecret].state == State.Initiator){
            swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value);
        }
        swaps[_hashedSecret].emptied = true;
        emit Redeemed(block.timestamp);
        swaps[_hashedSecret].secret = _secret;
	}

	function refund(bytes32 _hashedSecret)
        public
	    isRefundable(_hashedSecret)
	{
	    if(swaps[_hashedSecret].state == State.Participant){
            swaps[_hashedSecret].participant.transfer(swaps[_hashedSecret].value);
        }
        if(swaps[_hashedSecret].state == State.Initiator){
            swaps[_hashedSecret].initiator.transfer(swaps[_hashedSecret].value);
        }
        swaps[_hashedSecret].emptied = true;
	    emit Refunded(block.timestamp);
	}
}