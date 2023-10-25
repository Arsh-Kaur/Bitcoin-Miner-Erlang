-module(miner).
-import(string,[concat/2,slice/3]).
-export([mine/6]).


generateMatch(0,Match)->
    Match;
generateMatch(N,Match)when N > 0->
    generateMatch(N-1,concat(Match,"0")).



checkNumberOfZeroes(Num,InputString)->
    LeadingZeroes=slice(InputString,0,Num),
    StringToMatch=generateMatch(Num,""),
    string:equal(LeadingZeroes,StringToMatch).




mine(From,NumZeros,NonceStart,NonceStop,BaseInputString,MinerId)->
    if
        NonceStart/=NonceStop->
            InputString=concat(BaseInputString,integer_to_list(NonceStart)),
            GeneratedHash=io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,InputString))]),
            Found=checkNumberOfZeroes(NumZeros,GeneratedHash),
            if 
                Found==true->
                   From ! {foundBtc,MinerId,{InputString,GeneratedHash,NonceStart}},
                   mine(From,NumZeros,NonceStart+1,NonceStop,BaseInputString,MinerId);
                Found==false->
                    mine(From,NumZeros,NonceStart+1,NonceStop,BaseInputString,MinerId)
            end;
        NonceStart==NonceStop->
            From ! {completedMining ,MinerId};
        true->
            From ! "Something went wrong in miner"
    end.
