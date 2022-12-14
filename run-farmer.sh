#!/bin/bash
#   Copyright 2019-2022 Harodggg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

IMAGE_NODE=""
IMAGE_FARMER=""
FARMER_DIR=""
PLOT_SIZE=""
NODE_NAME=""
NODE_NUM=""
NODE_RPC=""

ADDRESS=()
NODE_AVAILABLE_PORT=()
FARMER_AVAILABLE_PORT=()
RPC_AVAILABLE_PORT=()

### Check Funcions
check_info() {
	echo "Does $* exist ?"
}

check_docker() {
	num=$(is_package_exist docker)
	if [ $num -eq 0 ]; then
		msg_success "Exist: [docker]"
	else
		msg_error 'No Exist: docker'
		install_docker
	fi

	# version_docker=$(docker --version | awk '{split($0,a,","); print a[1]}' | sed "s/Docker version //g")
}

check_only_farmer_network() {
	num=$(sudo docker network ls | grep farmer-network | wc -l)
	if [ $num -eq 0 ]; then
		msg_error "No Exist: farmer-network"
		network_id=sudo docker network create farmer-network
		msg_info "Starting building farmer-network"
		msg_success "new farmer-network is $network_id"

	else
		msg_success "Exist: farmer-network"
	fi
}

check_docker_compose() {
	num=$(is_package_exist docker-compose)
	if [ $num -eq 0 ]; then
		msg_success "Exist: [docker-compose]"
	else
		msg_error 'No Exist: docker-compose'
		install_docker_compose
	fi
}

check() {
	num=$(is_package_exist $1)
	if [ $num -eq 0 ]; then
		msg_success "Exist: [$1]"
	else
		msg_error "No Exist: [$1]"
		msg_info "Install: [$1]"
		install_package $1 || $($2)
	fi
}

check_netstat() {
	num=$(is_package_exist netstat)
	if [ $num -eq 0 ]; then
		msg_success "Exist: [netstat]"
	else
		msg_error "No Exist: [netstat]"
		msg_info "Install: [netstat]"
		install_netstat
	fi

}

check_snap() {
	case $(get_os) in
	"OSX")
		msg_success "No need snapd"
		;;

	"LINUX")
		num=$(is_package_exist snap)
		if [ $num -eq 0 ]; then
			msg_success "Exist: [snap]"
		else
			msg_error "No Exist: [snap]"
			msg_info "Install: [snap]"
			install_package snapd
		fi
		;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
}

check_environment() {
	msg_info "Check [1]: $(check_info docker)"
	check_docker
	msg_info "Check [2]: $(check_info docker-compose)"
	check_docker_compose

	msg_info "Check[3]: $(check_info snapd)"
	check_snap
	msg_info "Check [4]: $(check_info jq)"
	check jq
	msg_info "Check [5]: $(check_info yq)"
	check yq
	msg_info "Check [6]: $(check_info netstat)"
	check_netstat

}

check_port() {
	result=$(netstat -atnl | grep $* | wc -l)
	if [ $result -ne 0 ]; then
		echo "1"
	else
		echo "0"
	fi
}
check_dir() {
	num=$(is_exist_dir $*)
	if [ $num -eq 0 ]; then
		msg_error "The farmer directory already exists, please confirm! ! !"
		echo O
	else
		msg_success "The farmer directory does not exist, we will create it again"
		echo 1
	fi
}

upgrade_package() {
	case $(get_os) in
	"OSX") brew update && brew upgrade ;;
	"LINUX") sudo apt-get -y update && sudo apt-get -y upgrade ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
}

is_package_exist() {
	if type $1 >/dev/null 2>&1; then
		echo 0
	else
		echo 1
	fi
}

### Install Functions
install_docker_pre() {
	set +e
	sudo apt-get -y remove docker docker-engine docker.io containerd runc || true
	sudo apt-get -y install ca-certificates curl gnupg lsb-release
	sudo apt-get -y install pass gnupg2
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
	set -eu

}

install_docker() {
	case $(get_os) in
	"OSX") msg_warn "You should already have docker and docker-compose installed, if not, install them manually" ;;
	"LINUX") install_docker_pre ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac

	# add sources and gpg keys
	upgrade_package
	install_package docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

install_docker_compose() {
	sudo apt-get -y remove docker-compose && sudo snap remove docker-compose
	sudo wget https://github.com/docker/compose/releases/download/v2.11.1/docker-compose-linux-x86_64 -O /usr/bin/docker-compose && sudo chmod +x /usr/bin/docker-compose
}

install_package() {
	case $(get_os) in
	"OSX") brew install $1 ;;
	"LINUX") sudo apt -y install $1 || sudo snap install $1 ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
}

install_netstat() {
	install_package net-tools
}

is_exist_dir() {
	if [ ! -d $* ]; then
		echo 1
	else
		echo 0
	fi
}

