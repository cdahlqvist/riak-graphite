%% -------------------------------------------------------------------
%%
%% riak_graphite: Interface for riak-graphite server application
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

-module(riak_graphite).

-export([is_enabled/0,
         enable/0,
         disable/0
        ]).

%% @doc Check to see if server is enabled.
-spec is_enabled() -> boolean().
is_enabled() ->
    case application:get_env(riak_graphite, enabled) of
        {ok, true} ->
            true;
        {ok, false} ->
            false;
        undefined ->
            false
    end.

%% @doc Enable RiakGraphite integration server.
-spec enable() -> ok.
enable() ->
    application:set_env(riak_graphite, enabled, true).

%% @doc Disable RiakGraphite integration server.
-spec disable() -> ok.
disable() ->
    application:set_env(riak_graphite, enabled, false).
    