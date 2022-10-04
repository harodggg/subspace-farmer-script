work_path=$(pwd)
node_num=1
echo $work_path
for ((i = 1; i <= ${node_num}; i++)); do

    config_path=$(pwd)/"sfarmer"$i
    # cd $config_path
    address=$(yq '.services.farmer.command[-3]' <docker-compose.yaml)
    address=$address","
    echo $address

done
