# Bitcoin-Miner-Erlang

The problem was to mine bitcoin which can be any random string that, when “hashed” produces an output smaller than a given target value (in practice, the comparison values have leading 0’s). It is very difficult to mine a bitcoin as the number of zeros increase on a single computer. \
Solution - \
Created a distributed application based on the Erlang actor model in which multiple actors distributed over various client nodes generated hashed strings. The values are compared and if a bitcoin is found, it is sent back to server. \
The server and clients each run (4*No.of Cores) processes to ensure that all the cores are utilised completely. The string generation is an iterative approach where we are generating a workload of 10,000,000 for each process on the machine. Each process will be provided a start number and workload. The process will then mine for the bitcoin between start number and the workload. \
Random strings are generated that are composed of alphanumeric characters. They are used to create a random component for the input string. The generated string is concatenated with a fixed component ("arsshdeep.kaur") to create a base input string. When a process in the server/client completes a given workload, it send a requests to server for the new workload. if a bitcoin is found, it is sent back to server. 

The 3 components of this project are describer below in detail:

Server Module (server.erl): The server module handles the central control of the Bitcoin mining process. It listens for messages from client nodes and manages the mining operation. It generates and distributes base strings for mining, keeps track of miner statistics, and provides overall coordination for the distributed system.

Client Module (client.erl): The client module interacts with the server to request base strings for mining. It also manages a supervisor for miner processes. When a miner discovers a valid Bitcoin, the client module relays the information to the server. This module serves as a bridge between the server and the miner processes.

Miner Module (miner.erl): The miner module represents individual miner processes responsible for Bitcoin mining. Each miner works on a specific nonce range, incrementing nonces and hashing combinations with a base input string. When a miner successfully mines a Bitcoin with the required number of leading zeros, it communicates the finding to the client. This module embodies the core mining algorithm.