get_all_dir() {
	dir=$(ls -l $* | awk '/^d/ {print $NF}')
}

get_os() {
	case "$OSTYPE" in
	solaris*) echo "SOLARIS" ;;
	darwin*) echo "OSX" ;;
	linux*) echo "LINUX" ;;
	bsd*) echo "BSD" ;;
	msys*) echo "WINDOWS" ;;
	*) echo "unknown: $OSTYPE" ;;
	esac
}
get_current_dir() {
	path=$(pwd)
	echo $path
}

get_parent_dir() {
	path=$(dirname "$PWD")
	echo $path

}

usage() {
	echo "Usage: $(basename $0) options (init | create [only-farmer] | swarm [create | delete | upgrade] | stop | detele | upgrade)"
}

### Log Functions
echo_log() {
	now=$(date +"[%Y/%m/%d %H:%M:%S]")
	echo -e "\033[1;$1m${now}$2\033[0m"

}

msg_debug() {
	echo_log 35 "[Build] ====> $*"
}

msg_error() {
	echo_log 31 "[Error] ====> $*"
}

msg_success() {
	echo_log 32 "[Success] ====> $*"
}

msg_warn() {
	echo_log 33 "[Using] ====> $*"
}

msg_info() {
	echo_log 34 "[Info] ====> $*"
}

fatal_error() {
	msg_error "Fatal error, cannot be fixed automatically, please contact the author! ! !"
}

copy_configure_file() {
	cp $WORK_DIR/docker-compose.yaml $WORK_DIR/$FAMER_DIR
}

read_config() {
	#ADDRESS=$(jq -rc .address[0] $*)
	#echo $ADDRESS
	#echo $ADDRESS
	NODE_NUM=$(jq -rc .node_num $*)
	for ((i = 0; i < ${NODE_NUM}; i++)); do
		ADDRESS[$i]=$(jq -rc .address[$i] $*)
		#echo ${ADDRESS[$i]}
	done
	#echo $FAMER_NUM
	PLOT_SIZE=$(jq -rc .plot_size $*)
	#echo $PLOT_SIZE
	NODE_AVAILABLE_PORT[0]=$(jq -rc .node_available_port[0] $*)
	NODE_AVAILABLE_PORT[1]=$(jq -rc .node_available_port[1] $*)
	#echo $NODE_AVAILABLE_PORT

	FARMER_AVAILABLE_PORT[0]=$(jq -rc .farmer_available_port[0] $*)
	FARMER_AVAILABLE_PORT[1]=$(jq -rc .farmer_available_port[1] $*)

	#echo $FARMER_AVAILABLE_PORT
	NODE_NAME=$(jq -rc .node_name $*)
	#echo $NODE_NAME
	IMAGE_FARMER=$(jq -rc .farmer_image $*)
	#echo $IMAGE_FARMER
	IMAGE_NODE=$(jq -rc .node_image $*)
	#echo $IMAGE_NODE
	#show_config
}

read_node_config() {
	#ADDRESS=$(jq -rc .address[0] $*)
	#echo $ADDRESS
	#echo $ADDRESS
	#FARMER_NUM=$(jq -rc .farmer_num $*)
	#for ((i = 0; i < ${FARMER_NUM}; i++)); do
	#	ADDRESS[$i]=$(jq -rc .address[$i] $*)
	#	#echo ${ADDRESS[$i]}
	#done
	#echo $FAMER_NUM
	PLOT_SIZE=$(jq -rc .plot_size $*)
	#echo $PLOT_SIZE
	NODE_AVAILABLE_PORT[0]=$(jq -rc .node_available_port[0] $*)
	NODE_AVAILABLE_PORT[1]=$(jq -rc .node_available_port[1] $*)
	#echo $NODE_AVAILABLE_PORT

	RPC_AVAILABLE_PORT[0]=$(jq -rc .rpc_available_port[0] $*)
	RPC_AVAILABLE_PORT[1]=$(jq -rc .rpc_available_port[1] $*)
	#FARMER_AVAILABLE_PORT[0]=$(jq -rc .farmer_available_port[0] $*)
	#FARMER_AVAILABLE_PORT[1]=$(jq -rc .farmer_available_port[1] $*)

	#echo $FARMER_AVAILABLE_PORT
	NODE_NAME=$(jq -rc .node_name $*)
	#echo $NODE_NAME
	#IMAGE_FARMER=$(jq -rc .farmer_image $*)
	#echo $IMAGE_FARMER
	IMAGE_NODE=$(jq -rc .node_image $*)
	#echo $IMAGE_NODE
	#show_config
	NODE_NUM=$(jq -rc .node_num $*)
}

