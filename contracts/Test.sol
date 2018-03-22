pragma solidity ^0.4.19;

contract Test {
 
    struct A {
        bool active;
        uint id; 
    }
    
     A[] public array;
    
    function checkStruct(uint index) public view {
        // A memory a = array[index];
         A storage a = array[index];
        
        require(a.active);
    }
    
    function addToStruct(uint id) public {
        A memory a = A(true, id);
        array.push(a);
    } 
}