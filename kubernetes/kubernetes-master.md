版本信息
```
linux   Centos7
kubernetes v1.12.2
docker v17.03.2-ce
```
节点信息
```
VIP:47.110.19.11    阿里云负载均衡
172.16.0.41 VPC-OPEN-MASTER001  kubelet,etcd,kube-controller-manager,kube-scheduler,kube-proxy,flannel
172.16.0.43 VPC-OPEN-MASTER002  kubelet,etcd,kube-controller-manager,kube-scheduler,kube-proxy,flannel
172.16.0.42 VPC-OPEN-MASTER003  kubelet,etcd,kube-controller-manager,kube-scheduler,kube-proxy,flannel
172.16.0.45 VPC-OPEN-NODE001    kubelet, kube-proxy, flannel
172.16.0.44 VPC-OPEN-NODE002    kubelet, kube-proxy, flannel
```
安装前准备
```
开始部署前确保所有节点网络正常，能访问公网。主要操作都在VPC-OPEN-MASTER001节点进行，设置VPC-OPEN-MASTER001可以免密码登陆其他节点。所有操作都使用root用户身份进行。
```
1、配置hosts解析
```
# vim /etc/hosts
172.16.0.41 vpc-open-master001	k8s-m1
172.16.0.43 vpc-open-master002	k8s-m2
172.16.0.42 vpc-open-master003	k8s-m3
```
2、安装docker
```
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

yum install -y https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm  https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm

systemctl start docker && systemctl enable docker
```
3、安装 kubeadm, kubelet 和 kubectl
```
# 配置yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum -y install kubectl-1.12.2 kubeadm-1.12.2 kubelet-1.12.2
```
查看安装情况
```
systemctl cat kubelet
# 可以看到kubelet以设置为系统服务，生成kubelet.service和10-kubeadm.conf两文件
# /etc/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target

# /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS

```
4、配置系统相关参数
以下操作在所有节点操作
```
#!/bin/bash
#关闭Selinux
setenforce  0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux

#关闭Swapp
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

#修改转发配置
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness = 0
EOF

sysctl --system

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 开启forward
# Docker从1.13版本开始调整了默认的防火墙规则
# 禁用了iptables filter表中FOWARD链
# 这样会引起Kubernetes集群中跨Node的Pod无法通信
 
iptables -P FORWARD ACCEPT
 
# 加载ipvs相关内核模块
# 如果重新开机，需要重新加载
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack_ipv4
lsmod | grep ip_vs
```

5、配置阿里云负载均衡

6、配置kubelet
### 以下操作需要在所有节点上执行
```
# 配置kubelet使用国内阿里pause镜像，官方的镜像被墙，kubelet启动不了
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1"
EOF
 
# 重新载入kubelet系统配置
systemctl daemon-reload
# 设置开机启动，暂时不启动kubelet
systemctl enable kubelet

```
配置master节点

