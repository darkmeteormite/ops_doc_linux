二、Kubernetes系列之kubeadm部署多节点master集群

版本信息
```
linux   Centos7
kubernetes v1.14.5
docker v18.06.1-ce
```
节点信息
```
VIP:47.110.19.11    阿里云负载均衡
```
安装前准备
```
开始部署前确保所有节点网络正常，能访问公网。主要操作都在VPC-OPEN-MASTER001节点进行，设置VPC-OPEN-MASTER001可以免密码登陆其他节点。所有操作都使用root用户身份进行。
```
服务器说明
```
我们这里使用的是五台centos-7.6的虚拟机，具体信息如下表：
系统类型	IP地址	        节点角色	CPU	Memory	Hostname
centos-7.6	192.168.3.42	master	    >=2	>=4G	master01
centos-7.6	192.168.3.43	master	    >=2	>=4G	master02
centos-7.6	192.168.3.44	master	    >=2	>=4G	master03
centos-7.6	192.168.3.45	worker	    >=2	>=4G	node01
centos-7.6	192.168.3.46	worker	    >=2	>=4G	node02
```

一、环境准备
>1、设置主机名
```
# 查看主机名
$ hostname
# 修改主机名
$ hostnamectl set-hostname huoban-k8s-master01
# 配置host，使所有节点之间可以通过hostname互相访问

```
>2、配置hosts解析
```
# vim /etc/hosts
192.168.3.42 huoban-k8s-master01	master01
192.168.3.43 huoban-k8s-master02	master02
192.168.3.44 huoban-k8s-master03	master03
192.168.3.45 huoban-k8s-node01      node01
192.168.3.46 huoban-k8s-node02      node02
```
>3、安装依赖包
```
# 更新yum
$ yum update
# 安装依赖包
$ yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
```
>4、关闭防火墙、swap，重置iptables
```
# 关闭防火墙
$ systemctl stop firewalld && systemctl disable firewalld
# 重置iptables
$ iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT
# 关闭swap
$ swapoff -a
$ sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab
# 关闭selinux
$ setenforce 0
# 关闭dnsmasq(否则可能导致docker容器无法解析域名)
$ service dnsmasq stop && systemctl disable dnsmasq
```
>5、系统参数设置
```
# 制作配置文件
$ cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF
# 生效文件
$ sysctl -p /etc/sysctl.d/kubernetes.conf
```
二、安装docker
```
# 使用阿里云镜像仓库
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
# 安装docker
查看可以安装的版本
yum list docker-ce --showduplicates|sort -r
yum install -y docker-ce-18.06.1.ce-3

# 设置docker启动参数（可选）
# - graph: 设置docker数据目录：选择比较大的分区（我这里是根目录就不需要配置了，默认为/var/lib/docker）
# - exec-opts: 设置cgroup driver（默认是cgroupfs，不推荐设置systemd）
# - registry-mirrors 配置docker镜像加速

cat > /etc/docker/daemon.json <<EOF
{
    "graph": "/docker/data/path",
    "exec-opts": ["native.cgroupdriver=cgroupfs"],
    "registry-mirrors":["https://k9e55i4n.mirror.aliyuncs.com"]
}
EOF

# 启动docker服务并加入开机启动项
systemctl start docker && systemctl enable docker
```
三、安装 kubeadm, kubelet 和 kubectl

>1、配置yum源
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
>2、安装kubelet,kubeadm,kubectl
```
# 找到安装的版本号
yum list kubeadm --showduplicates | sort -r

#安装指定版本
yum install -y kubelet-1.14.5 kubeadm-1.14.5 kubectl-1.14.5
```
>3、查看安装情况
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

四、配置系统相关参数

```
#以下操作在所有节点操作
#!/bin/bash
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

五、配置阿里云负载均衡及修改证书

```
#下载源码包
cd /usr/local/src/
git clone https://github.com/kubernetes/kubernetes.git
git checkout -b kubernetes-1.14.5 origin/release-1.14

#docker拉取修改镜像,对应的版本有1.11.5、1.12.3、1.13.0、1.13.2、1.13.4
docker pull icyboy/k8s_build:v1.14.1

#k8s-1.14以上修改有效期的两个文件,找到NotAfter字段并修改日期有效期
/usr/local/src/kubernetes/staging/src/k8s.io/client-go/util/cert/cert.go
NotAfter:              now.Add(duration365d * 100).UTC(),
/usr/local/src/kubernetes/cmd/kubeadm/app/util/pkiutil/pki_helpers.go
NotAfter:     time.Now().Add(duration365d * 100).UTC(),   #改成100年

#执行编译
docker run --rm -v /usr/local/src/kubernetes:/go/src/k8s.io/kubernetes -it icyboy/k8s_build:v1.14.1 bash
# 编译kubeadm, 这里主要编译kubeadm 即可
make all WHAT=cmd/kubeadm GOFLAGS=-v

# 编译kubelet
make all WHAT=cmd/kubelet GOFLAGS=-v

