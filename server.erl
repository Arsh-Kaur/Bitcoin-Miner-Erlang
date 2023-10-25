-module(server).
-import(string,[concat/2,slice/3]).
-import(miner,[mine/5]).
-export([start/0,listen/1,minerSupervisor/2]).

generateRandomString(Length)->
    get_random_string(Length,"abcdefghijklmnopqrstuvwxyz0123456789").

get_random_string(Length, AllowedChars) ->
    lists:foldl(fun(_, Acc) ->
                        [lists:nth(random:uniform(length(AllowedChars)),
                                   AllowedChars)]
                            ++ Acc
                end, [], lists:seq(1, Length)).


generateBaseInputString()->
    Ufid="khare.vibhor",
    RandomString=generateRandomString(10),
    BaseInputString=concat(Ufid,RandomString),
    BaseInputString.

listen(Difficulty)->
    receive
        {From,Messege}-> 
            io:format(" got Messege ~s ~n",[Messege ]);
        {From,ClientNode,requestNewBaseString}->
            {From, ClientNode} ! {newBaseString,{generateBaseInputString(),Difficulty}};
        {From,foundBtc,{InputString,GeneratedHash,Nonce}}->
            {_, Time1} = statistics(runtime),
            {_, Time2} = statistics(wall_clock),
            CPUTime = Time1 / 1000,
            Realtime = Time2 / 1000,
            if
                Realtime>0->
                    NumCoresUsed=CPUTime/Realtime;
                true->
                    NumCoresUsed=erlang:system_info(logical_processors_available)
            end,
            io:format("~s~p ~s ~n",[InputString,Nonce , GeneratedHash]),
            io:format("CPUtime=~p~n",[CPUTime]),
            io:format("Realtime=~p~n",[Realtime]),
            io:format("No. of Core Utilized(CPUtime/Runtime)=~p~n~n",[NumCoresUsed]);
        {initaiteMinerSupervisor}->
            Supervisor=spawn(server,minerSupervisor,[self(),0]),
            Supervisor ! {start,{Difficulty,generateBaseInputString()}}
    end,
        listen(Difficulty).


createMiners(_,0,_,_,_,_,_)->
    ok;
createMiners(Supervisor,NumWorkers,NumZeros,NonceStart,NonceStop,BaseInputString,Workload)->
    MinerId=NumWorkers,
    Miner=spawn_link(miner,mine,[Supervisor,NumZeros,NonceStart,NonceStop,BaseInputString,MinerId]),  
    createMiners(Supervisor,NumWorkers-1,NumZeros,NonceStop,NonceStop+Workload,BaseInputString,Workload).

minerSupervisor(ClientPid,CompletedWorkers)->
    NumWorkers=erlang:system_info(logical_processors_available),
    Workload=100000000 div NumWorkers,
    receive
        {start,{NumZeroes,BaseInputString}}->
            createMiners(self(),NumWorkers,NumZeroes,0,Workload+1,BaseInputString,Workload);
        {foundBtc,MinerId,{InputString,GeneratedHash,NonceStart}}->
            ClientPid ! {self(),foundBtc , {InputString,GeneratedHash,NonceStart}};
        {completedMining ,MinerId}->
            if
                CompletedWorkers==NumWorkers-1->
                   ClientPid ! {initaiteMinerSupervisor},
                   exit("all miners done");
                CompletedWorkers/=NumWorkers->
                    minerSupervisor(ClientPid,CompletedWorkers+1)
            end;
        {From , Messege}->io:format("Got ~s ~n",[Messege]);
        _->io:format("Messege not supported~n")
    end,
    minerSupervisor(ClientPid,CompletedWorkers).

start()->
    {ok, Difficulty} = io:read("Enter the number of Required Leading Zeroes: "),
    net_kernel:start([server, shortnames]),
    erlang:set_cookie(node(), btcMiner),
    register(btcserver, spawn(server, listen, [Difficulty])),
    statistics(runtime),
    statistics(wall_clock),
    btcserver ! {initaiteMinerSupervisor},
    io:format("Starting Local Miners~n").