read_farmer_config() {
	#ADDRESS=$(jq -rc .address[0] $*)
	#echo $ADDRESS
	#echo $ADDRESS
	NODE_NUM=$(jq -rc .node_num $*)
	for ((i = 0; i < ${NODE_NUM}; i++)); do
		ADDRESS[$i]=$(jq -rc .address[$i] $*)
		#echo ${ADDRESS[$i]}
	done
	#echo $FAMER_NUM
	PLOT_SIZE=$(jq -rc .plot_size $*)
	#echo $PLOT_SIZE
	#NODE_AVAILABLE_PORT[0]=$(jq -rc .node_available_port[0] $*)
	#NODE_AVAILABLE_PORT[1]=$(jq -rc .node_available_port[1] $*)
	#echo $NODE_AVAILABLE_PORT

	FARMER_AVAILABLE_PORT[0]=$(jq -rc .farmer_available_port[0] $*)
	FARMER_AVAILABLE_PORT[1]=$(jq -rc .farmer_available_port[1] $*)

	#echo $FARMER_AVAILABLE_PORT
	NODE_NAME=$(jq -rc .node_name $*)
	echo $NODE_NAME
	IMAGE_FARMER=$(jq -rc .farmer_image $*)
	#echo $IMAGE_FARMER
	#IMAGE_NODE=$(jq -rc .node_image $*)
	#echo $IMAGE_NODE
	NODE_RPC=$(jq -rc .node_rpc $*)
	echo $NODE_RPC
	#show_config
}

read_swarm_config() {
	#ADDRESS=$(jq -rc .address[0] $*)
	#echo $ADDRESS
	#echo $ADDRESS
	NODE_NUM=$(jq -rc .node_num $*)
	for ((i = 0; i < ${NODE_NUM}; i++)); do
		ADDRESS[$i]=$(jq -rc .address[$i] $*)
		echo ${ADDRESS[$i]}
	done
	#echo $FAMER_NUM
	PLOT_SIZE=$(jq -rc .plot_size $*)
	echo $PLOT_SIZE

	NODE_NAME=$(jq -rc .node_name $*)
	echo $NODE_NAME

	IMAGE_FARMER=$(jq -rc .farmer_image $*)
	echo $IMAGE_FARMER

	NODE_RPC=$(jq -rc .node_rpc $*)
	echo $NODE_RPC
	#show_config

}

show_config() {
	echo address: $ADDRESS
	echo plat_size: $PLOT_SIZE
	echo node_port_base: $NODE_AVAILABLE_PORT
	echo framer_port_node: $FARMER_AVAILABLE_PORT
	echo node_name: $NODE_NAME
	echo iamge_farmer: $IMAGE_FARMER
	echo image_node: $IMAGE_NODE

}

### Create Farmer funtion
# farmer $1=parent-path $2=dir-name+path $3=address $4=node-name $5=plat-size $6=node-?????? $7=farmer-??????
create_farmer() {
	#echo $PLOT_SIZE
	work_dir=$(pwd)
	#echo $work_dir

	mkdir $1

	#echo $(pwd)/docker-compose.yaml
	cp $(pwd)/docker-compose.yaml $1

	sleep 0.5

	export SNI=$IMAGE_NODE
	yq -i '.services.node.image=env(SNI)' $1/docker-compose.yaml
	unset SNI

	export SFI=$IMAGE_FARMER
	yq -i '.services.farmer.image=env(SFI)' $1/docker-compose.yaml
	unset SFI

	export node_name=$2
	yq -i '.services.node.command[-1]=env(node_name)' $1/docker-compose.yaml
	unset node_name

	export node_path=$1:/var/subspace:rw
	yq -i '.services.node.volumes[0]=env(node_path)' $1/docker-compose.yaml
	unset node_path

	export farmer_path=$1:/var/subspace:rw
	yq -i '.services.farmer.volumes[0]=env(farmer_path)' $1/docker-compose.yaml
	unset farmer_path

	export plot_size=$PLOT_SIZE
	yq -i '.services.farmer.command[-1]=env(plot_size)' $1/docker-compose.yaml
	unset plot_size

	export address=$5
	yq -i '.services.farmer.command[-3]=env(address)' $1/docker-compose.yaml
	unset address

	export node_port="0.0.0.0:$3:30333"
	yq -i '.services.node.ports[0]=env(node_port)' $1/docker-compose.yaml
	unset node_port

	export farmer_port="0.0.0.0:$4:40333"
	yq -i '.services.farmer.ports[0]=env(farmer_port)' $1/docker-compose.yaml
	unset farmer_port

	cd $1

	sudo docker-compose up -d || true

	cd $work_dir
	#echo $(pwd)
}

