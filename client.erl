-module(client).
-import(miner,[mine/5]).
-export([minerSupervisor/2,clientListen/2,start/3]).


requestServerForNewBaseString(ServerPid, ServerNode)->
    {ServerPid, ServerNode} ! {clientPid,node(),requestNewBaseString}.



clientListen(ServerPid, ServerNode)->
    receive
        {newBaseString,{BaseInputString,Difficulty}}->
            io:format("~s ~p ~n",[BaseInputString,Difficulty]),
            process_flag(trap_exit, true),
            Supervisor=spawn(client,minerSupervisor,[clientPid,0]),
            Supervisor ! {start,{Difficulty,BaseInputString}};
        {toClientWorkerFoundBtc,{InputString,GeneratedHash,Nonce}}->
            {ServerPid, ServerNode} ! {self(),foundBtc,{InputString,GeneratedHash,Nonce}};
        {supervisorCompletedWork}->
            requestServerForNewBaseString(ServerPid, ServerNode);
        {From,Messege}->
            io:format("got Messege ~s~n",[Messege]);
        _->io:format("Messege not supported~n")
    end,
    clientListen(ServerPid, ServerNode).

createMiners(_,0,_,_,_,_,_)->
    ok;
createMiners(Supervisor,NumWorkers,NumZeros,NonceStart,NonceStop,BaseInputString,Workload)->
    MinerId=NumWorkers,
    spawn_link(miner,mine,[Supervisor,NumZeros,NonceStart,NonceStop,BaseInputString,MinerId]),  
    createMiners(Supervisor,NumWorkers-1,NumZeros,NonceStop,NonceStop+Workload,BaseInputString,Workload).


minerSupervisor(ClientPid,CompletedWorkers)->
    NumWorkers=2*erlang:system_info(logical_processors_available),
    Workload=100000000 div NumWorkers,
    receive
        {start,{NumZeroes,BaseInputString}}->
            io:format("I got a base string ~s ~n",[BaseInputString]),
            createMiners(self(),NumWorkers,NumZeroes,0,Workload+1,BaseInputString,Workload);
        {foundBtc,MinerId,{InputString,GeneratedHash,NonceStart}}->
            io:format("I got a bitcoin from miner ~p ~n",[integer_to_list(MinerId)]),
            ClientPid ! {toClientWorkerFoundBtc , {InputString,GeneratedHash,NonceStart}};
        {completedMining ,MinerId}->
            io:format("~p is completed ~n",[integer_to_list(MinerId)]),
            io:format("~p total completed ~n",[integer_to_list(CompletedWorkers)]),
            if
                CompletedWorkers==NumWorkers-1->
                   ClientPid ! {supervisorCompletedWork},
                   io:format("Supervisor Out Bye ~p ~n",[self()]),
                   exit("all miners done");
                CompletedWorkers/=NumWorkers->
                    minerSupervisor(ClientPid,CompletedWorkers+1)
            end;
        {From , Messege}->io:format("Got ~s ~n",[Messege]);
        _->io:format("Messege not supported~n")
    end,
    minerSupervisor(ClientPid,CompletedWorkers).



start(ServerPid, ServerNode,ClientName)->
    register(clientPid, spawn(client, clientListen, [ServerPid, ServerNode])),
    net_kernel:start([ClientName, shortnames]),
    erlang:set_cookie(node(), btcMiner),
    net_kernel:connect_node(ServerNode),
    requestServerForNewBaseString(ServerPid, ServerNode).
    


