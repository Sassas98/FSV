#define N 7
#define CAP 1

chan ch[N] = [CAP] of { byte };

byte id[N];
bool leader[N];

byte leader_count = 0;

proctype Node(byte i) {
    byte msg;
    byte next;

    next = (i + 1) % N;

    ch[next]!id[i];

    do
    :: ch[i]?msg ->
        if
        :: msg > id[i] ->
            ch[next]!msg

        :: msg < id[i] ->
            skip

        :: msg == id[i] ->
            leader_count = leader_count + 1;
            leader[i] = true;
        fi
    od
}

init {
    byte i;

    for (i : 0 .. N - 1) {
        if
        :: (i % 2 == 0) ->
            id[i] = (i / 2) + 1
        :: else ->
            id[i] = N - (i / 2)
        fi
    }

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