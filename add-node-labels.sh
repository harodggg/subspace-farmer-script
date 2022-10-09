nodes=("vmi977845.contaboserver.net
    vmi977846.contaboserver.net
    vmi977847.contaboserver.net
    vmi977849.contaboserver.net
    vmi977852.contaboserver.net")
seq=7
node_name="anode"
for node in $nodes; do
    seq=$((seq + 1))
    name=$node_name$seq
    docker_swarm node update --label-add name=$name $node
done
