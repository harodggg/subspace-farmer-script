num_per_farmer=5
node_name="anode"
end_machine=12
start_machine=1
work_path=$(pwd)

upgrade_node() {
    export NAME=$1
    yq -i '.services.farmer.deploy.placement.constraints[0]="node.labels.name == env(NAME)"' ./swarm-farmer.yaml
    unset NAME

}

upgrade_per_famers() {
    jq --arg $1 $num ".node_num=$num" ./swarm.json | sponge swarm.json
}

run() {
    # upgrade_per_famers $num_per_farmer
    for ((i = $start_machine; i <= $end_machine; i++)); do
        upgrade_node $((num_per_farmer * i))
        echo $((num_per_farmer * i))
        name=$node_name$i
        echo $name
        upgrade_node $name
        $(./run-farmer.sh create only-farmer)
    done
}

run
