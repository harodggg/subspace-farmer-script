#!/bin/bash

# Images
IMAGE_NODE="ghcr.io/subspace/node:gemini-2a-2022-sep-10"
IMAGE_FARMER="ghcr.io/subspace/farmer:gemini-2a-2022-sep-10"

ADDRESS=""

WORK_DIR="/root/"

FARMER_DIR="farmer"

PLOT_SIZE="30G"

NODE_NAME="G_xbt"

# check Os
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

upgrade_package() {
	case $(get_os) in
	"OSX") brew update && brew upgrade ;;
	"LINUX") sudo apt -y update && sudo apt -y upgrade ;;
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

install_docker_pre() {
	set -e
	sudo apt-get -y install curl
	sudo apt-get -y install gnupg
	sudo apt-get -y install ca-certificates
	sudo apt-get -y install lsb-release
	sudo apt -y install gpgv gpgsm gnupg-l10n gnupg dirmngr
	sudo apt -y install  gnupg2
	sudo apt -y install apt-transport-https ca-certificates  software-properties-common
	sudo apt-get -y remove docker
	sudo apt-get -y remove docker-engine
	sudo apt-get -y remove docker-engine
	sudo apt-get -y remove docker.io
	sudo apt -y remove containerd
	sudo apt -y remove runc
	sudo apt -y install gpgv gpgsm gnupg-l10n gnupg dirmngr
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu"
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
	install_package docker-ce
}

install_docker_compose() {
	case $(get_os) in
	"OSX") msg_warn "You should already have docker and docker-compose installed, if not, install them manually" ;;
	"LINUX") install_docker_pre ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
	upgrade_package
	install_package docker-compose
}

install_package() {
	case $(get_os) in
	"OSX") brew install $* ;;
	"LINUX") sudo apt -y install $* || sudo snap install $* ;;
	*) msg_error "unknown:$OSTYPE, The script does not support OS, please use mac or ubuntu! ! !" ;;
	esac
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

install_netstat() {
	install_package net-tools
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

is_exist_dir() {
	if [ ! -d $* ]; then
		return 1
	else
		return 0
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

usage() {
	echo "Usage: $(basename $0) options (init | create | detele | upgrade)"
}

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

create_farmer_dir() {
	mkdir $*
}

copy_configure_file() {
	cp $WORK_DIR/docker-compose.yaml $WORK_DIR/$FAMER_DIR
}
check_info() {
	echo "Does $* exist ?"
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

set -eu
# 修改 yaml 配置
parse_args $@
#print_script_name

#msg_success "This is sample log message for Run-Farmer"
#msg_success "Starting run farmer scirpt"

#msg_success $(get_current_dir)
#msg_success $(get_parent_dir)

#msg_info "Creating a farmer dir in " $(get_parent_dir)/$FARMER_DIR
#parse_args
#check_dir $(get_parent_dir)/$FARMER_DIR
#create_farmer_dir $(get_parent_dir)/$FARMER_DIR

#msg_info "Copeing docker-compose.yaml file to farmer dir"
#cp $(get_current_dir)/docker-compose.yaml $(get_parent_dir)/$FARMER_DIR

#msg_info "Configuring the node image in docker-compose.yaml"

#msg_info "Configuring the farmer image in docker-compose.yaml"

#msg_info "Configuring node-name in docker-compose.yaml"

#msg_info "Configuring plot-size  in docker-compose.yaml"

#msg_info "Configuring address  in docker-compose.yaml"
