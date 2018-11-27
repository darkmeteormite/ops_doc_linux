```
192.168.3.206	K8S-VPC-NODE001
192.168.3.204	K8S-VPC-NODE002
192.168.3.205	K8S-VPC-NODE003
192.168.3.207	K8S-VPC-NODE004
```


一、master安装基本软件及下载镜像

```
#!/bin/bash
#关闭Selinu
setenforce  0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

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

#添加yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y net-tools wget vim  ntpdate
# 安装docker 
yum install -y https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm  https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm
#wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
#yum install -y docker-ce
systemctl enable docker && systemctl start docker
systemctl enable docker.service
yum install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet && systemctl start kubelet
#!/bin/bash
images=(kube-proxy-amd64:v1.11.0 kube-scheduler-amd64:v1.11.0 kube-controller-manager-amd64:v1.11.0 kube-apiserver-amd64:v1.11.0
etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3)
for imageName in ${images[@]} ; do
  docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
  docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName k8s.gcr.io/$imageName
  #docker rmi registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
done
# 个人新加的一句，V 1.11.0 必加
docker tag da86e6ba6ca1 k8s.gcr.io/pause:3.1
```

二、安装master节点

```
执行master节点的初始化
# kubeadm init --kubernetes-version=v1.11.0 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=0.0.0.0
[init] using Kubernetes version: v1.11.0
[preflight] running pre-flight checks
I0802 12:17:21.291170   14414 kernel_validator.go:81] Validating kernel version
I0802 12:17:21.291251   14414 kernel_validator.go:96] Validating kernel config
	[WARNING SystemVerification]: docker version is greater than the most recently validated version. Docker version: 18.06.0-ce. Max validated version: 17.03
[preflight/images] Pulling images required for setting up a Kubernetes cluster
[preflight/images] This might take a minute or two, depending on the speed of your internet connection
[preflight/images] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[preflight] Activating the kubelet service
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [master kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 114.55.244.13]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated sa key and public key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] Generated etcd/ca certificate and key.
[certificates] Generated etcd/server certificate and key.
[certificates] etcd/server serving cert is signed for DNS names [master localhost] and IPs [127.0.0.1 ::1]
[certificates] Generated etcd/peer certificate and key.
[certificates] etcd/peer serving cert is signed for DNS names [master localhost] and IPs [114.55.244.13 127.0.0.1 ::1]
[certificates] Generated etcd/healthcheck-client certificate and key.
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/kubernetes/pki"
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
[apiclient] All control plane components are healthy after 39.001631 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.11" in namespace kube-system with the configuration for the kubelets in the cluster
[markmaster] Marking the node master as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node master as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "master" as an annotation
[bootstraptoken] using token: kvpswp.8112qywcdqxwkw6g
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

  kubeadm join 192.168.3.206:6443 --token 8wj3pz.6pgl3mux8imyqfzm --discovery-token-ca-cert-hash sha256:abddd5ed3a8496f061c90b5401bf24ed4ba5a1c8706e10a5c89a814933610ece

看到以上信息表示Master节点已经初始化成功了。如果需要用普通用户管理集群，可以按照提示进行操作，如果是使用root用户管理，执行下面的命令。
# echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile    #添加环境变量
# kubectl get nodes    # 查看集群节点
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    3h        v1.11.1
```

三、Master节点的网络配置

```
# sysctl net.bridge.bridge-nf-call-iptables=1
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
执行成功后，Master并不能马上变成Ready状态，稍等几分钟，就可以看到所有状态都正常了。
# kubectl get pods --all-namespaces
NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
kube-system   coredns-78fcdf6894-7pdgp                1/1       Running   0          3h
kube-system   coredns-78fcdf6894-xdmlx                1/1       Running   0          3h
kube-system   etcd-master                             1/1       Running   0          3h
kube-system   kube-apiserver-master                   1/1       Running   0          43m
kube-system   kube-controller-manager-master          1/1       Running   6          3h
kube-system   kube-flannel-ds-mcrqh                   1/1       Running   0          3h
kube-system   kube-proxy-mrxgm                        1/1       Running   0          3h
kube-system   kube-scheduler-master                   1/1       Running   7          3h
```

四、node加入节点（执行脚本初始化）