upgrade_farmer() {
	#echo $PLOT_SIZE
	work_dir=$(pwd)
	#echo $work_dir

	#mkdir $1

	#echo $(pwd)/docker-compose.yaml
	#	cp $(pwd)/docker-compose.yaml $1
	cd $1

	sleep 0.5

	export SNI=$IMAGE_NODE
	yq -i '.services.node.image=env(SNI)' $1/docker-compose.yaml
	unset SNI

	export SFI=$IMAGE_FARMER
	yq -i '.services.farmer.image=env(SFI)' $1/docker-compose.yaml
	unset SFI

	export node_name=$2
	yq -i '.services.node.command[-1]=env(node_name)' $1/docker-compose.yaml
	unset node_name

	export node_path=$1:/var/subspace:rw
	yq -i '.services.node.volumes[0]=env(node_path)' $1/docker-compose.yaml
	unset node_path

	export farmer_path=$1:/var/subspace:rw
	yq -i '.services.farmer.volumes[0]=env(farmer_path)' $1/docker-compose.yaml
	unset farmer_path

	export plot_size=$PLOT_SIZE
	yq -i '.services.farmer.command[-1]=env(plot_size)' $1/docker-compose.yaml
	unset plot_size

	export address=$5
	yq -i '.services.farmer.command[-3]=env(address)' $1/docker-compose.yaml
	unset address

	export node_port="0.0.0.0:$3:30333"
	yq -i '.services.node.ports[0]=env(node_port)' $1/docker-compose.yaml
	unset node_port

	export farmer_port="0.0.0.0:$4:40333"
	yq -i '.services.farmer.ports[0]=env(farmer_port)' $1/docker-compose.yaml
	unset farmer_port

	cd $1

	sudo docker-compose up -d || true

	cd $work_dir
	#echo $(pwd)

}

delete_dir() {
	rm -rf $*
}

stop_all_farmer() {
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	node_num=1
	msg_info "Config: Reading $1"
	"$2" $(get_current_dir)/$1
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/$1\""

	msg_info "Stopping: Start stopping all node"
	node_num=$NODE_NUM

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer stopping==================="
		msg_info "Node Sequence->[stop]: We start stopping the farmer-[$i]"
		msg_info "Node Name->[stop]: ${node_name}"
		msg_info "Node Path->[stop]: ${node_path}"

		if [ -d "$node_path" ]; then
			work_dir=$(pwd)

			cd ${parent_path}/${node_name}
			sudo docker-compose stop
			msg_success "...->[stop]:We have successfully stopped $node_path"
			cd $work_dir
		fi

	done

}

