#!/bin/bash

usage() {
	
	echo -e "Usage: install_kubernetes.sh [OPTIONS]
	master: install docker, kubectl, kubelet, kubeadm and creates the cluster
	worker: also installs docker, kubectl, kubelet and kubeadm but executes the join
		with the master. Takes three arguments: 'master_ip', 'token' and a 'hash'."
}

install_docker() {
	
	echo "Instaling Docker"

	sudo apt update
	sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
	
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		$(lsb_release -cs) \
		stable"
	
	sudo apt update
	sudo apt-get install docker-ce=18.09.7 docker-ce-cli=18.09.7 containerd.io=18.09.7
}

install_kubernetes() {
	
	echo "Instaling Kubeadm, Kubelet and Kubectl"

	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	
	sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
	
	sudo apt-get update
	sudo apt install -y kubelet=1.15.3 kubeadm=1.15.3 kubectl=1.15.3
}

config_master_node() {
	
	echo "Creating Kubernetes Cluster"
	
	sudo kubeadm init --pod-network-cidr=10.244.0.0/16
	
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config
	
	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml

	# Optional
	# To allow pods to run on the master node
	# uncomment the line below
	kubectl taint nodes --all node-role.kubernetes.io/master-
}

config_worker_node() {
	
	if [ $# -eq 0 ]; then
		
		echo "Need the master IP and token to join!"
		echo "Exemple: kubeadm join <ip_master>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
		exit
	fi

  kubeadm join $1:6443 --token $2 --discovery-token-ca-cert-hash sha256:$3
}

################################################################################

if [ $# -eq 0 ]; then
	
	usage
	exit
fi

case $1 in
	
	"master")
		
		install_docker
		install_kubernetes
		config_master_node
	;;

	"worker")
		
		# Checks for the correct number of arguments
		# Needed to config the worker and join it to the master
		if [ $1 = "worker" ]; then

			if [ $# -lt 4 ]; then

				echo "Need the master IP, token and hash to join!"
				echo "Exemple: kubeadm join <ip_master>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
				exit
			fi
		fi

		install_docker
		install_kubernetes
		config_worker_node $2 $3 $4
	;;

	*)
		usage
	;;
esac

echo "Done"