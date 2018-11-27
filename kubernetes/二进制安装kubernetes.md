一、创建TLS证书和密钥

1、安装 CFSSL
```
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
chmod +x cfssl_linux-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl

wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssljson_linux-amd64
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl-certinfo_linux-amd64
mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
```
2、创建CA
```
创建 CA 配置文件
mkdir /root/ssl
cd /root/ssl
cfssl print-defaults config > config.json
cfssl print-defaults csr > csr.json
# 根据config.json文件的格式创建如下的ca-config.json文件
# 过期时间设置成了 87600h
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

字段说明

ca-config.json：可以定义多个 profiles，分别指定不同的过期时间、使用场景等参数；后续在签名证书时使用某个 profile；
signing：表示该证书可用于签名其它证书；生成的 ca.pem 证书中 CA=TRUE；
server auth：表示client可以用该 CA 对server提供的证书进行验证；
client auth：表示server可以用该CA对client提供的证书进行验证；
```
3、创建CA证书签名请求
```
创建 ca-csr.json 文件，内容如下：
cat > ca-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "yunweibu",
      "OU": "huoban"
    }
  ],
    "ca": {
       "expiry": "87600h"
    }
}
EOF
"CN"：Common Name，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法；
"O"：Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)；
```
4、生成CA证书和私钥
```
# cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# ls ca*
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```
5、创建Kubernetes证书
```
cat > kubernetes-csr.json << EOF
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "192.168.3.204",
      "192.168.3.205",
      "192.168.3.206",
      "192.168.3.207",
      "10.254.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "yunweibu",
            "OU": "huoban"
        }
    ]
}
EOF
```
6、生成kubernetes证书和私钥
```
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

# ls kubernetes*
kubernetes.csr  kubernetes-csr.json  kubernetes-key.pem  kubernetes.pem
```
7、创建admin证书
```
cat > admin-csr.json << EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "huoban"
    }
  ]
}
EOF
```
8、生成 admin 证书和私钥：
```
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

# ls admin*
admin.csr  admin-csr.json  admin-key.pem  admin.pem
```
9、创建kube-proxy证书
```
cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "yunweibu",
      "OU": "huoban"
    }
  ]
}
EOF
```
10、生成 kube-proxy 客户端证书和私钥
```
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy

# ls kube-proxy*
kube-proxy.csr  kube-proxy-csr.json  kube-proxy-key.pem  kube-proxy.pem
```
11、校验证书
```
1、使用openssl命令
# openssl x509  -noout -text -in  kubernetes.pem
2、使用cfssl-certinfo命令
# cfssl-certinfo -cert kubernetes.pem
```
12、分发证书
```
mkdir -p /etc/kubernetes/ssl
cp *.pem /etc/kubernetes/ssl
```
二、安装配置高可用ETCD。
```
1、修改host文件及修改主机名：
192.168.3.206   K8S-VPC-NODE001
192.168.3.204   K8S-VPC-NODE002
192.168.3.205   K8S-VPC-NODE003
192.168.3.207   K8S-VPC-NODE004


2、下载安装etd：
wget https://github.com/etcd-io/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz
tar zxvf etcd-v3.3.9-linux-amd64.tar.gz 
cp etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
mkdir /var/lib/etcd     #etcd的数据目录
mkdir /etc/etcd        #etcd的配置文件目录

3、编写etcd的配置文件
node1
cat > /etc/etcd/etcd.conf << EOF
# [member]
ETCD_NAME=node1
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.3.206:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.3.206:2379"

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.3.206:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.3.206:2379"
EOF

node2
cat > /etc/etcd/etcd.conf << EOF
# [member]
ETCD_NAME=node2
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.3.204:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.3.204:2379"

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.3.204:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.3.204:2379"
EOF

node3
cat > /etc/etcd/etcd.conf << EOF
# [member]
ETCD_NAME=node3
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.3.205:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.3.205:2379"

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.3.205:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.3.205:2379"
EOF

4、编写etcd的启动文件
# vim /usr/lib/systemd/system/etcd.service 
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/local/bin/etcd \
  --name ${ETCD_NAME} \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  --peer-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --peer-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  --trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --initial-advertise-peer-urls ${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  --listen-peer-urls ${ETCD_LISTEN_PEER_URLS} \
  --listen-client-urls ${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
  --advertise-client-urls ${ETCD_ADVERTISE_CLIENT_URLS} \
  --initial-cluster-token ${ETCD_INITIAL_CLUSTER_TOKEN} \
  --initial-cluster node1=https://192.168.3.206:2380,node2=https://192.168.3.204:2380,node3=https://192.168.3.205:2380 \
  --initial-cluster-state new \
  --data-dir=${ETCD_DATA_DIR}
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

5、启动etcd并检查

启动

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
systemctl status etcd

检查

# etcdctl   --ca-file=/etc/kubernetes/ssl/ca.pem   --cert-file=/etc/kubernetes/ssl/kubernetes.pem   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem   cluster-health

```

