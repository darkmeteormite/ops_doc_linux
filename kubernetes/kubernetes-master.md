```
1、系统配置初始化
#!/bin/bash
# 临时禁用selinux
setenforce 0
# 永久关闭selinux，修改/etc/sysconfig/selinux文件设置，把SELINUX的值改为disabled
#vim /etc/sysconfig/selinux


# 临时关闭swap
swapoff -a
# 永久关闭 注释/etc/fstab文件里swap相关的行
#vim /etc/fstab

# 关闭防火墙
systemctl stop firewalld
# 禁用开机启动
systemctl disable firewalld

# 开启forward
# Docker从1.13版本开始调整了默认的防火墙规则
# 禁用了iptables filter表中FOWARD链
# 这样会引起Kubernetes集群中跨Node的Pod无法通信

iptables -P FORWARD ACCEPT

# 配置转发相关参数，否则可能会出错
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF
sysctl --system

# 加载ipvs相关内核模块
# 如果重新开机，需要重新加载
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack_ipv4
lsmod | grep ip_vs
```
2、安装软件配置环境
```
# 安装docker

wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

yum -y install docker-ce

systemctl start docker && systemctl enable docker

# 安装 kubeadm, kubelet 和 kubectl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum -y install kubectl-1.12.1 kubeadm-1.12.1 kubelet-1.12.1

systemctl cat kubelet

# 配置kubelet

# 配置kubelet使用国内阿里pause镜像，官方的镜像被墙，kubelet启动不了
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1"
EOF
 
# 重新载入kubelet系统配置
systemctl daemon-reload
# 设置开机启动，暂时不启动kubelet
systemctl enable kubelet

```
3、初始化master
```
# 第一台master上执行
#!/bin/bash
# 设置节点环境变量，后续ip,hostname信息都以环境变量表示
CP0_IP="172.16.0.39"
CP0_HOSTNAME="vpc-zhangqiang-node001"
CP1_IP="172.16.0.40"
CP1_HOSTNAME="vpc-zhangqiang-node002"
CP2_IP="172.16.0.38"
CP2_HOSTNAME="vpc-zhangqiang-node003"
ADVERTISE_VIP="47.110.19.11"

# 生成kubeadm配置文件
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
# kubernetes版本
kubernetesVersion: v1.12.1
# 使用国内阿里镜像
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers

apiServerCertSANs:
- "$CP0_HOSTNAME"
- "$CP0_IP"
- "$ADVERTISE_VIP"
- "127.0.0.1"

api:
  advertiseAddress: $CP0_IP
  controlPlaneEndpoint: $ADVERTISE_VIP:6443

etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://$CP0_IP:2379"
      advertise-client-urls: "https://$CP0_IP:2379"
      listen-peer-urls: "https://$CP0_IP:2380"
      initial-advertise-peer-urls: "https://$CP0_IP:2380"
      initial-cluster: "$CP0_HOSTNAME=https://$CP0_IP:2380"
    serverCertSANs:
      - $CP0_HOSTNAME
      - $CP0_IP
    peerCertSANs:
      - $CP0_HOSTNAME
      - $CP0_IP

controllerManagerExtraArgs:
  node-monitor-grace-period: 10s
  pod-eviction-timeout: 10s

networking:
  podSubnet: 10.244.0.0/16

kubeProxy:
  config:
    # mode: ipvs
    mode: iptables
EOF

# 提前拉取镜像
kubeadm config images pull --config kubeadm-master.config

# 初始化第一台master
kubeadm init --config kubeadm-master.config


# --all-namespaces 表示查看所有命名空间
kubectl get pods --all-namespaces

# 安装网络插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


# 上传文件到其他master节点

# 打包ca相关文件上传至其他master节点
cd /etc/kubernetes && tar cvzf k8s-key.tgz pki/ca.* pki/sa.* pki/front-proxy-ca.* pki/etcd/ca.*
scp /etc/kubernetes/k8s-key.tgz $CP1_IP:/etc/kubernetes
ssh $CP1_IP 'tar xf /etc/kubernetes/k8s-key.tgz -C /etc/kubernetes/'
scp /etc/kubernetes/k8s-key.tgz $CP2_IP:/etc/kubernetes
ssh $CP2_IP 'tar xf /etc/kubernetes/k8s-key.tgz -C /etc/kubernetes/'




# 第二台master节点上运行
#!/bin/bash
# 设置节点环境变量，后续ip,hostname信息都以环境变量表示
CP0_IP="172.16.0.39"
CP0_HOSTNAME="vpc-zhangqiang-node001"
CP1_IP="172.16.0.40"
CP1_HOSTNAME="vpc-zhangqiang-node002"
CP2_IP="172.16.0.38"
CP2_HOSTNAME="vpc-zhangqiang-node003"
ADVERTISE_VIP="47.110.19.11"

# 生成kubeadm配置文件
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
# kubernetes版本
kubernetesVersion: v1.12.1
# 使用国内阿里镜像
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers

apiServerCertSANs:
- "$CP1_HOSTNAME"
- "$CP1_IP"
- "$ADVERTISE_VIP"
- "127.0.0.1"

api:
  advertiseAddress: $CP1_IP
  controlPlaneEndpoint: $ADVERTISE_VIP:6443

etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://$CP1_IP:2379"
      advertise-client-urls: "https://$CP1_IP:2379"
      listen-peer-urls: "https://$CP1_IP:2380"
      initial-advertise-peer-urls: "https://$CP1_IP:2380"
      initial-cluster: "$CP0_HOSTNAME=https://$CP0_IP:2380,$CP1_HOSTNAME=https://$CP1_IP:2380"
      initial-cluster-state: existing
    serverCertSANs:
      - $CP1_HOSTNAME
      - $CP1_IP
    peerCertSANs:
      - $CP1_HOSTNAME
      - $CP1_IP

controllerManagerExtraArgs:
  node-monitor-grace-period: 10s
  pod-eviction-timeout: 10s

networking:
  podSubnet: 10.244.0.0/16

kubeProxy:
  config:
    # mode: ipvs
    mode: iptables
EOF


# 提前拉取镜像
kubeadm config images pull --config kubeadm-master.config
 
# 配置kubelet
# 生成证书
kubeadm alpha phase certs all --config kubeadm-master.config
# 生成kubelet相关配置文件
kubeadm alpha phase kubelet config write-to-disk --config kubeadm-master.config
kubeadm alpha phase kubelet write-env-file --config kubeadm-master.config
kubeadm alpha phase kubeconfig kubelet --config kubeadm-master.config
# 启动kubelet
systemctl restart kubelet
 
# 部署 controlplane，即kube-apiserver, kube-controller-manager, kube-scheduler等各组件
# 生成controlplane的配置文件
kubeadm alpha phase kubeconfig all --config kubeadm-master.config
 
# 设置kubectl 默认配置文件
mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config



# 添加etcd到集群中
# 向添加etcd集群中添加成员，此时如果使用kubectl命令会出错"Unable to connect to the server: unexpected EOF"，这是etcd添加第二个节点的机制导致的，先启动etcd就可以了
kubectl exec -n kube-system etcd-${CP0_HOSTNAME} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${CP0_IP}:2379 member add ${CP1_HOSTNAME} https://${CP1_IP}:2380
# 部署etcd静态pod
kubeadm alpha phase etcd local --config kubeadm-master.config
 
# 查看ectd节点
kubectl exec -n kube-system etcd-${CP0_HOSTNAME} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${CP0_IP}:2379 member list
 
 
# 部署controlplane静态pod文件，kubelet会自动启动各组件
kubeadm alpha phase controlplane all --config kubeadm-master.config

# 标记为master节点，只是在此节点上添加了label和taint
kubeadm alpha phase mark-master --config kubeadm-master.config

# 配置第三个master节点

#!/bin/bash
# 设置节点环境变量，后续ip,hostname信息都以环境变量表示
CP0_IP="172.16.0.39"
CP0_HOSTNAME="vpc-zhangqiang-node001"
CP1_IP="172.16.0.40"
CP1_HOSTNAME="vpc-zhangqiang-node002"
CP2_IP="172.16.0.38"
CP2_HOSTNAME="vpc-zhangqiang-node003"
ADVERTISE_VIP="47.110.19.11"

# 生成kubeadm配置文件
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
# kubernetes版本
kubernetesVersion: v1.12.1
# 使用国内阿里镜像
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers


apiServerCertSANs:
- "$CP2_HOSTNAME"
- "$CP2_IP"
- "$ADVERTISE_VIP"
- "127.0.0.1"

api:
  advertiseAddress: $CP2_IP
  controlPlaneEndpoint: $ADVERTISE_VIP:6443

etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://$CP2_IP:2379"
      advertise-client-urls: "https://$CP2_IP:2379"
      listen-peer-urls: "https://$CP2_IP:2380"
      initial-advertise-peer-urls: "https://$CP2_IP:2380"
      initial-cluster: "$CP0_HOSTNAME=https://$CP0_IP:2380,$CP1_HOSTNAME=https://$CP1_IP:2380,$CP2_HOSTNAME=https://$CP2_IP:2380"
      initial-cluster-state: existing
    serverCertSANs:
      - $CP2_HOSTNAME
      - $CP2_IP
    peerCertSANs:
      - $CP2_HOSTNAME
      - $CP2_IP


controllerManagerExtraArgs:
  node-monitor-grace-period: 10s
  pod-eviction-timeout: 10s

networking:
  podSubnet: 10.244.0.0/16

kubeProxy:
  config:
    # mode: ipvs
    mode: iptables
EOF


# 提前拉取镜像
kubeadm config images pull --config kubeadm-master.config
 
# 配置kubelet
# 生成证书
kubeadm alpha phase certs all --config kubeadm-master.config
# 生成kubelet相关配置文件
kubeadm alpha phase kubelet config write-to-disk --config kubeadm-master.config
kubeadm alpha phase kubelet write-env-file --config kubeadm-master.config
kubeadm alpha phase kubeconfig kubelet --config kubeadm-master.config
# 启动kubelet
systemctl restart kubelet
 
# 部署 controlplane，即kube-apiserver, kube-controller-manager, kube-scheduler等各组件
# 生成controlplane的配置文件
kubeadm alpha phase kubeconfig all --config kubeadm-master.config
 
# 设置kubectl 默认配置文件
mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
 
# 添加etcd到集群中
# 向添加etcd集群中添加成员，此时如果使用kubectl命令不会出错
kubectl exec -n kube-system etcd-${CP0_HOSTNAME} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${CP0_IP}:2379 member add ${CP2_HOSTNAME} https://${CP2_IP}:2380
# 部署etcd静态pod
kubeadm alpha phase etcd local --config kubeadm-master.config
 
# 查看ectd节点
kubectl exec -n kube-system etcd-${CP0_HOSTNAME} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${CP0_IP}:2379 member list
 
 
# 部署controlplane静态pod文件，kubelet会自动启动各组件
kubeadm alpha phase controlplane all --config kubeadm-master.config
 
# 标记为master节点，只是在此节点上添加了label和taint
kubeadm alpha phase mark-master --config kubeadm-master.config



```