1. 配置第一个master节点
```
# 设置节点环境变量，后续ip,hostname信息都以环境变量表示
CP0_IP="172.16.0.41"
CP0_HOSTNAME="vpc-open-master001"
CP1_IP="172.16.0.43"
CP1_HOSTNAME="vpc-open-master002"
CP2_IP="172.16.0.42"
CP2_HOSTNAME="vpc-open-master003"
ADVERTISE_VIP="47.110.19.11"

# 生成kubeadm配置文件
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
# kubernetes版本
kubernetesVersion: v1.12.2
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
    #mode: ipvs
    mode: iptables
EOF

#提前拉取镜像
# kubeadm config images pull --config kubeadm-master.config
#  拉取的镜像如下
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.12.2
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.12.2
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.12.2
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.12.2
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.2.24
[config/images] Pulled registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.2.2
```
初始化
```
# kubeadm init --config kubeadm-master.config
[init] using Kubernetes version: v1.12.2
[preflight] running pre-flight checks
[preflight/images] Pulling images required for setting up a Kubernetes cluster
[preflight/images] This might take a minute or two, depending on the speed of your internet connection
[preflight/images] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[preflight] Activating the kubelet service
[certificates] Generated etcd/ca certificate and key.
[certificates] Generated etcd/healthcheck-client certificate and key.
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] Generated etcd/server certificate and key.
[certificates] etcd/server serving cert is signed for DNS names [vpc-open-master001 localhost vpc-open-master001] and IPs [127.0.0.1 ::1 172.16.0.41]
[certificates] Generated etcd/peer certificate and key.
[certificates] etcd/peer serving cert is signed for DNS names [vpc-open-master001 localhost vpc-open-master001] and IPs [172.16.0.41 127.0.0.1 ::1 172.16.0.41]
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [vpc-open-master001 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local vpc-open-master001] and IPs [10.96.0.1 172.16.0.41 47.110.19.11 172.16.0.41 47.110.19.11 127.0.0.1]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/kubernetes/pki"
[certificates] Generated sa key and public key.
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[controlplane] wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests"
[init] this might take a minute or longer if the control plane images have to be pulled
[apiclient] All control plane components are healthy after 22.504801 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.12" in namespace kube-system with the configuration for the kubelets in the cluster
[markmaster] Marking the node vpc-open-master001 as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node vpc-open-master001 as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "vpc-open-master001" as an annotation
[bootstraptoken] using token: jjv5r2.g448y7z9bxzdwhls
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 47.110.19.11:6443 --token jjv5r2.g448y7z9bxzdwhls --discovery-token-ca-cert-hash sha256:939b311021acd36ce6f16875bf25201bf6e664c4aadf94b0246ef7bc054535e4
```
此时运行命令查看节点信息，发现节点状态为NotReady
```
# kubectl get nodes
NAME                 STATUS     ROLES    AGE     VERSION
vpc-open-master001   NotReady   master   2m54s   v1.12.2
```
安装网络插件flannel
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
稍等一会，部署网络，查看运行pod
```
# kubectl get pods --all-namespaces
NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE
kube-system   coredns-6c66ffc55b-6cr7h                     1/1     Running   0          5m24s
kube-system   coredns-6c66ffc55b-7664m                     1/1     Running   0          5m24s
kube-system   etcd-vpc-open-master001                      1/1     Running   0          4m37s
kube-system   kube-apiserver-vpc-open-master001            1/1     Running   0          4m52s
kube-system   kube-controller-manager-vpc-open-master001   1/1     Running   0          4m47s
kube-system   kube-flannel-ds-amd64-kl79l                  1/1     Running   0          77s
kube-system   kube-proxy-zqdkm                             1/1     Running   0          5m24s
kube-system   kube-scheduler-vpc-open-master001            1/1     Running   0          4m49s
```
上传文件至其他节点
```
# 打包ca相关文件上传至其他master节点
cd /etc/kubernetes && tar cvzf k8s-key.tgz pki/ca.* pki/sa.* pki/front-proxy-ca.* pki/etcd/ca.*
scp /etc/kubernetes/k8s-key.tgz $CP1_IP:/etc/kubernetes
ssh $CP1_IP 'tar xf /etc/kubernetes/k8s-key.tgz -C /etc/kubernetes/'
scp /etc/kubernetes/k8s-key.tgz $CP2_IP:/etc/kubernetes
ssh $CP2_IP 'tar xf /etc/kubernetes/k8s-key.tgz -C /etc/kubernetes/'
```
2. 配置第二个master节点
```
#!/bin/bash
# 设置节点环境变量，后续ip,hostname信息都以环境变量表示
CP0_IP="172.16.0.41"
CP0_HOSTNAME="vpc-open-master001"
CP1_IP="172.16.0.43"
CP1_HOSTNAME="vpc-open-master002"
CP2_IP="172.16.0.42"
CP2_HOSTNAME="vpc-open-master003"
ADVERTISE_VIP="47.110.19.11"

# 生成kubeadm配置文件
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
# kubernetes版本
kubernetesVersion: v1.12.2
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
```
查看节点情况
```
# kubectl get nodes
NAME                 STATUS   ROLES    AGE     VERSION
vpc-open-master001   Ready    master   6m59s   v1.12.2
vpc-open-master002   Ready    <none>   69s     v1.12.2
# 现在master002可以算作一个node节点

# 查看此节点上的pod运行情况
# kubectl get pods --all-namespaces -o wide |grep master002
kube-system   kube-flannel-ds-amd64-jwrks                  1/1     Running   0          2m38s   172.16.0.43   vpc-open-master002   <none>
kube-system   kube-proxy-97mfb                             1/1     Running   0          2m38s   172.16.0.43   vpc-open-master002   <none>

# 添加etcd到集群中
# 向添加etcd集群中添加成员，此时如果使用kubectl命令会出错"Unable to connect to the server: unexpected EOF"，这是etcd添加第二个节点的机制导致的，先启动etcd就可以了
kubectl exec -n kube-system etcd-${CP0_HOSTNAME} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${CP0_IP}:2379 member add ${CP1_HOSTNAME} https://${CP1_IP}:2380
# 部署etcd静态pod
kubeadm alpha phase etcd local --config kubeadm-master.config
 
# 查看ectd节点
kubectl exec -n kube-system etcd-${CP0_HOSTNAME} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${CP0_IP}:2379 member list
 
 
# 部署controlplane静态pod文件，kubelet会自动启动各组件
kubeadm alpha phase controlplane all --config kubeadm-master.config

# 此时查看节点及pod运行情况
# kubectl get nodes
NAME                 STATUS   ROLES    AGE     VERSION
vpc-open-master001   Ready    master   11m     v1.12.2
vpc-open-master002   Ready    <none>   5m11s   v1.12.2

# kubectl get pods --all-namespaces -o wide |grep master002
kube-system   etcd-vpc-open-master002                      1/1     Running   0          42s     172.16.0.43   vpc-open-master002   <none>
kube-system   kube-apiserver-vpc-open-master002            1/1     Running   0          23s     172.16.0.43   vpc-open-master002   <none>
kube-system   kube-controller-manager-vpc-open-master002   1/1     Running   0          23s     172.16.0.43   vpc-open-master002   <none>
kube-system   kube-flannel-ds-amd64-jwrks                  1/1     Running   0          5m23s   172.16.0.43   vpc-open-master002   <none>
kube-system   kube-proxy-97mfb                             1/1     Running   0          5m23s   172.16.0.43   vpc-open-master002   <none>
kube-system   kube-scheduler-vpc-open-master002            1/1     Running   0          23s     172.16.0.43   vpc-open-master002   <none>

# 标记为master节点，只是在此节点上添加了label和taint
# kubeadm alpha phase mark-master --config kubeadm-master.config
[markmaster] Marking the node vpc-open-master002 as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node vpc-open-master002 as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
# 查看节点信息
# kubectl get nodes
NAME                 STATUS   ROLES    AGE     VERSION
vpc-open-master001   Ready    master   12m     v1.12.2
vpc-open-master002   Ready    master   6m41s   v1.12.2
```
3. 配置第三个master节点 
```
#!/bin/bash
# 设置节点环境变量，后续ip,hostname信息都以环境变量表示
CP0_IP="172.16.0.41"
CP0_HOSTNAME="vpc-open-master001"
CP1_IP="172.16.0.43"
CP1_HOSTNAME="vpc-open-master002"
CP2_IP="172.16.0.42"
CP2_HOSTNAME="vpc-open-master003"
ADVERTISE_VIP="47.110.19.11"

# 生成kubeadm配置文件，与第一个master节点的区别除了修改ip外，主要是etcd增加节点的配置
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
# kubernetes版本
kubernetesVersion: v1.12.2
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
查看节点运行情况
```
# kubectl get nodes -w
NAME                 STATUS   ROLES    AGE   VERSION
vpc-open-master001   Ready    master   25m   v1.12.2
vpc-open-master002   Ready    master   19m   v1.12.2
vpc-open-master003   Ready    master   98s   v1.12.2
# kubectl get pods --all-namespaces
NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE
kube-system   coredns-6c66ffc55b-mrsqg                     1/1     Running   0          25m
kube-system   coredns-6c66ffc55b-nl686                     1/1     Running   0          25m
kube-system   etcd-vpc-open-master001                      1/1     Running   0          24m
kube-system   etcd-vpc-open-master002                      1/1     Running   0          15m
kube-system   etcd-vpc-open-master003                      1/1     Running   0          52s
kube-system   kube-apiserver-vpc-open-master001            1/1     Running   0          24m
kube-system   kube-apiserver-vpc-open-master002            1/1     Running   0          14m
kube-system   kube-apiserver-vpc-open-master003            1/1     Running   0          32s
kube-system   kube-controller-manager-vpc-open-master001   1/1     Running   1          24m
kube-system   kube-controller-manager-vpc-open-master002   1/1     Running   0          14m
kube-system   kube-controller-manager-vpc-open-master003   1/1     Running   0          32s
kube-system   kube-flannel-ds-amd64-jwrks                  1/1     Running   0          19m
kube-system   kube-flannel-ds-amd64-nxrx2                  1/1     Running   0          108s
kube-system   kube-flannel-ds-amd64-zmwbx                  1/1     Running   0          24m
kube-system   kube-proxy-97mfb                             1/1     Running   0          19m
kube-system   kube-proxy-h8ctq                             1/1     Running   0          25m
kube-system   kube-proxy-vf2k6                             1/1     Running   0          108s
kube-system   kube-scheduler-vpc-open-master001            1/1     Running   1          24m
kube-system   kube-scheduler-vpc-open-master002            1/1     Running   0          14m
kube-system   kube-scheduler-vpc-open-master003            1/1     Running   0          32s
```

配置node节点
```
# 初始化操作同master一样，不能省略，必须要做
# 软件安装及镜像下载
yum -y install kubectl-1.12.2 kubelet-1.12.2 kubeadm-1.12.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:v1.12.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy-amd64:v1.12.2 k8s.gcr.io/kube-proxy-amd64:v1.12.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1 k8s.gcr.io/pause:3.1
# 加入集群
# kubeadm join 47.110.19.11:6443 --token jjv5r2.g448y7z9bxzdwhls --discovery-token-ca-cert-hash sha256:939b311021acd36ce6f16875bf25201bf6e664c4aadf94b0246ef7bc054535e4
[preflight] running pre-flight checks
	[WARNING RequiredIPVSKernelModulesAvailable]: the IPVS proxier will not be used, because the following required kernel modules are not loaded: [ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh] or no builtin kernel ipvs support: map[nf_conntrack_ipv4:{} ip_vs:{} ip_vs_rr:{} ip_vs_wrr:{} ip_vs_sh:{}]
