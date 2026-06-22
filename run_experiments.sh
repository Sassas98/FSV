#!/bin/bash

MODEL="leader_ring_refined.pml"
RESULTS="results.csv"
WORKDIR="spin_experiments_tmp"

NS="6 7 8 9 10 11 12 13"
CAPS="1 2 3"

mkdir -p "$WORKDIR"

printf "model,N,CAP,state_vector,stored,matched,transitions,depth,errors,memory_mb,time_s\n" > "$RESULTS"

for N in $NS
do
  for CAP in $CAPS
  do
    TMP="$WORKDIR/refined_N${N}_CAP${CAP}.pml"
    LOG="$WORKDIR/log_N${N}_CAP${CAP}.txt"

    echo "Running N=$N CAP=$CAP..."

    sed -E \
      -e "s/^[[:space:]]*#define[[:space:]]+N[[:space:]]+.*/#define N ${N}/" \
      -e "s/^[[:space:]]*#define[[:space:]]+CAP[[:space:]]+.*/#define CAP ${CAP}/" \
      "$MODEL" > "$TMP"

    rm -f pan pan.* *.trail

    spin -a "$TMP" > /dev/null
    gcc -O2 -o pan pan.c

    ./pan -m1000000 > "$LOG"

    STATE_LINE=$(grep -m1 "^State-vector" "$LOG")

    STATE_VECTOR=$(echo "$STATE_LINE" | awk '{print $2}')
    DEPTH=$(echo "$STATE_LINE" | sed -E 's/.*depth reached[[:space:]]+([0-9]+),.*/\1/')
    ERRORS=$(echo "$STATE_LINE" | sed -E 's/.*errors:[[:space:]]+([0-9]+).*/\1/')

    STORED=$(awk '/^[[:space:]]*[0-9]+[[:space:]]+states, stored/ {print $1; exit}' "$LOG")
    MATCHED=$(awk '/^[[:space:]]*[0-9]+[[:space:]]+states, matched/ {print $1; exit}' "$LOG")
    TRANSITIONS=$(awk '/^[[:space:]]*[0-9]+[[:space:]]+transitions/ {print $1; exit}' "$LOG")

    MEMORY=$(awk '/total actual memory usage/ {print $1; exit}' "$LOG")
    TIME=$(awk '/elapsed time/ {print $4; exit}' "$LOG")

    STATE_VECTOR=${STATE_VECTOR:-NA}
    DEPTH=${DEPTH:-NA}
    ERRORS=${ERRORS:-NA}
    STORED=${STORED:-NA}
    MATCHED=${MATCHED:-NA}
    TRANSITIONS=${TRANSITIONS:-NA}
    MEMORY=${MEMORY:-NA}
    TIME=${TIME:-NA}

    printf "refined,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
      "$N" "$CAP" "$STATE_VECTOR" "$STORED" "$MATCHED" "$TRANSITIONS" "$DEPTH" "$ERRORS" "$MEMORY" "$TIME" \
      >> "$RESULTS"
  done
done

echo ""
echo "Done. Results written to $RESULTS"
echo "Logs are in $WORKDIR/"