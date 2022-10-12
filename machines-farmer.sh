num_per_farmer=5

node_name="anode"
end_machine=12

start_machine=1
work_path=$(pwd)

upgrade_node() {
    export NAME="node.labels.name =="$1
    yq -i '.services.farmer.deploy.placement.constraints[0]=env(NAME)' ./swarm-farmer.yaml
    unset NAME

}

upgrade_per_farmers() {
    jq --arg num $1 ".node_num=$num" ./swarm.json >tmp.$$.json && mv ./tmp.$$.json ./swarm.json
}

run() {
    # upgrade_per_famers $num_per_farmer
    for ((i = $start_machine; i <= $end_machine; i++)); do
        num=$((num_per_farmer * i))
        upgrade_per_farmers $num
        echo $((num_per_farmer * i))
        name=$node_name$i
        echo $name
        upgrade_node $name
        $work_path/run-farmer.sh swarm create
        sleep 2
    done
}

run