you can solve this problem with following methods:
 1. Run 'modprobe -- ' to load missing kernel modules;
2. Provide the missing builtin kernel ipvs support

	[WARNING Hostname]: hostname "vpc-open-node002" could not be reached
	[WARNING Hostname]: hostname "vpc-open-node002" lookup vpc-open-node002 on 100.100.2.138:53: no such host
[discovery] Trying to connect to API Server "47.110.19.11:6443"
[discovery] Created cluster-info discovery client, requesting info from "https://47.110.19.11:6443"
[discovery] Requesting info from "https://47.110.19.11:6443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "47.110.19.11:6443"
[discovery] Successfully established connection with API Server "47.110.19.11:6443"
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.12" ConfigMap in the kube-system namespace
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[preflight] Activating the kubelet service
[tlsbootstrap] Waiting for the kubelet to perform the TLS Bootstrap...
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "vpc-open-node002" as an annotation

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.
```
如果后面要加入多台机器，都是同一个命令
```
kubeadm join 47.110.19.11:6443 --token jjv5r2.g448y7z9bxzdwhls --discovery-token-ca-cert-hash sha256:939b311021acd36ce6f16875bf25201bf6e664c4aadf94b0246ef7bc054535e4
```
此命令创建的令牌默认有效期24h，如果过期或者忘记，需要使用如下命令创建新的token
```
kubeadm alpha phase bootstrap-token create --config kubeadm-master.config
```
在master节点上查看当前token列表
```
kubeadm token list
```
在master上查看当前节点及pod情况
```
# kubectl get nodes
NAME                 STATUS   ROLES    AGE     VERSION
vpc-open-master001   Ready    master   75m     v1.12.2
vpc-open-master002   Ready    master   69m     v1.12.2
vpc-open-master003   Ready    master   51m     v1.12.2
vpc-open-node001     Ready    <none>   18m     v1.12.2
vpc-open-node002     Ready    <none>   3m55s   v1.12.2
# kubectl get pods --all-namespaces
NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE
kube-system   coredns-6c66ffc55b-mrsqg                     1/1     Running   0          74m
kube-system   coredns-6c66ffc55b-nl686                     1/1     Running   0          74m
kube-system   etcd-vpc-open-master001                      1/1     Running   0          74m
kube-system   etcd-vpc-open-master002                      1/1     Running   0          64m
kube-system   etcd-vpc-open-master003                      1/1     Running   0          50m
kube-system   kube-apiserver-vpc-open-master001            1/1     Running   0          74m
kube-system   kube-apiserver-vpc-open-master002            1/1     Running   0          64m
kube-system   kube-apiserver-vpc-open-master003            1/1     Running   0          49m
kube-system   kube-controller-manager-vpc-open-master001   1/1     Running   1          74m
kube-system   kube-controller-manager-vpc-open-master002   1/1     Running   0          64m
kube-system   kube-controller-manager-vpc-open-master003   1/1     Running   0          49m
kube-system   kube-flannel-ds-amd64-dzq5b                  1/1     Running   0          4m5s
kube-system   kube-flannel-ds-amd64-hnf2f                  1/1     Running   0          18m
kube-system   kube-flannel-ds-amd64-jwrks                  1/1     Running   0          69m
kube-system   kube-flannel-ds-amd64-nxrx2                  1/1     Running   0          51m
kube-system   kube-flannel-ds-amd64-zmwbx                  1/1     Running   0          73m
kube-system   kube-proxy-97mfb                             1/1     Running   0          69m
kube-system   kube-proxy-h8ctq                             1/1     Running   0          74m
kube-system   kube-proxy-mw2l7                             1/1     Running   0          18m
kube-system   kube-proxy-qxztv                             1/1     Running   0          4m5s
kube-system   kube-proxy-vf2k6                             1/1     Running   0          51m
kube-system   kube-scheduler-vpc-open-master001            1/1     Running   1          74m
kube-system   kube-scheduler-vpc-open-master002            1/1     Running   0          64m
kube-system   kube-scheduler-vpc-open-master003            1/1     Running   0          49m
```
kubeadm初始化过程分步操作
kubeadm init命令实际是由的原子工作任务组成的，详见[http://docs.kubernetes.org.cn/829.html](http://docs.kubernetes.org.cn/829.html)

```
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
 