三、在Master上安装kubectl及生成配置文件
```
1、下载安装kubectl
wget https://dl.k8s.io/v1.9.2/kubernetes-client-linux-amd64.tar.gz
tar -xzvf kubernetes-client-linux-amd64.tar.gz
cp kubernetes/client/bin/kube* /usr/bin/
chmod a+x /usr/bin/kube*

2、创建kubectl kubeconfig文件

export KUBE_APISERVER="https://192.168.3.206:6443"
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER}
# 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem
# 设置上下文参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin
# 设置默认上下文
kubectl config use-context kubernetes

3、创建TLS Bootstrapping Token

export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
cp token.csv /etc/kubernetes/
scp token.csv root@K8S-VPC-NODE002:/etc/kubernetes/
scp token.csv root@K8S-VPC-NODE003:/etc/kubernetes/
scp token.csv root@K8S-VPC-NODE004:/etc/kubernetes/


4、创建kubelet bootstrapping kubeconfig 文件

cd /etc/kubernetes
export KUBE_APISERVER="https://192.168.3.206:6443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

5、创建 kube-proxy kubeconfig 文件

export KUBE_APISERVER="https://https://192.168.3.206:6443"
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

6、分发kubeconfig文件
scp bootstrap.kubeconfig kube-proxy.kubeconfig root@K8S-VPC-NODE002:/etc/kubernetes/
scp bootstrap.kubeconfig kube-proxy.kubeconfig root@K8S-VPC-NODE003:/etc/kubernetes/
scp bootstrap.kubeconfig kube-proxy.kubeconfig root@K8S-VPC-NODE004:/etc/kubernetes/
```

四、在master安装kube-apiserver,kube-scheduler,kube-controller-manager
```
1、下载最新的二进制文件
wget https://dl.k8s.io/v1.9.2/kubernetes-server-linux-amd64.tar.gz
tar -xzvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes
tar -xzvf  kubernetes-src.tar.gz
cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kube-proxy,kubelet} /usr/local/bin/

2、配置启动kube-apiserver

启动文件

# vim /usr/lib/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Service
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/apiserver
ExecStart=/usr/local/bin/kube-apiserver \
        $KUBE_LOGTOSTDERR \
        $KUBE_LOG_LEVEL \
        $KUBE_ETCD_SERVERS \
        $KUBE_API_ADDRESS \
        $KUBE_API_PORT \
        $KUBELET_PORT \
        $KUBE_ALLOW_PRIV \
        $KUBE_SERVICE_ADDRESSES \
        $KUBE_ADMISSION_CONTROL \
        $KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

配置文件

# vim /etc/kubernetes/config
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=0"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
KUBE_MASTER="--master=http://0.0.0.0:8080"


# vim /etc/kubernetes/apiserver

###
## kubernetes system config
##
## The following values are used to configure the kube-apiserver
##
#
## The address on the local server to listen to.
KUBE_API_ADDRESS="--advertise-address=0.0.0.0 --bind-address=0.0.0.0 --insecure-bind-address=0.0.0.0"
#
## The port on the local server to listen on.
#KUBE_API_PORT="--port=8080"
#
## Port minions listen on
#KUBELET_PORT="--kubelet-port=10250"
#
## Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=https://192.168.3.206:2379,https://192.168.3.204:2379,https://192.168.3.205:2379"
#
## Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
#
## default admission control policies
KUBE_ADMISSION_CONTROL="--admission-control=ServiceAccount,NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"
#
## Add your own!
KUBE_API_ARGS="--authorization-mode=Node,RBAC --runtime-config=rbac.authorization.k8s.io/v1beta1 --kubelet-https=true --enable-bootstrap-token-auth --token-auth-file=/etc/kubernetes/token.csv --service-node-port-range=30000-32767 --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem --etcd-cafile=/etc/kubernetes/ssl/ca.pem --etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem --etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem --enable-swagger-ui=true --apiserver-count=3 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/var/lib/audit.log --event-ttl=1h"

3、启动kube-apiserver

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver


4、配置启动kube-controller-manager

启动文件

# vim /usr/lib/systemd/system/kube-controller-manager.service  
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/controller-manager
ExecStart=/usr/local/bin/kube-controller-manager \
        $KUBE_LOGTOSTDERR \
        $KUBE_LOG_LEVEL \
        $KUBE_MASTER \
        $KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

配置文件
 
# vim /etc/kubenetes/controller-manager

###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--address=127.0.0.1 --service-cluster-ip-range=10.254.0.0/16 --cluster-name=kubernetes --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem --cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  --service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem --root-ca-file=/etc/kubernetes/ssl/ca.pem --leader-elect=true"

启动kube-controller-manager

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager

5、配置启动kube-scheduler

启动文件

# vim /usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler Plugin
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/scheduler
ExecStart=/usr/local/bin/kube-scheduler \
            $KUBE_LOGTOSTDERR \
            $KUBE_LOG_LEVEL \
            $KUBE_MASTER \
            $KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

配置文件

# vim /etc/kubernetes/scheduler
###
# kubernetes scheduler config

# default config should be adequate

# Add your own!
KUBE_SCHEDULER_ARGS="--leader-elect=true --address=127.0.0.1"

启动scheduler

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler
systemctl status kube-scheduler

验证

# kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health":"true"}
etcd-1               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
```

