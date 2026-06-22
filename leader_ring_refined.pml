#define N 7

chan ch[N] = [1] of { byte };

byte id[N];
bool leader[N];

byte leader_count = 0;

proctype Node(byte i) {
    byte msg;
    byte next;

    next = (i + 1) % N;

    ch[next]!id[i];

    do
    :: leader_count > 0 ->
        goto end_state

    :: atomic {
        ch[i]?<msg>;

        if
        :: leader_count > 0 ->
            goto end_state

        :: msg > id[i] && nfull(ch[next]) ->
            ch[i]?msg;
            ch[next]!msg

        :: msg < id[i] ->
            ch[i]?msg

        :: msg == id[i] ->
            ch[i]?msg;
            leader[i] = true;
            leader_count = leader_count + 1
        fi
    }
    od;

    end_state: skip
}

init {
    id[0] = 3;
    id[1] = 7;
    id[2] = 2;
    id[3] = 5;
    id[4] = 1;
    id[5] = 6;
    id[6] = 4;

    byte i;

    for (i : 0 .. N - 1) {
        leader[i] = false;
    }

    for (i : 0 .. N - 1) {
        run Node(i);
    }
}

ltl at_most_one {
    [] (leader_count <= 1)
}

ltl only_max_can_lead {
    [] (!leader[0] && !leader[2] && !leader[3] && !leader[4] && !leader[5] && !leader[6])
}

ltl leader_persistence {
    [] (leader[1] -> [] leader[1])
}

ltl eventually_some_leader {
    <> (leader_count > 0)
}

ltl eventually_max {
    <> leader[1]
}