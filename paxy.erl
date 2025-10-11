-module(paxy).
-export([start/1, stop/0, stop/1, crash/1, crash/0]).

-define(RED, {255,0,0}).
-define(BLUE, {0,0,255}).
-define(GREEN, {0,255,0}).
-define(YELLOW, {255,255,0}).
-define(CYAN, {124,163,214}).

% Sleep is a list with the initial sleep time for each proposer
start(Sleep) ->
  AcceptorNames = ["Homer", "Marge", "Bart", "Lisa", "Maggie", "Apu", "Jeff", "Burns", "Perro", "Bola de Nieve"],
  AccRegister = [homer, marge, bart, lisa, maggie, apu, jeff, burns, perro, boladenieve],
  ProposerNames = [{"Fry", ?RED}, {"Bender", ?GREEN}, {"Leela", ?BLUE}, {"Farnsworth", ?YELLOW}, {"Kiff", ?CYAN}],
  PropInfo = [{fry, ?RED}, {bender, ?GREEN}, {leela, ?BLUE}, {farnsworth, ?YELLOW}, {kiff, ?CYAN}],
  register(gui, spawn(fun() -> gui:start(AcceptorNames, ProposerNames) end)),
  gui ! {reqState, self()},
  % crash(homer),
  receive
    {reqState, State} ->
      {AccIds, PropIds} = State,
      start_acceptors(AccIds, AccRegister),
      spawn(fun() ->
        Begin = erlang:monotonic_time(),
        start_proposers(PropIds, PropInfo, AccRegister, Sleep, self()),
        wait_proposers(length(PropIds)),
        End = erlang:monotonic_time(),
        Elapsed = erlang:convert_time_unit(End-Begin, native, millisecond),
        io:format("[Paxy] Total elapsed time: ~w ms~n", [Elapsed])
      end)
  end.

start_acceptors(AccIds, AccReg) ->
  case AccIds of
    [] ->
      ok;
    [AccId|Rest] ->
      [RegName|RegNameRest] = AccReg,
      register(RegName, acceptor:start(RegName, AccId)),
      start_acceptors(Rest, RegNameRest)
  end.

start_proposers(PropIds, PropInfo, Acceptors, Sleep, Main) ->
  case PropIds of
    [] ->
      ok;
    [PropId|Rest] ->
      [{RegName, Colour}|RestInfo] = PropInfo,
      [FirstSleep|RestSleep] = Sleep,
      proposer:start(RegName, Colour, Acceptors, FirstSleep, PropId, Main),
      start_proposers(Rest, RestInfo, Acceptors, RestSleep, Main)
  end.

wait_proposers(0) ->
  ok;
wait_proposers(N) ->
  receive
    done ->
      wait_proposers(N-1)
  end.

stop() ->
  stop(homer),
  stop(marge),
  stop(bart),
  stop(lisa),
  stop(maggie),
  stop(apu),
  stop(jeff),
  stop(burns),
  stop(perro),
  stop(boladenieve),
  stop(gui).

stop(Name) ->
  case whereis(Name) of
    undefined ->
      ok;
    Pid ->
      Pid ! stop
  end.

crash(Name) ->
  case whereis(Name) of
    undefined ->
      ok;
    Pid ->
      unregister(Name),
      exit(Pid, "crash"),
      pers:open(Name),
      {_, _, _, Pn} = pers:read(Name),
      Pn ! {updateAcc, "Voted: CRASHED", "Promised: CRASHED", {0,0,0}},
      pers:close(Name),
      timer:sleep(3000),
      register(Name, acceptor:start(Name, na))
  end.

crash() ->
  case whereis(homer) of
    undefined ->
      io:format("[CRASH] Name ~w undefined~n", [homer]),
      ok;
    Pid ->
      io:format("[CRASH] Name ~w defined~n", [homer]),
      unregister(homer),
      exit(Pid, "crash"),
      pers:open(homer),
      {_, _, _, Pn} = pers:read(homer),
      Pn ! {updateAcc, "Voted: CRASHED", "Promised: CRASHED", {0,0,0}},
      pers:close(homer),
      timer:sleep(3000),
      register(homer, acceptor:start(homer, na))
  end.
