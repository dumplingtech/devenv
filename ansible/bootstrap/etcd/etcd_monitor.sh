#!/bin/bash

period=30 # number of seconds to sleep between each check iteration
iters=10 # number of problem iterations to start performing corrective action

# randomly delay this script startup so multiple monitors don't all run at the same time
sleep $(shuf -i 1-60 -n 1)

iter=0
while [ true ]; do
    sleep $period

    live_servers="$(etcdctl cluster-health 2> /dev/null |grep 'member [0-9a-f]* is healthy' |wc -l)"
    dead_members="$(etcdctl cluster-health 2> /dev/null |grep 'failed .* member' | awk -F 'member' '{print $2}' |awk '{print $1}')"

    slot=$((iter % iters))
    iter=$((iter + 1))

    live_hist[$slot]=$live_servers
    dead_hist[$slot]=$dead_members

    # remove dead member
    for member in $dead_members; do
        checked_iters=0
        for ((i=0; i<$iters; i++)); do
            if [[ ${dead_hist[$i]} == *"$member"* ]]; then
                checked_iters=$((checked_iters + 1))
            fi
        done
        if [ $checked_iters -ge $iters ]; then
            echo "Deleting dead cluster member $member"
            etcdctl member remove $member
            dead_hist=()
        fi
    done

    # report problem clusters
    bad_iters=0
    for ((i=0; i<$iters; i++)); do
        if [ ! -z ${live_hist[$i]} ] && [ ${live_hist[$i]} -lt 3 ]; then
            bad_iters=$((bad_iters + 1))
        fi
    done
    if [ $bad_iters -ge $iters ]; then
        curl -XPOST $ALERT_URL -d '{ "text": "'"ETCD cluster in ${EC2_REGION} has only $live_servers members"'" }'
        live_hist=()
    fi

done
