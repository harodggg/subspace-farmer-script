work_path=$(pwd)
node_num=100      #  修改节点数
node_name=sfarmer # 修改自己的节点名字
for ((i = 1; i <= ${node_num}; i++)); do

    config_path=$work_path/"$node_name"$i
    cd $config_path
    address=$(yq '.services.farmer.command[-3]' <docker-compose.yaml)
    if [ $i -eq $node_num ]; then
        address='"'$address'"'
    else
        address='"'$address'"'","
    fi
    
    echo $address

done
