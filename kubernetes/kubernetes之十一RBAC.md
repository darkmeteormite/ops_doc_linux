kubernetes之十一RBAC


一、RBAC介绍
```
在Kubernetes中，授权有ABAC（基于属性的访问控制）、RBAC（基于角色的访问控制）、Webhook、Node、AlwaysDeny（一直拒绝）和AlwaysAllow（一直允许）这6种模式。从1.6版本起，Kubernetes 默认启用RBAC访问控制策略。从1.8开始，RBAC已作为稳定的功能。通过设置–authorization-mode=RBAC，启用RABC。在RABC API中，通过如下的步骤进行授权：1）定义角色：在定义角色时会指定此角色对于资源的访问控制的规则；2）绑定角色：将主体与角色进行绑定，对用户进行访问授权。
```


1、 角色和集群角色
在RBAC API中，角色包含代表权限集合的规则。在这里，权限只有被授予，而没有被拒绝的设置。在Kubernetes中有两类角色，即普通角色和集群角色。可以通过Role定义在一个命名空间中的角色，或者可以使用ClusterRole定义集群范围的角色。一个角色只能被用来授予访问单一命令空间中的资源。
集群角色(ClusterRole)能够被授予如下资源的权限：
    集群范围的资源（类似于Node）
    非资源端点（类似于”/healthz”）
    集群中所有命名空间的资源（类似Pod）

2、角色绑定和集群角色绑定
角色绑定用于将角色与一个或一组用户进行绑定，从而实现将对用户进行授权的目的。主体分为用户、组和服务帐户。角色绑定也分为角色普通角色绑定和集群角色绑定。角色绑定只能引用同一个命名空间下的角色。
角色绑定也可以通过引用集群角色授予访问权限，当主体对资源的访问仅限与本命名空间，这就允许管理员定义整个集群的公共角色集合，然后在多个命名空间中进行复用。
集群角色可以被用来在集群层面和整个命名空间进行授权。

3、资源
在Kubernets中，主要的资源包括：Pods、Nodes、Services、Deployment、Replicasets、Statefulsets、Namespace、Persistents、Secrets和ConfigMaps等。另外，有些资源下面存在子资源，例如：Pod下就存在log子资源

4、主体
RBAC授权中的主体可以是组，用户或者服务帐户。用户通过字符串表示，比如“alice”、 “bob@example.com”等，具体的形式取决于管理员在认证模块中所配置的用户名。system:被保留作为用来Kubernetes系统使用，因此不能作为用户的前缀。组也有认证模块提供，格式与用户类似。

二、简单示例
**1、使用RoleBanding将用户绑定到Role上**

1)、查看命令帮助及格式
```
[root@k8s-master01 ~]# kubectl create role -h  #查看创建role的命令帮助，以及一些简单的示例
[root@k8s-master01 RBAC]# kubectl create role pods-reader --verb=get,list,watch --resource=pods --dry-run -o yaml  #通过 -o参数导出yaml格式，可以大致看到Role是如何定义的
[root@k8s-master01 RBAC]# cat role-demo.yaml  #最后完成的yaml文件如下 
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pods-reader
  namespace: default  #名称空间名称
rules:
- apiGroups:
  - ""
  resources:  #包含哪些资源
  - pods
  verbs:       #对以上资源允许进行哪些操作
  - get
  - list
  - watch
```
2)、创建Role
```
[root@k8s-master01 RBAC]# kubectl apply -f role-demo.yaml 
role.rbac.authorization.k8s.io "pods-reader" created
[root@k8s-master01 RBAC]# kubectl get role   #查看role的信息
NAME          AGE
pods-reader   8s
[root@k8s-master01 RBAC]# kubectl describe role pods-reader  #查看pods-reader 的详细信息
Name:         pods-reader
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"rbac.authorization.k8s.io/v1","kind":"Role","metadata":{"annotations":{},"name":"pods-reader","namespace":"default"},"rules":[{"apiGroup...
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------     -----------------         --------------          -----
  pods          []                            []                         [get list watch]
#
Resources：资源类别，表示对该资源类别下的所有资源进行操作
Non-Resource URLs：非资源URL，对某些资源进行某种特殊操作的存在
Resource Names：对资源类别下某个或多个资源进行操作
Verbs：操作的类型　　
```
3)、创建一个RoleBinding，将用户qiangungun(该用户在上一章节serviceaccount中已经被创建)绑定到pods-reader 这个role上去
```
[root@k8s-master01 ~]# kubectl create rolebinding -h  #查看命令帮助
 kubectl create rolebinding  qiangungun-read-pods --role=pods-reader --user=qiangungun  --dry-run -o yaml  #创建名称为qiangungun-read-pods的rolebinding，绑定到名称为pods-reader的role上
[root@k8s-master01 RBAC]# cat rolebinding-demo.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: qiangungun-read-pods
roleRef:   #role引用，表示引用哪个role
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pods-reader
subjects:  #动作的执行主题
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: qiangungun
[root@k8s-master01 RBAC]# kubectl describe rolebinding qiangungun-read-pods 
Name:         qiangungun-read-pods
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"rbac.authorization.k8s.io/v1","kind":"RoleBinding","metadata":{"annotations":{},"name":"qiangungun-read-pods","namespace":"default"},"ro...
Role:
  Kind:  Role
  Name:  pods-reader
Subjects:
  Kind  Name        Namespace
  ----  ----        ---------
  User  qiangungun 　　

```
4)、验证操作
```
[root@k8s-master01 RBAC]# kubectl config use-context qiangungun@kubernetes #前后当前上下文到qiangungun用户
Switched to context "qiangungun@kubernetes".
[root@k8s-master01 RBAC]# kubectl get pods    #获取当前名称空间的pod信息，可以看到能够正常显示
NAME                             READY     STATUS    RESTARTS   AGE
myapp-deploy-5cfd895984-262kz    1/1       Running   0          3d
myapp-deploy-5cfd895984-7whdn    1/1       Running   0          3d
myapp-deploy-5cfd895984-lg8sh    1/1       Running   0          3d
myapp-deploy-5cfd895984-m7h5j    1/1       Running   0          3d
myapp-deploy-5cfd895984-zd9cm    1/1       Running   0          3d
[root@k8s-master01 RBAC]# kubectl get pods -n kube-system    #查看其它空间pod的信息，可以看到提示没有权限，即验证RoleBanding的权限只对当前的名称空间生效
Error from server (Forbidden): pods is forbidden: User "qiangungun" cannot list pods in the namespace "kube-system"
```

