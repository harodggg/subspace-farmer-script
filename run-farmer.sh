#!/bin/bash

# Images
IMAGE_NODE=""
IMAGE_FARMER=""

ADDRESS=()

WORK_DIR=""

FARMER_DIR=""

PLOT_SIZE=""

NODE_NAME=

FAMER_NUM=""
NODE_AVAILABLE_PORT=()

FARMER_AVAILABLE_PORT=()

### Check Funcions Start
check_info() {
	echo "Does $* exist ?"
}
check_docker() {
	num=$(is_package_exist docker)
	if [ $num -eq 0 ]; then
		msg_success "Exists: docker,go next"
	else
		msg_error 'No Exist: docker'
		install_docker
	fi

	# version_docker=$(docker --version | awk '{split($0,a,","); print a[1]}' | sed "s/Docker version //g")
}

check_docker_compose() {
	num=$(is_package_exist docker-compose)
	if [ $num -eq 0 ]; then
		msg_success "Exist: docker-compose,go next"
	else
		msg_error 'No Exist: docker-compose'
		install_docker_compose
	fi
}

check() {
	num=$(is_package_exist $*)
	if [ $num -eq 0 ]; then
		msg_success "Exist: $*,go next"
	else
		msg_error "No Exist: $*"
		msg_info "Install: $*"
		install_package $1 || $($2)
	fi
}

check_environment() {
	msg_info "Check [1]: $(check_info docker)"
	check_docker
	msg_info "Check [2]: $(check_info docker-compose)"
	check_docker_compose
	msg_info "Check [3]: $(check_info jq)"
	check jq
	msg_info "Check [4]: $(check_info yq)"
	check yq
	msg_info "Check [5]: $(check_info netstat)"
	check netstat install_netstat
}

check_port() {
	result=$(netstat -atnl | grep $* | wc -l)
	echo $result
	if [ $result -ne 0 ]; then
		echo "1"
	else
		echo "0"
	fi
}
check_dir() {
	is_exist_dir $*
	if $?; then
		msg_error "The farmer directory already exists, please confirm! ! !"
	else
		msg_success "The farmer directory does not exist, we will create it again"
	fi
}

get_node_num() {
	echo "1"
}

### Check Funcions End

upgrade_package() {
	case $(get_os) in
	"OSX") brew update && brew upgrade ;;
	"LINUX") sudo apt-get -y update && sudo apt-get -y upgrade ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
}

is_package_exist() {
	if type $* >/dev/null 2>&1; then
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
	sudo apt-get -y remove docker-compose | sudo snap docker-compose
	sudo wget https://github.com/docker/compose/releases/download/v2.11.1/docker-compose-linux-x86_64 -O /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
}

install_package() {
	case $(get_os) in
	"OSX") brew install $* ;;
	"LINUX") sudo apt -y install $* || sudo snap install $* ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
}

install_netstat() {
	install_package net-tools
}
### Install End

### Is Functions
is_exist_dir() {
	if [ ! -d $* ]; then
		return 1
	else
		return 0
	fi
}
### Is End

### Get Function
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

get_avaliable_port() {
	echo "K"
}

get_avaliable_dir() {
	echo "k"
}

get_node_num() {
	jq
	echo $num
}
### Get End

### Help Functions
usage() {
	echo "Usage: $(basename $0) options (init | create | detele | upgrade)"
}
### Help End

### Log Functions
echo_log() {
	now=$(date +"[%Y/%m/%d %H:%M:%S]")
	echo -e "\033[1;$1m${now}$2\033[0m"

}

msg_debug() {
	echo_log 35 "[Debug] ====> $*"
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
###Log End

create_farmer_dir() {
	mkdir $*
}

copy_configure_file() {
	cp $WORK_DIR/docker-compose.yaml $WORK_DIR/$FAMER_DIR
}

read_config() {
	ADDRESS=$(jq -c .address $*)
	#echo $ADDRESS
	FAMER_NUM=$(jq -rc .farmer_num $*)
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

show_config(){
	echo address: $ADDRESS
	echo plat_size: $PLOT_SIZE
	echo node_port_base: $NODE_AVAILABLE_PORT
	echo framer_port_node: $FARMER_AVAILABLE_PORT
	echo node_name: $NODE_NAME
	echo iamge_farmer: $IMAGE_FARMER
	echo image_node: $IMAGE_NODE

}

### Create Farmer funtion
# 建立单个 farmer $1=parent-path $2=dir-name+path $3=address $4=node-name $5=plat-size $6=node-端口 $7=farmer-端口
create_farmer() {
	# 2,建立特定的目录
	# 3,copy docker-compose.yaml
	# 4,修改 docker-compose
	# 5,进入该目录docker-compose up -d
	echo "l"
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
	framer_num=$FAMER_NUM
	msg_info "Farmer Num: We will building \"${framer_num}\" farmer/farmers"

	msg_info "Base Node Name: \"${NODE_NAME}\""

	msg_info "Base Dir: \"${parent_path}\""
	base_node_port=${NODE_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_node_port}\""

	base_farmer_port=${FARMER_AVAILABLE_PORT[0]}
	msg_info "Base Node Port: \"${base_farmer_port}\""

	for ((i = 1; i <= ${framer_num}; i++)); do
		node_name=$NODE_NAME${i}
		node_port=$(( i + base_node_port ))
		farmer_port=$(( i + base_farmer_port ))
		msg_info "Node Sequence: We start building the \"${i}\"th farmer"
		msg_info "Node Name: ${node_name}"
		msg_info "Node Path: ${parent_path}/${node_name}"

		# 判断目录是不是存在，目录存在，就表明这个节点已经运行，就退出。

		msg_info "Node Port: $node_port"
		msg_info "Farmer Port: $farmer_port"


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
			print_script_name
			msg_info "Create: We will create one or more farmer nodes according to the config configuration."

			create_many_farmer
			;;
		"delete")
			print_script_name
			msg_info "Delete: We will delete one or more farmer nodes according to the config configuration."
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

#msg_success $(get_current_dir)
#msg_success $(get_parent_dir)

#msg_info "Creating a farmer dir in " $(get_parent_dir)/$FARMER_DIR
#parse_args
#check_dir $(get_parent_dir)/$FARMER_DIR
#create_farmer_dir $(get_parent_dir)/$FARMER_DIR

#msg_info "Copeing docker-compose.yaml file to farmer dir"
#cp $(get_current_dir)/docker-compose.yaml $(get_parent_dir)/$FARMER_DIR

set -eu
parse_args $@