```
#!/bin/bash
#关闭Selinu
setenforce  0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

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

#添加yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y net-tools wget vim  ntpdate
# 安装docker
yum install -y https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch.rpm  https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/docker-ce-17.03.2.ce-1.el7.centos.x86_64.rpm
#wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
#yum install -y docker-ce
systemctl enable docker && systemctl start docker
systemctl enable docker.service
yum install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet && systemctl start kubelet
#!/bin/bash
images=(kube-proxy-amd64:v1.11.0  pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3)
for imageName in ${images[@]} ; do
  docker pull registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
  docker tag registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName k8s.gcr.io/$imageName
  docker rmi registry.cn-hangzhou.aliyuncs.com/k8sth/$imageName
done
# 个人新加的一句，V 1.11.0 必加
docker tag k8s.gcr.io/pause-amd64:3.1 k8s.gcr.io/pause:3.1
#
根据master节点的提示加入集群
# kubeadm join 192.168.3.206:6443 --token 8wj3pz.6pgl3mux8imyqfzm --discovery-token-ca-cert-hash sha256:abddd5ed3a8496f061c90b5401bf24ed4ba5a1c8706e10a5c89a814933610ece" #把node节点加入到集群中
```

五、在master节点上验证集群是否启动正常

```
# kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master    Ready     master    3h        v1.11.1
node1     Ready     <none>    3h        v1.11.1
node2     Ready     <none>    3h        v1.11.1
node3     Ready     <none>    3h        v1.11.1
```

六、安装dashboard插件

```
1、修改kube-apiserver主配置文件（修改完不需要重启，会自动监测此文件，发生改变会自动重启）

# vim /etc/kubernetes/manifests/kube-apiserver.yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --authorization-mode=Node,RBAC
    - --advertise-address=192.168.3.206
    - --anonymous-auth=false    # 不接受匿名访问，若为true，则表示接受，此处设置为false，便于dashboard访问

2、创建kubernetes-dashboard.yaml文件

# mkdir /data/kubernetes/dashboard
# vim /data/kubernetes/dashboard/kubernetes-dashboard.yaml
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

# Configuration to deploy release version of the Dashboard UI compatible with
# Kubernetes 1.8.
#
# Example usage: kubectl create -f <this_file>

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
        image: k8s.gcr.io/kubernetes-dashboard-amd64:v1.8.3
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
      nodePort: 30000
  selector:
    k8s-app: kubernetes-dashboard

3、创建kubernetes-dashboard-rbac.yaml文件

# vim /data/kubernetes/dashboard/kubernetes-dashboard-rbac.yaml
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

4、创建dashboard、dashboard-rbac resource

# cd /data/kubernetes/dashboard/
# kubectl apply -f ./
clusterrolebinding.rbac.authorization.k8s.io/admin created
serviceaccount/admin created
ingress.extensions/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
serviceaccount/kubernetes-dashboard created
role.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
deployment.apps/kubernetes-dashboard created
service/kubernetes-dashboard created

# kubectl describe --namespace kube-system service kubernetes-dashboard    #查看访问地址
Name:                     kubernetes-dashboard
Namespace:                kube-system
Labels:                   k8s-app=kubernetes-dashboard
Annotations:              kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"k8s-app":"kubernetes-dashboard"},"name":"kubernetes-dashboard","namespace":...
Selector:                 k8s-app=kubernetes-dashboard
Type:                     NodePort
IP:                       10.108.99.148
Port:                     <unset>  443/TCP
TargetPort:               8443/TCP
NodePort:                 <unset>  30000/TCP
Endpoints:                10.244.2.13:8443
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

# 访问方式
https://masterIP:30000


# kubectl -n kube-system  get secret|grep admin
admin-token-ft7tc                                kubernetes.io/service-account-token   3         42s
# kubectl describe secret -n kube-system admin-token-ft7tc
```

七、注意事项
默认情况下，令牌在24小时后过期。如果在当前令牌过期之后节点加入集群，则可以通过在主节点上运行以下命令来创建新令牌
```
1、创建新令牌
# kubeadm token create
42teg2.z6da0h9rd42xq5ii
2、获取--discovery-token-ca-cert-hash，通过主节点运行以下命令
# openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl  rsa -pubin -outform der 2>/dev/null |  openssl dgst -sha256 -hex | sed 's/^.* //'
abddd5ed3a8496f061c90b5401bf24ed4ba5a1c8706e10a5c89a814933610ece
3、加入到集群中
# kubeadm  join 192.168.3.206:6443 --token 42teg2.z6da0h9rd42xq5ii --discovery-token-ca-cert-hash sha256:abddd5ed3a8496f061c90b5401bf24ed4ba5a1c8706e10a5c89a814933610ece
4、在集群中主节点查看结果
# kubectl get nodes
```
