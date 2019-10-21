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
一、配置hosts解析
```
# vim /etc/hosts
192.168.3.42 huoban-k8s-master01  master01
192.168.3.43 huoban-k8s-master02  master02
192.168.3.44 huoban-k8s-master03  master03
```
二、安装docker
```
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

yum install -y docker-ce-18.06.1.ce-3

systemctl start docker && systemctl enable docker

# 配置docker镜像加速（可选）
cat > /etc/docker/daemon.json <<EOF
{
"registry-mirrors":["https://k9e55i4n.mirror.aliyuncs.com"]
}
EOF
```
三、安装 kubeadm, kubelet 和 kubectl
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

yum install -y kubelet-1.14.5 kubeadm-1.14.5 kubectl-1.14.5

#查看安装情况

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

六、配置kubelet

```
### 以下操作需要在所有节点上执行
# 重新载入kubelet系统配置
systemctl daemon-reload
# 设置开机启动，暂时不启动kubelet
systemctl enable kubelet

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


#验证证书有效时间
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


#安装网络插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#拷贝master证书到其他节点
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

八、安装metrics-server插件。

```
1、先把文件都下载下来。  
mkdir ./metrics-server  
cd metrics-server/  
for file in aggregated-metrics-reader.yaml auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml; do  wget https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/$file;done  
  
2、这里需要改2个地方，一个是镜像的问题，一个是服务启动的问题。  
  
# 在所有Node节点上执行。先把镜像国通阿里云的镜像源下载下来。再改个名字。  
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server-amd64:v0.3.3  
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server-amd64:v0.3.3 k8s.gcr.io/metrics-server-amd64:v0.3.3  
  
# 修改metrics-server-deployment.yaml，增加一个imagePullPolicy，增加command内容，否则会报错no metrics known for node。相关问题原因自行百度。  
# vim metrics-server-deployment.yaml  
 30       containers:  
 31       - name: metrics-server  
 32         image: k8s.gcr.io/metrics-server-amd64:v0.3.3  
 33         imagePullPolicy: IfNotPresent  
 34         command:  
 35           - /metrics-server  
 36           - --kubelet-preferred-address-types=InternalIP 
 37           - --kubelet-insecure-tls  
 38         volumeMounts:  
 39         - name: tmp-dir  
 40           mountPath: /tmp  
   
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
metrics-server-55898485b6-pdhnz               1/1     Running   0          93m    10.244.4.2      huoban-k8s-node01  
  
# 一定要等几分钟，否则会报错的！  
kubectl top node  
NAME                  CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%     
huoban-k8s-master01   72m          3%     612Mi           16%         
huoban-k8s-master02   93m          4%     713Mi           19%         
huoban-k8s-master03   108m         5%     674Mi           18%         
huoban-k8s-node01     26m          1%     334Mi           9%          
huoban-k8s-node02     26m          1%     339Mi           9%          
huoban-k8s-node03     25m          1%     316Mi           8%    
```


九、安装ingress-nginx

```
#给master002和master003打上标签
kubectl label nodes huoban-k8s-master02 kubernetes.io=nginx-ingress
kubectl label nodes huoban-k8s-master03 kubernetes.io=nginx-ingress

# vim mandatory.yaml 

apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginxs
data:
  proxy-body-size: "200m"

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

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
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
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

apiVersion: apps/v1
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
      nodeSelector:
        kubernetes.io: nginx-ingress
      tolerations:
      - effect: NoSchedule
        operator: Exists
      hostNetwork: true
      serviceAccountName: nginx-ingress-serviceaccount
      containers:
        - name: nginx-ingress-controller
          image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:0.25.0
          imagePullPolicy: IfNotPresent
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            allowPrivilegeEscalation: true
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
              containerPort: 80
            - name: https
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
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
      volumes:
      - name: ssl
        nfs:
          path: /conf/global_sign_ssl
          server: 0a52248244-vcq8.cn-hangzhou.nas.aliyuncs.com
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
    
# kubectl apply -f ./


#创建TLS证书
kubectl create secret tls huobanim-ingress-secret --cert=server.crt --key=server.key --dry-run -o yaml > huobanim-ingress-secret.yaml
```