# 生成添加节点命令
# 上传配置到configMap中
kubeadm alpha phase upload-config --config kubeadm-master.config
kubeadm alpha phase kubelet config upload --config kubeadm-master.config
# 配置节点的 TLS 引导
kubeadm alpha phase bootstrap-token all --config kubeadm-master.config
 
# 单独创建token
kubeadm alpha phase bootstrap-token create --config kubeadm-master.config
 
# 单独安装插件，通过 API server 安装内部 coreDNS 服务和 kube-proxy 插件组件
kubeadm alpha phase addon all --config kubeadm-master.config
 
# 标记为master节点，只是在此节点上添加了label和taint
kubeadm alpha phase mark-master --config kubeadm-master.config
 
 
 
# 清除docker容器，方便反复试验
docker ps -a | awk 'NR!=1{print $1}' | xargs docker rm -f
umount /var/lib/kubelet/pods/*/volumes/kubernetes.io~secret/*
rm -rf /var/lib/kubelet/
rm -rf /var/lib/etcd/
rm -rf /var/log/pods/
# 重新生成删除的配置文件
kubeadm alpha phase kubelet config write-to-disk --config kubeadm-master.config
kubeadm alpha phase kubelet write-env-file --config kubeadm-master.config
 
# kubeconfig中的client-certificate-data字段值是证书的base64编码后的文本，还原为证书格式
cat /etc/kubernetes/admin.conf | grep client-certificate-data | awk -F ': ' '{print $2}' | base64 -d > /etc/kubernetes/pki/client.crt
```
部署kubernetes-dashboard
在master节点上操作
1. 生成kubernetes-dashboard.yaml文件
```
# wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

# 生成kubernetes-dashboard.yaml，把镜像地址改为国内阿里镜像，设置service的type为NodePort，nodePort为30001对集群外访问提供端口
# cat > kubernetes-dashboard.yaml << EOF
# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ------------------- Dashboard Secret ------------------- #

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kube-system
type: Opaque

---
# ------------------- Dashboard Service Account ------------------- #

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Role & Role Binding ------------------- #

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
rules:
  # Allow Dashboard to create 'kubernetes-dashboard-key-holder' secret.
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create"]
  # Allow Dashboard to create 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create"]
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
  verbs: ["get", "update", "delete"]
  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["kubernetes-dashboard-settings"]
  verbs: ["get", "update"]
  # Allow Dashboard to get metrics from heapster.
- apiGroups: [""]
  resources: ["services"]
  resourceNames: ["heapster"]
  verbs: ["proxy"]
- apiGroups: [""]
  resources: ["services/proxy"]
  resourceNames: ["heapster", "http:heapster:", "https:heapster:"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard-minimal
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Deployment ------------------- #

kind: Deployment
apiVersion: apps/v1beta2
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
      - name: kubernetes-dashboard
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/kubernetes-dashboard-amd64:v1.10.0
        ports:
        - containerPort: 8443
          protocol: TCP
        args:
          - --auto-generate-certificates
          # Uncomment the following line to manually specify Kubernetes API server Host
          # If not specified, Dashboard will attempt to auto discover the API server and connect
          # to it. Uncomment only if the default does not work.
          # - --apiserver-host=http://my-address:port
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
          # Create on-disk volume to store exec logs
        - mountPath: /tmp
          name: tmp-volume
        livenessProbe:
          httpGet:
            scheme: HTTPS
            path: /
            port: 8443
          initialDelaySeconds: 30
          timeoutSeconds: 30
      volumes:
      - name: kubernetes-dashboard-certs
        secret:
          secretName: kubernetes-dashboard-certs
      - name: tmp-volume
        emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule

---
# ------------------- Dashboard Service ------------------- #

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
  selector:
    k8s-app: kubernetes-dashboard
EOF
```
2. 部署dashboard
```
kubectl create -f kubernetes-dashboard.yaml
```
查看Pod及Service运行情况
```
# kubectl get pods -n kube-system -o wide
NAME                                         READY   STATUS    RESTARTS   AGE   IP            NODE                 NOMINATED NODE
coredns-6c66ffc55b-mrsqg                     1/1     Running   0          16h   10.244.0.4    vpc-open-master001   <none>
coredns-6c66ffc55b-nl686                     1/1     Running   0          16h   10.244.0.5    vpc-open-master001   <none>
etcd-vpc-open-master001                      1/1     Running   0          16h   172.16.0.41   vpc-open-master001   <none>
etcd-vpc-open-master002                      1/1     Running   0          15h   172.16.0.43   vpc-open-master002   <none>
etcd-vpc-open-master003                      1/1     Running   0          15h   172.16.0.42   vpc-open-master003   <none>
kube-apiserver-vpc-open-master001            1/1     Running   0          16h   172.16.0.41   vpc-open-master001   <none>
kube-apiserver-vpc-open-master002            1/1     Running   0          15h   172.16.0.43   vpc-open-master002   <none>
kube-apiserver-vpc-open-master003            1/1     Running   0          15h   172.16.0.42   vpc-open-master003   <none>
kube-controller-manager-vpc-open-master001   1/1     Running   1          16h   172.16.0.41   vpc-open-master001   <none>
kube-controller-manager-vpc-open-master002   1/1     Running   0          15h   172.16.0.43   vpc-open-master002   <none>
kube-controller-manager-vpc-open-master003   1/1     Running   0          15h   172.16.0.42   vpc-open-master003   <none>
kube-flannel-ds-amd64-dzq5b                  1/1     Running   0          14h   172.16.0.44   vpc-open-node002     <none>
kube-flannel-ds-amd64-hnf2f                  1/1     Running   0          15h   172.16.0.45   vpc-open-node001     <none>
kube-flannel-ds-amd64-jwrks                  1/1     Running   0          16h   172.16.0.43   vpc-open-master002   <none>
kube-flannel-ds-amd64-nxrx2                  1/1     Running   0          15h   172.16.0.42   vpc-open-master003   <none>
kube-flannel-ds-amd64-zmwbx                  1/1     Running   0          16h   172.16.0.41   vpc-open-master001   <none>
kube-proxy-97mfb                             1/1     Running   0          16h   172.16.0.43   vpc-open-master002   <none>
kube-proxy-h8ctq                             1/1     Running   0          16h   172.16.0.41   vpc-open-master001   <none>
kube-proxy-mw2l7                             1/1     Running   0          15h   172.16.0.45   vpc-open-node001     <none>
kube-proxy-qxztv                             1/1     Running   0          14h   172.16.0.44   vpc-open-node002     <none>
kube-proxy-vf2k6                             1/1     Running   0          15h   172.16.0.42   vpc-open-master003   <none>
kube-scheduler-vpc-open-master001            1/1     Running   1          16h   172.16.0.41   vpc-open-master001   <none>
kube-scheduler-vpc-open-master002            1/1     Running   0          15h   172.16.0.43   vpc-open-master002   <none>
kube-scheduler-vpc-open-master003            1/1     Running   0          15h   172.16.0.42   vpc-open-master003   <none>
kubernetes-dashboard-85477d54d7-72bjj        1/1     Running   0          22s   10.244.3.2    vpc-open-node001     <none>
```
3. 创建一个管理员用户
```
# 生成配置文件
cat > kubernetes-dashboard-rbac.yaml << EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
EOF
# 创建用户
kubectl create -f kubernetes-dashboard-rbac.yaml
```
4. 登录dashboard
在浏览器中访问地址：https://47.110.19.11/   #这块在阿里云做负载均衡了
![图片.png](https://upload-images.jianshu.io/upload_images/6064401-e1e07062ebe2bd64.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
# 运行命令查看secret列表
# kubectl get secrets -n kube-system
NAME                                             TYPE                                  DATA   AGE
admin-token-9v6ql                                kubernetes.io/service-account-token   3      5m32s
attachdetach-controller-token-5b48q              kubernetes.io/service-account-token   3      16h
bootstrap-signer-token-cd8pr                     kubernetes.io/service-account-token   3      16h
bootstrap-token-jjv5r2                           bootstrap.kubernetes.io/token         6      16h
certificate-controller-token-8fwzr               kubernetes.io/service-account-token   3      16h
clusterrole-aggregation-controller-token-6bw5h   kubernetes.io/service-account-token   3      16h
coredns-token-z8fqw                              kubernetes.io/service-account-token   3      16h
cronjob-controller-token-bszlt                   kubernetes.io/service-account-token   3      16h
daemon-set-controller-token-k9x27                kubernetes.io/service-account-token   3      16h
default-token-n6wsp                              kubernetes.io/service-account-token   3      16h
deployment-controller-token-zd5hr                kubernetes.io/service-account-token   3      16h
disruption-controller-token-clbvw                kubernetes.io/service-account-token   3      16h
endpoint-controller-token-df2nv                  kubernetes.io/service-account-token   3      16h
expand-controller-token-xrq62                    kubernetes.io/service-account-token   3      16h
flannel-token-btkhc                              kubernetes.io/service-account-token   3      16h
generic-garbage-collector-token-9klpk            kubernetes.io/service-account-token   3      16h
horizontal-pod-autoscaler-token-vqjhc            kubernetes.io/service-account-token   3      16h
job-controller-token-nph48                       kubernetes.io/service-account-token   3      16h
kube-proxy-token-7vzj6                           kubernetes.io/service-account-token   3      16h
kubernetes-dashboard-certs                       Opaque                                0      9m50s
kubernetes-dashboard-key-holder                  Opaque                                2      9m44s
kubernetes-dashboard-token-r9bbl                 kubernetes.io/service-account-token   3      9m51s
namespace-controller-token-jhxxt                 kubernetes.io/service-account-token   3      16h
node-controller-token-cwndg                      kubernetes.io/service-account-token   3      16h
persistent-volume-binder-token-2lv28             kubernetes.io/service-account-token   3      16h
pod-garbage-collector-token-m9kln                kubernetes.io/service-account-token   3      16h
pv-protection-controller-token-s4hnb             kubernetes.io/service-account-token   3      16h
pvc-protection-controller-token-r5cgj            kubernetes.io/service-account-token   3      16h
replicaset-controller-token-4xv99                kubernetes.io/service-account-token   3      16h
replication-controller-token-tkcck               kubernetes.io/service-account-token   3      16h
resourcequota-controller-token-pm258             kubernetes.io/service-account-token   3      16h
service-account-controller-token-p86s7           kubernetes.io/service-account-token   3      16h
service-controller-token-blf7k                   kubernetes.io/service-account-token   3      16h
statefulset-controller-token-b48r9               kubernetes.io/service-account-token   3      16h
token-cleaner-token-zh8rd                        kubernetes.io/service-account-token   3      16h
ttl-controller-token-x7kz6                       kubernetes.io/service-account-token   3      16h
# 第一个为admin-token-9v6ql的secret，运行命令查看secret详情
# kubectl describe secret admin-token-9v6ql -n kube-system
Name:         admin-token-9v6ql
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin
              kubernetes.io/service-account.uid: 43ee5cd4-f2b6-11e8-b0d3-00163e199148

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi10b2tlbi05djZxbCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjQzZWU1Y2Q0LWYyYjYtMTFlOC1iMGQzLTAwMTYzZTE5OTE0OCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTphZG1pbiJ9.uj1kkIy39qvJFQO-Aagwd73oZNJT5sg9Xc0lDrcMtFEXkrYCwIbsV0ecF412EZ-gVVGZPBYVh1TRt2_Ffmv5XZd65F-E6O9V-eps0rhdlTuOHyipCLqrO2-4DOUMG4H3Pu6Lraz_fPekhjc__AgzKS882kBdJPLWM5vbRys6j3MtStNXoentWwNpUkiL_ezxHrI2Du4Xm6paZMw9O_JKRkDX-h_vx1ik6NyPD71-_6JJwZO3vx40ByN7xhM3aJ3eRyCf0yFnagAOg5SoLShjsJs_FTCeDM8PQuvxGiAoOT_y2rfiH75UJd-7fZNyZTKhnjm47yeDvjs3JbB3gBE5Pw
```
到dashboard登录界面，选择“令牌”，复制token的值到“输入令牌”文本框中，登录

![图片.png](https://upload-images.jianshu.io/upload_images/6064401-0b79a40943d50ef3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

部署metrics-server
```
# 新建目录
# mkdir /data/kubernetes/metrics-server
# cd /data/kubernetes/metrics-server
# 下载文件到本地
# for file in aggregated-metrics-reader.yaml auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml; do  wget https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/$file;done
# 修改images地址
# cat aggregated-metrics-reader.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:aggregated-metrics-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
rules:
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

# cat auth-reader.yaml
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system

# cat metrics-server-deployment.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      volumes:
      # mount in tmp so we can safely use from-scratch images and/or read-only containers
      - name: tmp-dir
        emptyDir: {}
      containers:
      - name: metrics-server
        image: hub.huoban.com/k8s/metrics-server-amd64:v0.2.1
        imagePullPolicy: IfNotPresent
        command:
          - /metrics-server
          - --source=kubernetes.summary_api:https://kubernetes.default?kubeletHttps=true&kubeletPort=10250&insecure=true
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp

# cat resource-reader.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  - nodes/stats
  - namespaces
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - "extensions"
  resources:
  - deployments
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system

# cat auth-delegator.yaml
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system

# cat metrics-apiservice.yaml
---
apiVersion: apiregistration.k8s.io/v1beta1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  group: metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100

# cat metrics-server-service.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    kubernetes.io/name: "Metrics-server"
spec:
  selector:
    k8s-app: metrics-server
  ports:
  - port: 443
    protocol: TCP
    targetPort: 443

# 启动
# kubectl apply -f ./
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
serviceaccount/metrics-server created
deployment.extensions/metrics-server created
service/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created

# 查看pod状态
# kubectl get pods -n kube-system -o wide|grep metrics-server
metrics-server-667fc65b-mw6lh                1/1     Running   0          19s   10.244.3.5    vpc-open-node001     <none>
```
等待几分钟，然后查看收集的信息
```
# kubectl top nodes
NAME                 CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
vpc-open-master001   162m         8%     1546Mi          41%
vpc-open-master002   132m         6%     1471Mi          39%
vpc-open-master003   79m          3%     1427Mi          38%
vpc-open-node001     42m          2%     853Mi           23%
vpc-open-node002     26m          1%     759Mi           20%
# kubectl top pods -n kube-system
NAME                                         CPU(cores)   MEMORY(bytes)
coredns-6c66ffc55b-mrsqg                     1m           12Mi
coredns-6c66ffc55b-nl686                     1m           10Mi
etcd-vpc-open-master001                      29m          273Mi
etcd-vpc-open-master002                      18m          260Mi
etcd-vpc-open-master003                      17m          264Mi
kube-apiserver-vpc-open-master001            29m          505Mi
kube-apiserver-vpc-open-master002            62m          472Mi
kube-apiserver-vpc-open-master003            16m          433Mi
kube-controller-manager-vpc-open-master001   27m          72Mi
kube-controller-manager-vpc-open-master002   0m           12Mi
kube-controller-manager-vpc-open-master003   0m           14Mi
kube-flannel-ds-amd64-dzq5b                  1m           18Mi
kube-flannel-ds-amd64-hnf2f                  1m           14Mi
kube-flannel-ds-amd64-jwrks                  1m           14Mi
kube-flannel-ds-amd64-nxrx2                  1m           14Mi
kube-flannel-ds-amd64-zmwbx                  1m           12Mi
kube-proxy-97mfb                             2m           12Mi
kube-proxy-h8ctq                             2m           12Mi
kube-proxy-mw2l7                             2m           11Mi
kube-proxy-qxztv                             2m           12Mi
kube-proxy-vf2k6                             2m           12Mi
kube-scheduler-vpc-open-master001            7m           13Mi
kube-scheduler-vpc-open-master002            6m           11Mi
kube-scheduler-vpc-open-master003            7m           11Mi
kubernetes-dashboard-85477d54d7-72bjj        3m           12Mi
metrics-server-667fc65b-mw6lh                1m           9Mi
```
部署ingress-nginx
```
# 下载官方提供的安装文件
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
# 修改文件，网络模式修改成hostNetwork
# vim mandatory.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

data:
  proxy-body-size: "200m"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
    resources:
      - ingresses/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: nginx-ingress-role
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx"
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      hostNetwork: true
      serviceAccountName: nginx-ingress-serviceaccount
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.21.0
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 33
            runAsUser: 33
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              hostPort: 80
              containerPort: 80
            - name: https
              hostPort: 443
              containerPort: 443
          volumeMounts:
          - name: ssl
            mountPath: /etc/ingress-controller/ssl
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
      volumes:
      - name: ssl
        nfs:
          path: /conf/global_sign_ssl
          server: 0c54248c72-vok17.cn-hangzhou.nas.aliyuncs.com

---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
    - name: https
      port: 443
      targetPort: 443
      protocol: TCP
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
# kubectl apply -f mandatory.yaml
# 查看运行的pod
# kubectl get pods -n ingress-nginx -o wide
NAME                                        READY   STATUS    RESTARTS   AGE   IP             NODE                     NOMINATED NODE
nginx-ingress-controller-5c4679db66-vgdxp   1/1     Running   0          24m   172.16.0.45   vpc-open-node001   <none>
nginx-ingress-controller-5c4679db66-wpjqz   1/1     Running   0          24m   172.16.0.44   vpc-open-node002   <none>
```