**2、使用ClusterRoleBanding将用户绑定到ClusterRole上**
#创建一个ClusterRole
```
[root@k8s-master01 RBAC]# kubectl config use-context kubernetes-admin@kubernetes #切换上下文
Switched to context "kubernetes-admin@kubernetes".
[root@k8s-master01 RBAC]# kubectl create clusterrole -h
[root@k8s-master01 RBAC]# kubectl create clusterrole cluster-reader --verb=get,list,watch --resource=pods -o yaml --dry-run
[root@k8s-master01 RBAC]# cat clusterrole-cluster.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-reader #ClusterRole属于集群级别，所有不可以定义namespace
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
[root@k8s-master01 RBAC]# kubectl apply -f clusterrole-cluster.yaml 
[root@k8s-master01 RBAC]# useradd admin
[root@k8s-master01 RBAC]# cp -rp ~/.kube/ /home/admin
[root@k8s-master01 RBAC]# chown -R admin:admin /home/admin
[root@k8s-master01 RBAC]# su - admin
[admin@k8s-master01 ~]$ kubectl config use-context qiangungun@kubernetes
[admin@k8s-master01 ~]$ kubectl config view　　
```
创建一个ClusterRoleBinding,将用户qiangungun绑定到cluster-reader这个ClusterRole上面去
```
[root@k8s-master01 RBAC]# kubectl delete rolebinding qiangungun-read-pods   #root用户
[admin@k8s-master01 ~]$ kubectl get pods   #admin用户下验证
Error from server (Forbidden): pods is forbidden: User "qiangungun" cannot list pods in the namespace "default"
[root@k8s-master01 RBAC]# kubectl create clusterrolebinding -h
[root@k8s-master01 RBAC]# kubectl create clusterrolebinding qiangungun-read-all-pods --clusterrole=cluster-reader --user=qiangungun --dry-run -o yaml #创建名称为qiangungun-read-all-pods的才clusterrolebinding，将名称为cluster-reader的clusterrole绑定到用户名称为qiangungun上
[root@k8s-master01 RBAC]# cat clusterrolebinding-demo.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: qiangungun-read-all-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: qiangungun
[root@k8s-master01 RBAC]# kubectl apply -f clusterrolebinding-demo.yaml 
[root@k8s-master01 RBAC]# kubectl describe clusterrolebinding qiangungun-read-all-pods 　　
```
验证
```
#切换到admin用户终端下
[admin@k8s-master01 ~]$ kubectl get pods  #可以查看当前名称空间pod信息
NAME                             READY     STATUS    RESTARTS   AGE
myapp-deploy-5cfd895984-262kz    1/1       Running   0          3d
myapp-deploy-5cfd895984-7whdn    1/1       Running   0          3d
myapp-deploy-5cfd895984-lg8sh    1/1       Running   0          3d
myapp-deploy-5cfd895984-m7h5j    1/1       Running   0          3d
myapp-deploy-5cfd895984-zd9cm    1/1       Running   0          3d
[admin@k8s-master01 ~]$ kubectl get pods -n ingress-nginx  #可以查看其他空间的pod信息
NAME                                        READY     STATUS    RESTARTS   AGE
default-http-backend-66c4fbf5b4-m8d6j       1/1       Running   0          24d
nginx-ingress-controller-64bcff8657-6j4tq   1/1       Running   0          24d
[admin@k8s-master01 ~]$ kubectl delete pod myapp-deploy-5cfd895984-262kz  #无法删除pod
Error from server (Forbidden): pods "myapp-deploy-5cfd895984-262kz" is forbidden: User "qiangungun" cannot delete pods in the namespace "default"
```
**3、使用RoleBinding绑定ClusterRole**
创建一个RoleBinding(ClusterRole使用以及存在的)，并将用户绑定到ClusterRole上