upgrade_all_framer() {
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	dir_name=""
	node_num=1
	stop_all_farmer $1 $2
	msg_info "Config: Reading config.json"
	"$2" $(get_current_dir)/$1
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/config.json\""

	msg_info "Building: Start upgrading node"
	node_num=$NODE_NUM
	msg_info "Farmer Num: We will upgrading \"${node_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""
	base_node_port=${NODE_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_node_port}\""

	base_farmer_port=${FARMER_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_farmer_port}\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$((i + base_node_port))
		farmer_port=$((i + base_farmer_port))
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer upgrading==================="
		msg_info "Node Sequence-->[upgrade]: We start upgrading the \"${i}\"th farmer"
		msg_info "Node Name-->[upgrade]: ${node_name}"
		msg_info "Node Path-->[upgrade]: ${node_path}"

		# Judging whether the directory exists,
		# the existence of the directory indicates that the node is already running, and then exits.
		#is_path=$(check_dir "${parent_path}/${node_name}")
		#echo "$is_path"
		#if (( $is_path = 0 )); then
		#	msg_success "The farmer is runing ,We will build next Farmer"
		#	continue
		#fi

		#	if [ -d "${parent_path}/${node_name}" ]; then
		#		msg_error "Exist: "${parent_path}/${node_name}" directory already exists"
		#		msg_error "Abandon the farmer operation that continues to be established, and proceed to the next farmer establishment task"
		#		msg_error "${node_name} has been failed ?????????"
		#		continue
		#	fi

		while [ $(check_port $node_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Node Port-->[upgrade]: $node_port"

		while [ $(check_port $farmer_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Farmer Port-->[upgrade]: $farmer_port"

		msg_info "Image Node-->[upgrade]: $IMAGE_NODE"
		msg_info "Image Node-->[upgrade]: $IMAGE_FARMER"
		msg_info "Plot Size-->[upgrade]: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address-->[upgrade]: $address"
		upgrade_farmer $node_path $node_name $node_port $farmer_port $address
		msg_success "Farmer-[${i}] has been successfully upgrade ?????????"
	done
}

delete_all_farmer() {
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	dir_name=""
	node_num=1
	msg_info "Config: Reading $1"
	"$2" $(get_current_dir)/$1
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/$1\""

	msg_info "Delete: Start deleting all node"
	node_num=$NODE_NUM

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer Delete==================="
		msg_info "Node Sequence-->[delete]: We start removing the farmer-[$i]"
		msg_info "Node Name-->[delete]: ${node_name}"
		msg_info "Node Path-->[delete]: ${node_path}"
		if [ -d "$node_path" ]; then
			work_dir=$(pwd)

			cd ${parent_path}/${node_name}
			sudo docker-compose stop || true
			rm -rf ${parent_path}/${node_name}
			msg_success "...-->[detele]:We have successfully deleted $node_path"
			cd $work_dir
		fi

	done
}

create_many_farmer() {
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	dir_name=""
	node_num=1
	msg_info "Config: Reading config.json"
	read_config $(get_current_dir)/config.json
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/config.json\""

	msg_info "Building: Start building a node"
	node_num=$NODE_NUM
	msg_info "Farmer Num: We will building \"${node_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""
	base_node_port=${NODE_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_node_port}\""

	base_farmer_port=${FARMER_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_farmer_port}\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$((i + base_node_port))
		farmer_port=$((i + base_farmer_port))
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer building==================="
		msg_info "Node Sequence-->[build]: We start building the farmer-[$i]"
		msg_info "Node Name-->[build]: ${node_name}"
		msg_info "Node Path-->[build]: ${node_path}"

		# Judging whether the directory exists,
		# the existence of the directory indicates that the node is already running, and then exits.
		#is_path=$(check_dir "${parent_path}/${node_name}")
		#echo "$is_path"
		#if (( $is_path = 0 )); then
		#	msg_success "The farmer is runing ,We will build next Farmer"
		#	continue
		#fi

		if [ -d "${parent_path}/${node_name}" ]; then
			msg_error "Exist: "${parent_path}/${node_name}" directory already exists"
			msg_error "Abandon the farmer operation that continues to be established, and proceed to the next farmer establishment task"
			msg_error "${node_name} has been failed ?????????"
			continue
		fi

		while [ $(check_port $node_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Node Port-->[build]: $node_port"

		while [ $(check_port $farmer_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Farmer Port-->[build]: $farmer_port"

		msg_info "Image Node-->[build]: $IMAGE_NODE"
		msg_info "Image Node-->[build]: $IMAGE_FARMER"
		msg_info "Plot Size-->[build]: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address: $address"
		create_farmer $node_path $node_name $node_port $farmer_port $address
		msg_success "Farmer-[${i}] has been successfully built ?????????"
	done

}

create_only_node() {
	#echo $PLOT_SIZE
	work_dir=$(pwd)
	#echo $work_dir

	mkdir $1

	#echo $(pwd)/docker-compose.yaml
	cp $(pwd)/node.yaml $1/docker-compose.yaml

	sleep 0.5

	export SNI=$IMAGE_NODE
	yq -i '.services.node.image=env(SNI)' $1/docker-compose.yaml
	unset SNI

	export node_name=$2
	yq -i '.services.node.command[-1]=env(node_name)' $1/docker-compose.yaml
	unset node_name

	export node_path=$1:/var/subspace:rw
	yq -i '.services.node.volumes[0]=env(node_path)' $1/docker-compose.yaml
	unset node_path

	export node_port="0.0.0.0:$3:30333"
	yq -i '.services.node.ports[0]=env(node_port)' $1/docker-compose.yaml
	unset node_port

	export rpc="0.0.0.0:$4:9944"
	yq -i '.services.node.ports[1]=env(rpc)' $1/docker-compose.yaml
	unset rpc

	cd $1

	sudo docker-compose up -d || true

	cd $work_dir
	#echo $(pwd)

}

create_only_nodes() {
	plat_size="30G"
	base_node_port=35000
	base_rpc_port=9944
	parent_path=$(get_parent_dir)
	dir_name=""
	node_num=1
	msg_info "Config: Reading node.json"
	read_node_config $(get_current_dir)/node.json
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/node.json\""

	msg_info "Building--<only-node>: Start building a node"
	node_num=$NODE_NUM
	msg_info "Node Num--<only-node>: We will building \"${node_num}\" node/nodes"

	msg_info "Base Node Name--<only-node>: \"${NODE_NAME}\""

	msg_info "Base Dir--<only-node>: \"${parent_path}\""
	base_node_port=${NODE_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_node_port}\""

	rpc_node_port=${RPC_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${rpc_node_port}\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$((i + base_node_port))
		rpc_port=$((i + base_rpc_port))
		node_path=${parent_path}/${node_name}
		msg_debug "=================Only Node building==================="
		msg_info "Node Sequence-->[build]: We start building the node-[$i]"
		msg_info "Node Name-->[build]: ${node_name}"
		msg_info "Node Path-->[build]: ${node_path}"

		# Judging whether the directory exists,
		# the existence of the directory indicates that the node is already running, and then exits.
		#is_path=$(check_dir "${parent_path}/${node_name}")
		#echo "$is_path"
		#if (( $is_path = 0 )); then
		#	msg_success "The farmer is runing ,We will build next Farmer"
		#	continue
		#fi

		if [ -d "${parent_path}/${node_name}" ]; then
			msg_error "Exist: "${parent_path}/${node_name}" directory already exists"
			msg_error "Abandon the node operation that continues to be established, and proceed to the next farmer establishment task"
			msg_error "${node_name} has been failed ?????????"
			continue
		fi

		while [ $(check_port $rpc_port) -ne 0 ]; do
			msg_error "The port exists, the rpc port is incremented by one"
			rpc_port=$(($rpc_port + 1))
		done

		msg_info "Node Port-->[build]: $node_port"
		msg_info "Image Node-->[build]: $IMAGE_NODE"
		msg_success "The ode rpc is : 0.0.0.0:$rpc_port"
		create_only_node $node_path $node_name $node_port $rpc_port
		msg_success "Node-[${i}] has been successfully built ?????????"
	done
}

create_only_farmer() {
	echo $1
	echo $2
	echo $3
	echo $4
	echo $5
	#echo $PLOT_SIZE
	work_dir=$(pwd)
	#echo $work_dir

	mkdir $1

	#echo $(pwd)/docker-compose.yaml
	cp $(pwd)/farmer.yaml $1/docker-compose.yaml

	sleep 0.5

	export SFI=$IMAGE_FARMER
	yq -i '.services.farmer.image=env(SFI)' $1/docker-compose.yaml
	unset SFI

	export farmer_path=$1:/var/subspace:rw
	yq -i '.services.farmer.volumes[0]=env(farmer_path)' $1/docker-compose.yaml
	unset farmer_path

	export plot_size=$PLOT_SIZE
	yq -i '.services.farmer.command[-1]=env(plot_size)' $1/docker-compose.yaml
	unset plot_size

	export address=$4
	yq -i '.services.farmer.command[-3]=env(address)' $1/docker-compose.yaml
	unset address

	export farmer_port="0.0.0.0:$3:40333"
	yq -i '.services.farmer.ports[0]=env(farmer_port)' $1/docker-compose.yaml
	unset farmer_port

	export rpc=$4
	yq -i '.services.farmer.command[4]=env(rpc)' $1/docker-compose.yaml
	unset rpc

	cd $1

	sudo docker-compose up -d || true

	cd $work_dir
	#echo $(pwd)

}

create_swarm() {
	#echo $PLOT_SIZE
	work_dir=$(pwd)
	#echo $work_dir

	mkdir $1

	#echo $(pwd)/docker-compose.yaml
	cp $(pwd)/swarm-farmer.yaml $1/docker-compose.yaml

	sleep 0.5

	export SFI=$IMAGE_FARMER
	yq -i '.services.farmer.image=env(SFI)' $1/docker-compose.yaml
	unset SFI

	export plot_size=$PLOT_SIZE
	yq -i '.services.farmer.command[-1]=env(plot_size)' $1/docker-compose.yaml
	unset plot_size

	export address=$3
	yq -i '.services.farmer.command[-3]=env(address)' $1/docker-compose.yaml
	unset address

	export rpc=$4
	yq -i '.services.farmer.command[4]=env(rpc)' $1/docker-compose.yaml
	unset rpc

	cd $1

	sudo docker stack deploy -c docker-compose.yaml $2 || true

	cd $work_dir
	#echo $(pwd)
}

delete_swarm() {
	plat_size="30G"
	parent_path=$(get_parent_dir)
	node_num=1
	node_rpc=""
	node_name=""
	msg_info "Config: Reading swarm.json"
	read_swarm_config $(get_current_dir)/swarm.json
	node_num=$NODE_NUM
	echo $node_num
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/swarm.json\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}

		msg_debug "=================farmer building==================="
		msg_info "Node Sequence-->[build]: We start building the farmer-[$i]"
		msg_info "Node Path-->[build]: ${node_path}"

		if [ -d "${parent_path}/${node_name}" ]; then
			work_dir=$(pwd)

			cd ${parent_path}/${node_name}
			sudo docker stack rm ${node_name} || true
			rm -rf ${parent_path}/${node_name}
			msg_success "...-->[detele]:We have successfully deleted $node_path"
			cd $work_dir
		fi
	done

}

create_only_farmers() {
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	dir_name=""
	node_num=1
	node_rpc=""
	node_name=""
	msg_info "Config: Reading farmer.json"
	read_farmer_config $(get_current_dir)/farmer.json
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/farmer.json\""

	msg_info "Building: Start building a farmer"
	node_num=$NODE_NUM
	msg_info "Farmer Num: We will building \"${node_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""

	base_farmer_port=${FARMER_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_farmer_port}\""
	node_rpc=${NODE_RPC}
	msg_info "Base RPC Port: \"${node_rpc}\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$((i + base_farmer_port))
		node_path=${parent_path}/${node_name}

		msg_debug "=================farmer building==================="
		msg_info "Node Sequence-->[build]: We start building the farmer-[$i]"
		msg_info "Node Path-->[build]: ${node_path}"

		# Judging whether the directory exists,
		# the existence of the directory indicates that the node is already running, and then exits.
		#is_path=$(check_dir "${parent_path}/${node_name}")
		#echo "$is_path"
		#if (( $is_path = 0 )); then
		#	msg_success "The farmer is runing ,We will build next Farmer"
		#	continue
		#fi

		if [ -d "${parent_path}/${node_name}" ]; then
			msg_error "Exist: "${parent_path}/${node_name}" directory already exists"
			msg_error "Abandon the farmer operation that continues to be established, and proceed to the next farmer establishment task"
			msg_error "${node_name} has been failed ?????????"
			continue
		fi

		while [ $(check_port $node_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			$node_port=$(($node_port + 1))
		done
		msg_info "Farmer Port-->[build]: $node_port"
		msg_info "Node Rpc-->[build]: $node_rpc"

		msg_info "Image Node-->[build]: $IMAGE_FARMER"
		msg_info "Plot Size-->[build]: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address: $address"
		create_only_farmer $node_path $node_name $node_port $address $node_rpc
		msg_success "Farmer-[${i}] has been successfully built ?????????"
	done

}

create_many_swarm() {
	plat_size="30G"
	parent_path=$(get_parent_dir)
	node_num=1
	node_rpc=""
	node_name=""
	msg_info "Config: Reading swarm.json"
	read_swarm_config $(get_current_dir)/swarm.json
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/swarm.json\""

	msg_info "Building: Start building a swarm farmer"
	node_num=$NODE_NUM
	msg_info "Farmer Num: We will building \"${node_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""

	node_rpc=${NODE_RPC}
	msg_info "Base RPC Port: \"${node_rpc}\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}

		msg_debug "=================farmer building==================="
		msg_info "Node Sequence-->[build]: We start building the farmer-[$i]"
		msg_info "Node Path-->[build]: ${node_path}"

		if [ -d "${parent_path}/${node_name}" ]; then
			msg_error "Exist: "${parent_path}/${node_name}" directory already exists"
			msg_error "Abandon the farmer operation that continues to be established, and proceed to the next farmer establishment task"
			msg_error "${node_name} has been failed ?????????"
			continue
		fi

		msg_info "Image Node-->[build]: $IMAGE_FARMER"
		msg_info "Plot Size-->[build]: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address: $address"
		create_swarm $node_path $node_name $address $node_rpc
		msg_success "Farmer-[${i}] has been successfully built ?????????"
	done

}

create_k8s() {
	#echo $PLOT_SIZE
	work_dir=$(pwd)
	#echo $work_dir

	mkdir $1

	#echo $(pwd)/docker-compose.yaml
	cp $(pwd)/k8s-farmer.yaml $1/farmer.yaml

	sleep 0.5

	export name=$2
	yq -i '.metadata.name=env(name)' $1/farmer.yaml
	yq -i '.metadata.labels.app=env(name)' $1/farmer.yaml
	yq -i '.spec.selector.matchLabels.app=env(name)' $1/farmer.yaml
	yq -i '.spec.template.metadata.labels.app=env(name)' $1/farmer.yaml
	yq -i '.spec.template.spec.containers[0].name=env(name)' $1/farmer.yaml
	unset name

	export SFI=$IMAGE_FARMER
	yq -i '.spec.template.spec.containers[0].image=env(SFI)' $1/farmer.yaml
	unset SFI

	export plot_size=$PLOT_SIZE
	yq -i '.spec.template.spec.containers[0].command[-1]=env(plot_size)' $1/farmer.yaml
	unset plot_size

	export address=$3
	yq -i '.spec.template.spec.containers[0].command[-3]=env(address)' $1/farmer.yaml
	unset address

	export rpc=$4
	yq -i '.spec.template.spec.containers[0].command[5]=env(rpc)' $1/farmer.yaml
	unset rpc

	cd $1

	#sudo docker stack deploy -c docker-compose.yaml $2 || true

	sudo kubectl apply -f farmer.yaml || true

	cd $work_dir
	#echo $(pwd)

}
delete_many_k8s() { 
	plat_size="30G"
	parent_path=$(get_parent_dir)
	node_num=1
	node_rpc=""
	node_name=""
	msg_info "Config: Reading k8s.json"
	read_swarm_config $(get_current_dir)/k8s.json
	node_num=$NODE_NUM
	echo $node_num
	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/k8s.json\""

	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}

		msg_debug "=================farmer building==================="
		msg_info "Node Sequence-->[build]: We start building the farmer-[$i]"
		msg_info "Node Path-->[build]: ${node_path}"

		if [ -d "${parent_path}/${node_name}" ]; then
			work_dir=$(pwd)

			cd ${parent_path}/${node_name}
			sudo kubectl delete deployment ${node_name} || true
			rm -rf ${parent_path}/${node_name}
			msg_success "...-->[detele]:We have successfully deleted $node_path"
			cd $work_dir
		fi
	done


}
create_many_k8s() {
	plat_size="30G"
	parent_path=$(get_parent_dir)
	node_num=1
	node_rpc=""
	node_name=""
	msg_info "Config: Reading k8s.json"
	read_swarm_config $(get_current_dir)/k8s.json

	msg_success "Path:Configuration has been read???config path is \"$(get_current_dir)/k8s.json\""

	msg_info "Building: Start building a swarm farmer"
	node_num=$NODE_NUM
	msg_info "Farmer Num: We will building \"${node_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""

	node_rpc=${NODE_RPC}
	msg_info "Base RPC Port: \"${node_rpc}\""
	for ((i = 1; i <= ${node_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}

		msg_debug "=================farmer building==================="
		msg_info "Node Sequence-->[build]: We start building the farmer-[$i]"
		msg_info "Node Path-->[build]: ${node_path}"

		if [ -d "${parent_path}/${node_name}" ]; then
			msg_error "Exist: "${parent_path}/${node_name}" directory already exists"
			msg_error "Abandon the farmer operation that continues to be established, and proceed to the next farmer establishment task"
			msg_error "${node_name} has been failed ?????????"
			continue
		fi

		msg_info "Image Node-->[build]: $IMAGE_FARMER"
		msg_info "Plot Size-->[build]: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address: $address"
		create_k8s $node_path $node_name $address $node_rpc
		msg_success "Farmer-[${i}] has been successfully built ?????????"
	done

}

print_script_name() {
	echo ".______       __    __  .__   __.     _______    ___      .___  ___.  _______ .______"
	echo "|   _  \     |  |  |  | |  \ |  |    |   ____|  /   \     |   \/   | |   ____||   _  \	     "
	echo "|  |_)  |    |  |  |  | |   \|  |    |  |__    /  ^  \    |  \  /  | |  |__   |  |_)  |	     "
	echo "|      /     |  |  |  | |  ' '  |    |   __|  /  /_\  \   |  |\/|  | |   __|  |      /       "
	echo "|  |\  \----.|  '--'  | |  |\   |    |  |    /  _____  \  |  |  |  | |  |____ |  |\  \----   "
	echo "| _| '._____| \______/  |__| \__|    |__|   /__/     \__\ |__|  |__| |_______|| _| '._____|  "
	echo " 											 	"
}

parse_args() {
	if [ $# -eq 0 ]; then
		print_script_name
		msg_warn $(usage)
	fi
	while [ $# -gt 0 ]; do
		case $1 in
		"init")
			print_script_name
			msg_info "Init: We will initialize the environment"
			msg_info "Checking [all]: Start checking the system environment"
			check_environment
			msg_success "Congrats: All checks have passed !!!"
			;;
		"create")
			if [ $# -eq 2 ]; then
				case $2 in
				"only-farmer")
					print_script_name
					check_only_farmer_network
					create_only_farmers
					exit 0
					;;
				"only-node")
					print_script_name
					create_only_nodes
					exit 0
					;;
				esac
			fi
			print_script_name
			msg_info "Create: We will create one or more farmer nodes according to the config configuration."
			create_many_farmer
			;;
		"swarm")
			if [ $# -eq 2 ]; then
				case $2 in
				"create")
					print_script_name
					create_many_swarm
					exit 0
					;;
				"delete")
					print_script_name
					delete_swarm
					exit 0
					;;
				esac
			fi
			print_script_name
			;;
		"k8s")
			if [ $# -eq 2 ]; then
				case $2 in
				"create")
					print_script_name
					create_many_k8s
					exit 0
					;;
				"delete")
					print_script_name
					delete_many_k8s
					exit 0
					;;
				esac
			fi
			print_script_name
			;;
		"stop")
			if [ $# -eq 2 ]; then
				case $2 in
				"only-farmer")
					print_script_name
					stop_all_farmer farmer.json read_farmer_config
					exit 0
					;;
				"only-node")
					print_script_name
					stop_all_farmer node.json read_node_config
					exit 0
					;;
				esac
			fi
			print_script_name
			stop_all_farmer config.json read_config
			;;
		"delete")
			if [ $# -eq 2 ]; then
				case $2 in
				"only-farmer")
					print_script_name
					delete_all_farmer farmer.json read_farmer_config
					exit 0
					;;
				"only-node")
					print_script_name
					delete_all_farmer node.json read_node_config
					exit 0
					;;
				esac
			fi
			print_script_name
			msg_info "Delete: We will delete one or more farmer nodes according to the config configuration."
			delete_all_farmer config.json read_config
			;;
		"upgrade")
			if [ $# -eq 2 ]; then
				case $2 in
				"only-farmer")
					print_script_name
					upgrade_all_farmer farmer.json read_farmer_config
					exit 0
					;;
				"only-node")
					print_script_name
					upgrade_all_farmer node.json read_node_config
					exit 0
					;;
				esac
			fi
			print_script_name
			msg_info "Upgrade: We will Upgrade one or more farmer nodes according to the config configuration."
			upgrade_all_framer config.json read_config
			;;
		*)
			echo "fatal"
			;;
		esac
		shift 2
	done
}

set -eu
parse_args $@
