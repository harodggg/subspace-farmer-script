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
FARMER_NUM=""

ADDRESS=()
NODE_AVAILABLE_PORT=()
FARMER_AVAILABLE_PORT=()

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
	echo "Usage: $(basename $0) options (init | create [only-farmer] | stop | detele | upgrade)"
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
	echo_log 33 "[Warning] ====> $*"
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
	FARMER_NUM=$(jq -rc .farmer_num $*)
	for ((i = 0; i < ${FARMER_NUM}; i++)); do
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
# farmer $1=parent-path $2=dir-name+path $3=address $4=node-name $5=plat-size $6=node-端口 $7=farmer-端口
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

	mkdir $1

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
	dir_name=""
	farmer_num=1
	msg_info "Config: Reading config.json"
	read_config $(get_current_dir)/config.json
	msg_success "Path:Configuration has been read，config path is \"$(get_current_dir)/config.json\""

	msg_info "Stopping: Start stopping all node"
	farmer_num=$FARMER_NUM

	for ((i = 1; i <= ${farmer_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer stopping==================="

		if [ -d "$node_path" ]; then
			work_dir=$(pwd)

			cd ${parent_path}/${node_name}
			sudo docker-compose stop
			msg_info "We have successfully stopped $node_path"
			cd $work_dir
		fi

	done

}

upgrade_all_framer() {
	stop_all_farmer
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	dir_name=""
	farmer_num=1
	msg_info "Config: Reading config.json"
	read_config $(get_current_dir)/config.json
	msg_success "Path:Configuration has been read，config path is \"$(get_current_dir)/config.json\""

	msg_info "Building: Start upgrading node"
	farmer_num=$FARMER_NUM
	msg_info "Farmer Num: We will upgrading \"${farmer_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""
	base_node_port=${NODE_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_node_port}\""

	base_farmer_port=${FARMER_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_farmer_port}\""

	for ((i = 1; i <= ${farmer_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$((i + base_node_port))
		farmer_port=$((i + base_farmer_port))
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer upgrading==================="
		msg_info "Node Sequence: We start upgrading the \"${i}\"th farmer"
		msg_info "Node Name[upgrade]: ${node_name}"
		msg_info "Node Path[upgrade]: ${node_path}"

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
	#		msg_error "${node_name} has been failed ！！！"
	#		continue
	#	fi

		while [ $(check_port $node_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Node Port[upgrade]: $node_port"

		while [ $(check_port $farmer_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Farmer Port[upgrade]: $farmer_port"

		msg_info "Image Node[upgrade]: $IMAGE_NODE"
		msg_info "Image Node[upgrade]: $IMAGE_FARMER"
		msg_info "Plot Size[upgrade]: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address[upgrade]: $address"
		upgrade_farmer $node_path $node_name $node_port $farmer_port $address
		msg_success "Farmer${i} has been successfully upgrade ！！！"
	done
}

delete_all_farmer() {
	plat_size="30G"
	base_node_port=30000
	base_farmer_port=40000
	parent_path=$(get_parent_dir)
	dir_name=""
	farmer_num=1
	msg_info "Config: Reading config.json"
	read_config $(get_current_dir)/config.json
	msg_success "Path:Configuration has been read，config path is \"$(get_current_dir)/config.json\""

	msg_info "Delete: Start deleting all node"
	farmer_num=$FARMER_NUM

	for ((i = 1; i <= ${farmer_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer Delete==================="

		if [ -d "$node_path" ]; then
			work_dir=$(pwd)

			rm -rf ${parent_path}/${node_name}
			msg_info "We have successfully deleted $node_path"
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
	farmer_num=1
	msg_info "Config: Reading config.json"
	read_config $(get_current_dir)/config.json
	msg_success "Path:Configuration has been read，config path is \"$(get_current_dir)/config.json\""

	msg_info "Building: Start building a node"
	farmer_num=$FARMER_NUM
	msg_info "Farmer Num: We will building \"${farmer_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""
	base_node_port=${NODE_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_node_port}\""

	base_farmer_port=${FARMER_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_farmer_port}\""

	for ((i = 1; i <= ${farmer_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$((i + base_node_port))
		farmer_port=$((i + base_farmer_port))
		node_path=${parent_path}/${node_name}
		msg_debug "=================farmer building==================="
		msg_info "Node Sequence: We start building the \"${i}\"th farmer"
		msg_info "Node Name: ${node_name}"
		msg_info "Node Path: ${node_path}"

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
			msg_error "${node_name} has been failed ！！！"
			continue
		fi

		while [ $(check_port $node_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Node Port: $node_port"

		while [ $(check_port $farmer_port) -ne 0 ]; do
			msg_error "The port exists, the port is incremented by one"
			node_port=$(($node_port + 1))
		done
		msg_info "Farmer Port: $farmer_port"

		msg_info "Image Node: $IMAGE_NODE"
		msg_info "Image Node: $IMAGE_FARMER"
		msg_info "Plot Size: $PLOT_SIZE"
		address=${ADDRESS[$i - 1]}
		msg_info "Address: $address"
		create_farmer $node_path $node_name $node_port $farmer_port $address
		msg_success "Farmer${i} has been successfully built ！！！"
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
			if [ -n "$2" ]; then
				case $2 in
				"only-farmer")
					print_script_name
					echo "hello"
					exit 0
					;;
				"only-node")
					print_script_name
					exit 0
					;;
				esac
			fi
			print_script_name
			msg_info "Create: We will create one or more farmer nodes according to the config configuration."
			create_many_farmer
			;;
		"stop")
			print_script_name
			stop_all_farmer
			;;
		"delete")
			print_script_name
			msg_info "Delete: We will delete one or more farmer nodes according to the config configuration."
			stop_all_farmer

			;;
		"upgrade")
			print_script_name
			msg_info "Upgrade: We will Upgrade one or more farmer nodes according to the config configuration."
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