```
[root@k8s-master01 RBAC]# kubectl delete clusterrolebinding qiangungun-read-all-pods #为了避免冲突，先将之前的clusterrolebinding删除
clusterrolebinding.rbac.authorization.k8s.io "qiangungun-read-all-pods" deleted
[root@k8s-master01 RBAC]#kubectl create rolebinding qiangungun-read-pods --clusterrole=cluster-reader --user=qiangungun --dry-run -o yam
[root@k8s-master01 RBAC]# cat rolebinding-cluster-demo.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: qiangungun-read-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: qiangungun
[root@k8s-master01 RBAC]# kubectl apply -f rolebinding-cluster-demo.yaml 
rolebinding.rbac.authorization.k8s.io "qiangungun-read-pods" created
[root@k8s-master01 RBAC]# kubectl describe rolebinding qiangungun-read-pods 　　
```
验证
```
#admin用户终端下
[admin@k8s-master01 ~]$ kubectl get pods  #可以获取当前名称空间的pod信息
NAME                             READY     STATUS    RESTARTS   AGE
myapp-deploy-5cfd895984-262kz    1/1       Running   0          3d
myapp-deploy-5cfd895984-7whdn    1/1       Running   0          3d
myapp-deploy-5cfd895984-lg8sh    1/1       Running   0          3d
myapp-deploy-5cfd895984-m7h5j    1/1       Running   0          3d
myapp-deploy-5cfd895984-zd9cm    1/1       Running   0          3d
[admin@k8s-master01 ~]$ kubectl get pods -n ingress-nginx   #不可用获取其他名称空间的信息
Error from server (Forbidden): pods is forbidden: User "qiangungun" cannot list pods in the namespace "ingres
```
4、使用RoleBinding绑定集群自带的ClusterRole　　
```
[root@k8s-master01 RBAC]# kubectl get clusterrole  #查看当前集群存在的clusterrole
[root@k8s-master01 RBAC]# kubectl create rolebinding default-ns-admin --clusterrole=admin --user=qiangungun  --dry-run -o yaml #将qiangungun用户绑定到名称为admin的clusterrole上，可以使用get查看admin的配置
[root@k8s-master01 RBAC]# cat rolebinding-cluster-admin-demo.yaml
piVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-ns-admin
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: qiangungun
[root@k8s-master01 RBAC]# kubectl apply -f rolebinding-cluster-admin-demo.yaml
[root@k8s-master01 RBAC]# kubectl describe rolebinding default-ns-admin 　　
```
验证
```
#admin用户终端下
[admin@k8s-master01 ~]$ kubectl get pods  #可以获取当前名称空间的pod信息
NAME                             READY     STATUS    RESTARTS   AGE
myapp-deploy-5cfd895984-262kz    1/1       Running   0          3d
myapp-deploy-5cfd895984-7whdn    1/1       Running   0          3d
myapp-deploy-5cfd895984-lg8sh    1/1       Running   0          3d
myapp-deploy-5cfd895984-m7h5j    1/1       Running   0          3d
myapp-deploy-5cfd895984-zd9cm    1/1       Running   0          3d
......
[admin@k8s-master01 ~]$ kubectl delete pod myapp-deploy-5cfd895984-262kz   #可以删除当前名称空间的pod
pod "myapp-deploy-5cfd895984-262kz" deleted
[admin@k8s-master01 ~]$ kubectl get deploy  #可以查看名称空间中的其他资源，如deployment
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy    5               5              5                   5                 3d
[admin@k8s-master01 ~]$ kubectl delete deployment nginx-deploy  #可以删除当前名称空间的其他资源，如deployment
deployment.extensions "nginx-deploy" deleted
[admin@k8s-master01 ~]$ kubectl get pods -n kube-system  #对其名称空间没有任何权限
Error from server (Forbidden): pods is forbidden: User "qiangungun" cannot list pods in the namespace "kube-system"
```
#三、Role、CluseterRole、RoleBinding、ClusterRoleBinding在系统的相关联系

