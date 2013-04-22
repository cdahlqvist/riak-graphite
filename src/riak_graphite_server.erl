%% -------------------------------------------------------------------
%%
%% riak_graphite_server: Riak-Graphite Integration Server
%%
%% Copyright (c) 2013 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(riak_graphite_server).

-behaviour(gen_server).

%% Application callbacks
-export([start_link/0]).

-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {socket, host, port, interval, key, node}).

-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------    
init([]) ->
    {ok, Host} = application:get_env(riak_graphite, graphite_host),
    {ok, Port} = application:get_env(riak_graphite, graphite_port),
    {ok, LocalPort} = application:get_env(riak_graphite, port),
    Interval = case application:get_env(riak_graphite, interval) of
        undefined ->
            10;
        I when is_integer(I) andalso I > 0 ->
            I;
        _ ->
            10
    end,
    {ok, Key} = application:get_env(riak_graphite, key),
    {ok, Socket} = gen_udp:open(LocalPort, [{active, true}]),
    erlang:send_after(1000 * Interval, self(), gather_stats),
    Node = string:join(string:tokens(atom_to_list(node()), "@\."), "-"),
    {ok, #state{socket = Socket, host = Host, port = Port, interval = Interval, key = Key, node = Node}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({load_filter, FilterID}, _From, #state{bucket = Bucket} = State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({remove_cached_filter, FilterID}, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(gather_stats, #state{interval = Interval, host = Host, port = Port, socket = Socket} = State) ->
    case application:get_env(riak_graphite, enabled) of
        {ok, true} ->
            StatList = [{S, V} || {S, V} <- riak_kv_stat:get_stats(), is_integer(V)],
            send_stats_to_graphite(State, StatList),
            erlang:send_after(1000 * Interval, self(), check_expiry),
        _ ->
            erlang:send_after(1000 * Interval, self(), check_expiry),
    end.
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% hidden
send_stats_to_graphite(_, []) ->
    ok;
send_stats_to_graphite(#state{host = Host, port = Port, socket = Socket, key = Key} = State, [{S, V} | Rest]) ->
    Message = list_to_binary(io_lib:fwrite("~s.~s.~s ~p", [Key, Host, S, V])),
    gen_udp:send(Socket, Host, Port, Message),
    send_stats_to_graphite(State, Rest). 
