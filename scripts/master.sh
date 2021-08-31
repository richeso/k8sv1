#! /bin/bash

CLUSTER_NAME=$1
#MASTER_IP="192.168.56.10"
#POD_CIDR="172.16.0.0/16"
MASTER_IP=$2
POD_CIDR=$3
CIDR_RANGE=$4
NODE_NAME=$(hostname -s)

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.
config_path="/vagrant/configs"
template_path="/vagrant/yaml"

if [ -d $config_path ]; then
   rm -f $config_path/*
else
   mkdir -p /vagrant/configs
fi

echo "output init defaults and change kubernetes clusterName to: "$CLUSTER_NAME
echo "==> MASTER_IP = "$MASTER_IP
echo "==> NODE_NAME = "$NODE_NAME
echo "==> POD_CIDR = "$POD_CIDR/$CIDR_RANGE
kubeadm config print init-defaults > $config_path/init-defaults.yaml
cp $config_path/init-defaults.yaml $config_path/init-defaults.original.yaml
sed "s/_cluster_name/$CLUSTER_NAME/g" $template_path/init-defaults-template.yaml > $config_path/init-defaults-changes.yaml
sed -i "s/_master_ip/$MASTER_IP/g" $config_path/init-defaults-changes.yaml 
sed -i "s/_node_name/$NODE_NAME/g" $config_path/init-defaults-changes.yaml
sed -i "s/_pod_cidr/$POD_CIDR/g" $config_path/init-defaults-changes.yaml
sed -i "s/_cidr_range/$CIDR_RANGE/g" $config_path/init-defaults-changes.yaml

#sudo kubeadm --apiserver-advertise-address=$MASTER_IP  --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap
sudo kubeadm init --config $config_path/init-defaults-changes.yaml --ignore-preflight-errors Swap

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Save Configs to shared /Vagrant location

cp -i /etc/kubernetes/admin.conf /vagrant/configs/config
touch /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh       

kubeadm token create --print-join-command > /vagrant/configs/join.sh

# Install Calico Network Plugin

curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

## install weave
## kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Install Metrics Server

kubectl apply -f https://raw.githubusercontent.com/scriptcamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# Install Kubernetes Dashboard

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

# Create Dashboard User

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

## sleep for 5 mins.. to give system enough time to
## finish before attempting to generate the json key

sleep 5
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" >> /vagrant/configs/token

# change config file to enable context switching
# using clustername to ovrride the default context_name
lcluster_name=$(echo $CLUSTER_NAME | tr '[:upper:]' '[:lower:]')
default_user_name="kubernetes-admin"
context_name=$default_user_name"@"$CLUSTER_NAME
sed -i "s/$context_name/$lcluster_name/g" /vagrant/configs/config
sed -i "s/$default_user_name/$lcluster_name/g" /vagrant/configs/config

# mod bashrc to add kubectl alias and completion bash
source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
echo "alias k=kubectl" >> ~/.bashrc # add kubectl alias to your bash shell.
echo "complete -F __start_kubectl k" >> ~/.bashrc # add autocomplete for kubectl alias to your bash shell.
cp ~/.bashrc /vagrant/scripts/.bashrc

sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
cp /vagrant/scripts/.bashrc ~/.bashrc
EOF





