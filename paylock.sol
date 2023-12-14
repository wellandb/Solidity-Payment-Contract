// SPDX-License-Identifier: UNLICESED
pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int disc;
    State st;
    int clock;
    int clockpoint; // Get's time of Collect_1_N
    address timeAdd;
    
    constructor(address clk) public {
        st = State.Working;
        disc = 0;
        clock = 0;
        timeAdd = clk;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
    }

    function collect_1_Y() public {
        require( st == State.Completed && clock < 4 );
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require( st == State.Completed && clock >= 4);
        st = State.Delay;
        disc = 5;
        clockpoint = clock;
    }

    function collect_2_Y() external {
        require( st == State.Delay && clock < clockpoint + 4);
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require( st == State.Delay && clock >= 8);
        st = State.Forfeit;
        disc = 0;
    }

    function tick() public returns(int){
        require(msg.sender == timeAdd);
        clock += 1;
        return(clock);
    }

}

contract Supplier {
    
    Paylock p;
    
    enum State { Working , Completed }
    
    State st;

    Rental r;

    enum Resource {Available, Taken}

    Resource res;
    
    constructor(address pp, Rental rent) public {
        p = Paylock(pp);
        st = State.Working;
        r = rent;
        res = Resource.Available;
    }
    
    function finish() external {
        require (st == State.Working);
        p.signal();
        st = State.Completed;
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function aquire_resource() public payable{
        require(res == Resource.Available);
        res = Resource.Taken;
        r.rent_out_resource{value: 1 wei}();
    }

    function return_resource() public payable{
        require(res == Resource.Taken);
        res = Resource.Available;
        r.retrieve_resource{value: 1 wei}();    
    }
        
    receive() external payable{}

}

contract Rental {
    
    address resource_owner;
    bool resource_available;
    
    constructor() public {
        resource_available = true;
    }
    
    function rent_out_resource() payable external {
        require(resource_available == true);
        //CHECK FOR PAYMENT HERE
        require(msg.value == 1 wei);
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external payable {
        require(resource_available == false && msg.sender == resource_owner);
        //RETURN DEPOSIT HERE
        (bool completed,) = resource_owner.call{value: 1 wei}("");
        require(completed == true);
        resource_available = true;
    }
    
}