/*

Etherandom v1.0 [Core]

Copyright (c) 2016, Etherandom [etherandom.com]
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the 
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL ETHERANDOM BE LIABLE FOR ANY 
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

*/

contract EtherandomProxy {
  address owner;
  address etherandom;
  address callback;

  function EtherandomProxy() {
    owner = msg.sender;
  }

  modifier onlyAdmin {
    if (msg.sender != owner) throw;
    _
  }

  function getContractAddress() public constant returns (address _etherandom) {
    return etherandom;
  }
  
  function setContractAddress(address newEtherandom) onlyAdmin {
    etherandom = newEtherandom;
  }

  function getCallbackAddress() public constant returns (address _callback) {
    return callback;
  }
  
  function setCallbackAddress(address newCallback) onlyAdmin {
    callback = newCallback;
  }
  
  function kill() onlyAdmin {
    selfdestruct(owner);
  }
}

contract AmIOnTheFork{
  function forked() constant returns(bool);
}

contract Etherandom {
  address owner;
  uint seedPrice;
  uint execPrice;
  uint gasPrice;
  uint minimumGasLimit;
  mapping(address => uint) seedc;
  mapping(address => uint) execc;

  address constant AmIOnTheForkAddress = 0x2bd2326c993dfaef84f696526064ff22eba5b362;

  event SeedLog(address sender, bytes32 seedID, uint gasLimit);
  event ExecLog(address sender, bytes32 execID, uint gasLimit, bytes32 serverSeedHash, bytes32 clientSeed, uint cardinality);

  function Etherandom() {
    owner = msg.sender;
  }

  modifier onlyAdmin {
    if (msg.sender != owner) throw;
    _
  }

  function getSeedPrice() public constant returns (uint _seedPrice) {
    return seedPrice;
  }

  function getExecPrice() public constant returns (uint _execPrice) {
    return execPrice;
  }

  function getGasPrice() public constant returns (uint _gasPrice) {
    return gasPrice;
  }

  function getMinimumGasLimit() public constant returns (uint _minimumGasLimit) {
    return minimumGasLimit;
  }

  function getSeedCost(uint _gasLimit) public constant returns (uint _cost) {
    uint cost = seedPrice + (_gasLimit * gasPrice);
    return cost;
  }

  function getExecCost(uint _gasLimit) public constant returns (uint _cost) {
    uint cost = execPrice + (_gasLimit * gasPrice);
    return cost;
  }

  function kill() onlyAdmin {
    selfdestruct(owner);
  }

  function setSeedPrice(uint newSeedPrice) onlyAdmin {
    seedPrice = newSeedPrice;
  }

  function setExecPrice(uint newExecPrice) onlyAdmin {
    execPrice = newExecPrice;
  }

  function setGasPrice(uint newGasPrice) onlyAdmin {
    gasPrice = newGasPrice;
  }

  function setMinimumGasLimit(uint newMinimumGasLimit) onlyAdmin {
    minimumGasLimit = newMinimumGasLimit;
  }

  function withdraw(address addr) onlyAdmin {
    addr.send(this.balance);
  }

  function () {
    throw;
  }

  modifier costs(uint cost) {
    if (msg.value >= cost) {
      uint diff = msg.value - cost;
      if (diff > 0) msg.sender.send(diff);
      _
    } else throw;
  }

  function seed() returns (bytes32 _id) {
    return seedWithGasLimit(getMinimumGasLimit());
  }

  function seedWithGasLimit(uint _gasLimit) costs(getSeedCost(_gasLimit)) returns (bytes32 _id) {
    if (_gasLimit > block.gaslimit || _gasLimit < getMinimumGasLimit()) throw;
    bool forkFlag = AmIOnTheFork(AmIOnTheForkAddress).forked();
    _id = sha3(forkFlag, this, msg.sender, seedc[msg.sender]);
    seedc[msg.sender]++;
    SeedLog(msg.sender, _id, _gasLimit);
    return _id;
  }

  function exec(bytes32 _serverSeedHash, bytes32 _clientSeed, uint _cardinality) returns (bytes32 _id) {
    return execWithGasLimit(_serverSeedHash, _clientSeed, _cardinality, getMinimumGasLimit());
  }

  function execWithGasLimit(bytes32 _serverSeedHash, bytes32 _clientSeed, uint _cardinality, uint _gasLimit) costs(getExecCost(_gasLimit)) returns (bytes32 _id) {
    if (_gasLimit > block.gaslimit || _gasLimit < getMinimumGasLimit()) throw;
    bool forkFlag = AmIOnTheFork(AmIOnTheForkAddress).forked();
    _id = sha3(forkFlag, this, msg.sender, execc[msg.sender]);
    execc[msg.sender]++;
    ExecLog(msg.sender, _id, _gasLimit, _serverSeedHash, _clientSeed, _cardinality);
    return _id;
  }
}