```
[root@k8s-master01 RBAC]# kubectl get clusterrolebinding #查看集群中的clusterrolebingding
NAME                                                   AGE
cluster-admin                                          31d
......
[root@k8s-master01 RBAC]# kubectl get clusterrolebinding cluster-admin -o yaml  #获取名称为cluster-admin的clusterrolebingding配置信息
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: 2018-10-30T02:32:22Z
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: cluster-admin
  resourceVersion: "103"
  selfLink: /apis/rbac.authorization.k8s.io/v1/clusterrolebindings/cluster-admin
  uid: 07b1d436-dbec-11e8-8969-5254001b07db
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group   #类型是一个组
  name: system:masters   #这个组中包含了kubernetes-admin这个用户，而这个用户是默认的当前使用用户
[root@k8s-master01 RBAC]# kubectl config view 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://172.16.150.212:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin  #默认使用的当前用户
  name: kubernetes-admin@kubernetes
- context:
    cluster: kubernetes
    user: qiangungun
  name: qiangungun@kubernetes
current-context: kubernetes-admin@kubernetes  #当前的使用sa
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: qiangungun
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
[root@k8s-master01 RBAC]# cd /etc/kubernetes/pki/
[root@k8s-master01 pki]# openssl x509  -in ./apiserver-kubelet-client.crt -text -noout #查看证书签发的内容
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 3187679453637891293 (0x2c3ce992f3e5d4dd)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes
        Validity
            Not Before: Oct 30 02:32:03 2018 GMT
            Not After : Oct 30 02:32:03 2019 GMT
        Subject: O=system:masters, CN=kube-apiserver-kubelet-client  #kubernetes-admin用户之所以属于system:master这个组，是因为在它的的证书中定义的，O表示组,如果以后我们想一次授权多个用户，可以将这些用户添加至一个组内，然后给这个组授权即可
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
              .....
```
#如果RoleBinding或者ClusterRoleBinding的对象是serviceaccount，，那么任意一个pod(spec.serviceAcountName中定义)如果启动时以这个serviceaccount name作为它是以的serviceaccount，那么pod中的应用程序也同时拥有了这个serviceaccount的权限，也就是拥有该serviceaccount绑定的Role或者ClusterRole的权限。系统上一下特殊的pod可能需要做这样的设置，下面我就以集群创建时使用的flannel网络插件为示例讲解

查看flannel的配置
```
[root@k8s-master01 kubernetes]# cat kube-flannel.yml   #flannel的配置文件
---
kind: ClusterRole    #定义一个ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
rules:
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes/status
    verbs:
      - patch
---
kind: ClusterRoleBinding  #定义了一个ClusterRoleBinding 
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1 
kind: ServiceAccount   #定义了一个ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
......(以下省略)　　
```
查看flannel创建的pod信息
```
[root@k8s-master01 kubernetes]# kubectl get pod -n kube-system 
NAME                                   READY     STATUS    RESTARTS   AGE
etcd-k8s-master01                      1/1       Running   0          32d
kube-apiserver-k8s-master01            1/1       Running   0          32d
kube-controller-manager-k8s-master01   1/1       Running   0          7d
kube-dns-86f4d74b45-72kdh              3/3       Running   0          32d
kube-flannel-ds-amd64-847wt            1/1       Running   0          32d
kube-flannel-ds-amd64-9v9t6            1/1       Running   0          32d
kube-flannel-ds-amd64-k4blq            1/1       Running   0          32d
kube-proxy-8l9tf                       1/1       Running   0          32d
kube-proxy-m6pqm                       1/1       Running   0          32d
kube-proxy-scj8n                       1/1       Running   0          32d
kube-scheduler-k8s-master01            1/1       Running   0          32d
[root@k8s-master01 kubernetes]# kubectl get pod kube-flannel-ds-amd64-847wt -n kube-system  -o yaml
......(省略)
  serviceAccount: flannel
  serviceAccountName: flannel  #表示当前的pod在启动容器时，运行的进程与APIserver进行通讯的时候，会以serviceAccountName的账号与APIserver进行连接，从而获得该serviceaccount的权限
.....(省略)　
```
下面是一张我个人总结的关于user绑定到不同的Role和Binding时所拥有的权限边界

User

Binding 类型

Role 类型

权限

RoleBinding

Role

namespace

ClusterRoleBinding

ClusterRole

Cluster

RoleBinding

ClusterRole

namespace

#其实关于RBAC还有很多需要讲解的地方，当时能力有限，有些内容虽然自己理解，但是不知道如何以文件的形式表达出来，写的不好，请多多谅解

参考文档：https://www.kubernetes.org.cn/4062.html　　
