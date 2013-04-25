riak-graphite
=============

Riak-Graphite is an Erlang/OTP application that allows stats to be queried periodically and forwarded to a Graphite instance over UDP. It is run as an application alongside and a version of Riak 1.3.1 with riak-graphite included can be built from [the cd-riak1.3.1_graphite branch](https://github.com/basho/riak/tree/cd-riak1.3.1_graphite).

Configuration is done through a new section in the app.config file. The default values for this can be found below.

    {riak_graphite, [
        %% Enable or disable Hosted Grapite integration
        {enabled, false},

        %% Hosted graphite server name
        % {graphite_host, "carbon.hostedgraphite.com"},
    
        %% Hosted Graptite UDP port
        % {graphite_port, 2003},
    
        %% Local port to send stats from
        % {port, 20003},
    
        %% Stats collection interval in seconds
        % {interval, 10},

        %% Hosted Graphite Key
        % {key, ""},

        % Stats filtered out from feed to Hosted Graphite
        {filtered_stats, [riak_kv_stat_ts,
                          riak_pipe_stat_ts,
                          ring_num_partitions,
                          ring_creation_size,
                          sys_wordsize,
                          sys_thread_pool_size
                          ]}
                 ]}