# 编译kubectl
make all WHAT=cmd/kubectl GOFLAGS=-v

#编译完产物在 /usr/local/src/kubernetes/_output/local/bin/linux/amd64 目录下
#将kubeadm 文件拷贝出来，替换系统中的kubeadm

#用新的kubeadm 替换官方的kubeadm
chmod +x kubeadm && \cp -f kubeadm /usr/bin
```

六、部署第一个主节点
>1、配置kubelet
```
### 以下操作需要在所有节点上执行
# 重新载入kubelet系统配置
systemctl daemon-reload
# 设置开机启动，暂时不启动kubelet
systemctl enable kubelet
```
>2、根据配置文件初始化集群
```
# 使用kubeadm-config.yaml配置k8s1.14.5集群

# cat init.sh
LOAD_BALANCER_DNS="47.110.19.11"
LOAD_BALANCER_PORT="6443"
# 生成kubeadm配置文件
cat > kubeadm-master.config <<EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
# kubernetes版本
kubernetesVersion: v1.14.5
# 使用国内阿里镜像
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers

apiServer:
  certSANs:
  - "$LOAD_BALANCER_DNS"
controlPlaneEndpoint: "$LOAD_BALANCER_DNS:$LOAD_BALANCER_PORT"

networking:
  podSubnet: 10.244.0.0/16
EOF

#初始化k8s集群
kubeadm init --config=kubeadm-master.config
```

>3、验证证书有效时间
```
# cd /etc/kubernetes/pki
# for crt in $(find /etc/kubernetes/pki/ -name "*.crt"); do openssl x509 -in $crt -noout -dates; done 
 
notBefore=Aug 20 07:43:46 2019 GMT 
notAfter=Jul 27 07:43:46 2119 GMT 
notBefore=Aug 20 07:43:45 2019 GMT 
notAfter=Jul 27 07:43:45 2119 GMT 
notBefore=Aug 20 07:43:46 2019 GMT 
notAfter=Jul 27 07:43:47 2119 GMT 
notBefore=Aug 20 07:43:46 2019 GMT 
notAfter=Jul 27 07:43:47 2119 GMT 
notBefore=Aug 20 07:43:46 2019 GMT 
notAfter=Jul 27 07:43:47 2119 GMT 
notBefore=Aug 20 07:43:46 2019 GMT 
notAfter=Jul 27 07:43:46 2119 GMT 
notBefore=Aug 20 07:43:45 2019 GMT 
notAfter=Jul 27 07:43:46 2119 GMT 
notBefore=Aug 20 07:43:45 2019 GMT 
notAfter=Jul 27 07:43:45 2119 GMT 
notBefore=Aug 20 07:43:45 2019 GMT 
notAfter=Jul 27 07:43:45 2119 GMT 
notBefore=Aug 20 07:43:45 2019 GMT 
notAfter=Jul 27 07:43:45 2119 GMT 
 
# notBefore代表生效时间，notAfter代表失效时间。 
```

>4、安装网络插件
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
>5、拷贝master证书到其他节点
```
# cat scp.sh
USER=root
CONTROL_PLANE_IPS="192.168.3.43 192.168.3.44"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:etcd-ca.crt
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:etcd-ca.key
    scp /etc/kubernetes/admin.conf "${USER}"@$host:
    ssh ${USER}@${host} 'mkdir -p /etc/kubernetes/pki/etcd'
    ssh ${USER}@${host} 'mv /${USER}/ca.crt /etc/kubernetes/pki/'
    ssh ${USER}@${host} 'mv /${USER}/ca.key /etc/kubernetes/pki/'
    ssh ${USER}@${host} 'mv /${USER}/sa.pub /etc/kubernetes/pki/'
    ssh ${USER}@${host} 'mv /${USER}/sa.key /etc/kubernetes/pki/'
    ssh ${USER}@${host} 'mv /${USER}/front-proxy-ca.crt /etc/kubernetes/pki/'
    ssh ${USER}@${host} 'mv /${USER}/front-proxy-ca.key /etc/kubernetes/pki/'
    ssh ${USER}@${host} 'mv /${USER}/etcd-ca.crt /etc/kubernetes/pki/etcd/ca.crt'
    ssh ${USER}@${host} 'mv /${USER}/etcd-ca.key /etc/kubernetes/pki/etcd/ca.key'
    ssh ${USER}@${host} 'mv /${USER}/admin.conf /etc/kubernetes/admin.conf'
done
```

七、其他节点上部署

```
#master

kubeadm join 47.110.19.11:6443 --token qlrq5y.1yhm3rz9r7ynfqf1 --discovery-token-ca-cert-hash sha256:62579157003c3537deb44b30f652c500e7fa6505b5ef6826d796ba1245283899 --experimental-control-plane

#node

kubeadm join 47.110.19.11:6443 --token qlrq5y.1yhm3rz9r7ynfqf1 --discovery-token-ca-cert-hash sha256:62579157003c3537deb44b30f652c500e7fa6505b5ef6826d796ba1245283899
```