五、在所有节点安装flannel网络插件

```
1、下载软件包
wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz
tar xf flannel-v0.10.0-linux-amd64.tar.gz
mkdir /usr/libexec/flannel
cp mk-docker-opts.sh /usr/libexec/flannel
cp flanneld /usr/local/bin

2、配置启动flannel

启动文件
# vim /usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/local/bin/flanneld  \
  -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} \
  -etcd-prefix=${FLANNEL_ETCD_PREFIX} \
  $FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service

配置文件
# vim /etc/sysconfig/flanneld
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD_ENDPOINTS="https://192.168.3.206:2379,https://192.168.3.204:2379,https://192.168.3.205:2379"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_PREFIX="/kube-centos/network"

# Any additional options that you want to pass
FLANNEL_OPTIONS="-etcd-cafile=/etc/kubernetes/ssl/ca.pem -etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem -etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem"

在etcd中创建网络配置（在master配置）
etcdctl --endpoints=https://192.168.3.206:2379,https://192.168.3.204:2379,https://192.168.3.205:2379 \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  mkdir /kube-centos/network
etcdctl --endpoints=https://192.168.3.206:2379,https://192.168.3.204:2379,https://192.168.3.205:2379 \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  mk /kube-centos/network/config '{"Network":"172.30.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}'
  
启动flannel

systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld
systemctl status flanneld

验证

# etcdctl --endpoints=${ETCD_ENDPOINTS} \
    --ca-file=/etc/kubernetes/ssl/ca.pem \
    --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
    --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
    ls /kube-centos/network/subnets
/kube-centos/network/subnets/172.30.27.0-24
/kube-centos/network/subnets/172.30.19.0-24
/kube-centos/network/subnets/172.30.42.0-24
/kube-centos/network/subnets/172.30.94.0-24

# etcdctl --endpoints=${ETCD_ENDPOINTS} \
   --ca-file=/etc/kubernetes/ssl/ca.pem \
   --cert-file=/etc/kubernetes/ssl/kubernetes.pem \
   --key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
   get /kube-centos/network/config
{"Network":"172.30.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}
```


六、在所有节点上安装配置docker、kubelet、kube-proxy
```
1、安装docker
# yum install -y https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm  https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm

2、给kubelet赋予权限（主节点上执行）

cd /etc/kubernetes
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap

3、分发kubelet和kube-proxy二进制文件
scp /root/soft/kubernetes/server/bin/{kube-proxy,kubelet} root@K8S-VPC-NODE002:/usr/local/bin/
scp /root/soft/kubernetes/server/bin/{kube-proxy,kubelet} root@K8S-VPC-NODE003:/usr/local/bin/
scp /root/soft/kubernetes/server/bin/{kube-proxy,kubelet} root@K8S-VPC-NODE004:/usr/local/bin/
mkdir /var/lib/kubelet

4、配置和启动kubelet

# vim /usr/lib/systemd/system/kubelet.service

[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service
[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/usr/local/bin/kubelet \
--address=192.168.3.206 \
--hostname-override=192.168.3.206 \
--pod-infra-container-image=docker.io/kubernetes/pause \
--experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
--kubeconfig=/etc/kubernetes/ssl/kubelet.kubeconfig \
--cert-dir=/etc/kubernetes/ssl \
--hairpin-mode promiscuous-bridge \
--allow-privileged=true \
--serialize-image-pulls=false \
--logtostderr=true \
--cgroup-driver=systemd \
--cluster_dns=10.254.0.2 \
--cluster_domain=cluster.local \
--v=2
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target

启动kubelet
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet

通过kubelet的TLS证书请求
kubelet 首次启动时向 kube-apiserver 发送证书签名请求，必须通过后 kubernetes 系统才会将该 Node 加入到集群。
1、查看未授权的请求：
 kubectl get csr
2、通过csr请求：
kubectl get csr | awk '/Pending/ {print $1}' | xargs kubectl certificate approve
$ kubectl get nodes


配置安装kube-proxy
yum install -y conntrack-tools

启动文件
vim /usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
ExecStart=/usr/local/bin/kube-proxy \
         --bind-address=192.168.3.206 \
         --hostname-override=192.168.3.206 \
         --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
         --cluster-cidr=10.254.0.0/16
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

启动kube-proxy
systemctl daemon-reload
systemctl enable kube-proxy
systemctl start kube-proxy
systemctl status kube-proxy

```
