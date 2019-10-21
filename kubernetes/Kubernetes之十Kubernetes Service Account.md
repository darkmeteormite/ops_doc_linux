Service Account

#一、说明
```
第一步：对客户端访问进行认证操作，确认是否具有访问k8s权限
    token(共享秘钥)
    SSL(双向SSL认证)
    通过任何一个认证即表示认证通过，进入下一步

第二步：授权检查，确认是否对资源具有相关的权限
    ABAC(基于属性的访问控制)
    RBAC(基于角色的访问控制)
    NODE(基于节点的访问控制)
    WEB HOOK(自定义HTTP回调方法的访问控制)

第三步：准入控制(对操作资源相关联的其他资源是否有权限操作)
```

**Kubernetes只对以下的API请求属性进行检查**

```
user - username,uid
group - user group 
"extra"- 额外信息
API - API资源的对象 
Request path - 请求资源的路径(k8s使用resultful风格接口的API) 
 http://Node_IPaddr:6443/apis/apps/v1/namespaces/namespaces_name/resource_name/
HTTP 请求动作 - HTTP verbs get，post，put，和delete用于非资源请求
HTTP 请求动作映射到 API资源操作-  get，list，create，update，patch，watch，proxy，redirect，delete，和deletecollection用于请求resource
Resource -被访问（仅用于resource 请求）的resource 的ID或名字- *对于使用resource 的请求get，update，patch，和delete，必须提供resource 名称。
Subresource - 正在访问的subresource （仅用于请求resource ）
Namespace - 正在访问对象的命名空间（仅针对命名空间的请求资源）
API group - 正在访问的API组（仅用于请求资源）。空字符串指定核心API组。
```
**什么是serviceaccount**
```
Service account是为了方便Pod里面的进程调用Kubernetes API或其他外部服务而设计的。它与User account不同
　　1.User account是为人设计的，而service account则是为Pod中的进程调用Kubernetes API而设计；
　　2.User account是跨namespace的，而service account则是仅局限它所在的namespace；
　　3.每个namespace都会自动创建一个default service account
　　4.Token controller检测service account的创建，并为它们创建secret
　　5.开启ServiceAccount Admission Controller后
       1.每个Pod在创建后都会自动设置spec.serviceAccount为default（除非指定了其他ServiceAccout）
　　　　2.验证Pod引用的service account已经存在，否则拒绝创建
　　　　3.如果Pod没有指定ImagePullSecrets，则把service account的ImagePullSecrets加到Pod中
　　　　4.每个container启动后都会挂载该service account的token和ca.crt到/var/run/secrets/kubernetes.io/serviceaccount/　　
```
**验证**

```
[root@k8s-master01 ~]# kubectl create namespace qiangungun  #创建一个名称空间
namespace "qiangungun" created
[root@k8s-master01 ~]# kubectl get sa -n qiangungun  #名称空间创建完成后会自动创建一个sa
NAME      SECRETS   AGE
default   1         11s
[root@k8s-master01 ~]# kubectl get secret -n qiangungun  #同时也会自动创建一个secret
NAME                  TYPE                                  DATA      AGE
default-token-5jtz2   kubernetes.io/service-account-token   3         19s
```
**在创建的名称空间中新建一个pod**
```
[root@k8s-master01 pod-example]# cat pod_demo.yaml 
kind: Pod
apiVersion: v1
metadata:
  name: task-pv-pod
  namespace: qiangungun
spec:
  containers:
  - name: nginx
    image: ikubernetes/myapp:v1
    ports:
     - containerPort: 80
       name: www
```
**查看pod信息**
```
[root@k8s-master01 pod-example]# kubectl apply -f  pod_demo.yaml 
pod "task-pv-pod" created
[root@k8s-master01 pod-example]# kubectl get pod -n qiangungun 
NAME          READY     STATUS    RESTARTS   AGE
task-pv-pod   1/1       Running   0          13s
[root@k8s-master01 pod-example]# kubectl get  pod task-pv-pod -o yaml   -n qiangungun 
......
volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-5jtz2
......
volumes:  #挂载sa的secret
  - name: default-token-5jtz2
    secret:
      defaultMode: 420
      secretName: default-token-5jtz2 
......

#名称空间新建的pod如果不指定sa，会自动挂载当前名称空间中默认的sa(default)      
```
#二、创建ServiceAccount
```
[root@k8s-master01 ~]#  kubectl create  serviceaccount admin   #创建一个sa 名称为admin
serviceaccount "admin" created
[root@k8s-master01 ~]# kubectl get sa 
NAME      SECRETS   AGE
admin     1         6s
default   1         28d
[root@k8s-master01 ~]# kubectl describe sa admin   #查看名称为admin的sa的信息，系统会自动创建一个token信息
Name:                admin
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   admin-token-rxtrc
Tokens:              admin-token-rxtrc
Events:              <none>
[root@k8s-master01 ~]# kubectl get secret  #会自动创建一个secret(admin-token-rxtrc),用于当前sa连接至当前API server时使用的认证信息
NAME                    TYPE                                  DATA      AGE
admin-token-rxtrc       kubernetes.io/service-account-token   3         1m
default-token-tcwjz     kubernetes.io/service-account-token   3         28d
myapp-ingress-secret    kubernetes.io/tls                     2         6h
mysql-passwd            Opaque                                1         17d
tomcat-ingress-secret   kubernetes.io/tls                     2         7h
```

**创建一个POD应用刚刚创建的SA**
```
[root@k8s-master01 service_account]# cat deploy-demon.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: sa-demo
  labels:
    app: myapp
    release: canary
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v2
    ports:
    - name: httpd
      containerPort: 80
  serviceAccountName: admin  #此处指令为指定sa的名称
[root@k8s-master01 service_account]# kubectl apply -f deploy-demon.yaml 
pod "sa-demo" created
[root@k8s-master01 service_account]# kubectl describe pod sa-demo 
......
Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from admin-token-rxtrc (ro) #pod会自动挂载自己sa的证书
......
  Volumes:
    admin-token-rxtrc:
      Type: Secret (a volume populated by a Secret)
      SecretName: admin-token-rxtrc
......
```

集群交互的时候少不了的是身份认证，使用 kubeconfig（即证书） 和 token 两种认证方式是最简单也最通用的认证方式，下面我使用kubeconfing来进行认证

使用kubeconfig文件来组织关于集群，用户，名称空间和身份验证机制的信息。使用 kubectl命令行工具对kubeconfig文件来查找选择群集并与群集的API服务器进行通信所需的信息。

默认情况下 kubectl使用的配置文件名称是在$HOME/.kube目录下 config文件，可以通过设置环境变量KUBECONFIG或者--kubeconfig指定其他的配置文件

**查看系统的kubeconfig**
```
[root@k8s-master01 ~]# kubectl config view 
apiVersion: v1
clusters:   #集群列表 
- cluster:
    certificate-authority-data: REDACTED  #认证集群的方式
    server: https://172.16.150.212:6443    #访问服务的APIserver的路径
  name: kubernetes #集群的名称
contexts: #上下文列表
- context:
    cluster: kubernetes  #访问kubernetes这个集群
    user: kubernetes-admin  #使用 kubernetes-admin账号
  name: kubernetes-admin@kubernetes #给定一个名称
current-context: kubernetes-admin@kubernetes #当前上下文，表示使用哪个账号访问哪个集群
kind: Config
preferences: {}
users:  #用户列表
- name: kubernetes-admin #用户名称
  user:
    client-certificate-data: REDACTED #客户端证书，用于与apiserver进行认证
    client-key-data: REDACTED #客户端私钥
```

```
[root@k8s-master01 ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP             29d
my-nginx     NodePort    10.104.13.148    <none>        80:32008/TCP        18h
myapp        ClusterIP   10.102.229.150   <none>        80/TCP              19h
tomcat       ClusterIP   10.106.222.72    <none>        8080/TCP,8009/TCP   19h
[root@k8s-master01 ~]# kubectl describe svc kubernetes 
Name:              kubernetes
Namespace:         default
Labels:            component=apiserver
                   provider=kubernetes
Annotations:       <none>
Selector:          <none>
Type:              ClusterIP
IP:                10.96.0.1
Port:              https  443/TCP
TargetPort:        6443/TCP
Endpoints:         172.16.150.212:6443  #可以看到此处svc后端的Endpoint是当前节点的IP地址，通过svc的IP地址进行映射，以确保cluster中的pod可以通过该sa与集群内api进行通讯，仅仅是身份认证
Session Affinity:  ClientIP
Events:            <none>
```

查看kubeconfig命令行配置帮助

```
[root@k8s-master01 ~]# kubectl config --help
Modify kubeconfig files using subcommands like "kubectl config set current-context my-context" 

The loading order follows these rules: 

  1. If the --kubeconfig flag is set, then only that file is loaded.  The flag may only be set once
and no merging takes place.  
  2. If $KUBECONFIG environment variable is set, then it is used a list of paths (normal path
delimitting rules for your system).  These paths are merged.  When a value is modified, it is
modified in the file that defines the stanza.  When a value is created, it is created in the first
file that exists.  If no files in the chain exist, then it creates the last file in the list.  
  3. Otherwise, ${HOME}/.kube/config is used and no merging takes place.

Available Commands:
  current-context 显示 current_context
  delete-cluster  删除 kubeconfig 文件中指定的集群
  delete-context  删除 kubeconfig 文件中指定的 context
  get-clusters    显示 kubeconfig 文件中定义的集群
  get-contexts    描述一个或多个 contexts
  rename-context  Renames a context from the kubeconfig file.
  set             设置 kubeconfig 文件中的一个单个值
  set-cluster     设置 kubeconfig 文件中的一个集群条目
  set-context     设置 kubeconfig 文件中的一个 context 条目
  set-credentials 设置 kubeconfig 文件中的一个用户条目
  unset           取消设置 kubeconfig 文件中的一个单个值
  use-context     设置 kubeconfig 文件中的当前上下文
  view            显示合并的 kubeconfig 配置或一个指定的 kubeconfig 文件

Usage:
  kubectl config SUBCOMMAND [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).

```

三、创建一个cluster用户及context


1、使用当前系统的ca证书认证一个私有证书
```
root@k8s-master01 ~]# cd /etc/kubernetes/pki/
[root@k8s-master01 pki]# (umask 077;openssl genrsa -out qiangungun.key 2048)
Generating RSA private key, 2048 bit long modulus
.........................+++
..........................................................+++
e is 65537 (0x10001)
[root@k8s-master01 pki]# openssl req -new -key qiangungun.key -out qiangungun.csr -subj "/CN=qiangungun"  #qiangungun是后面我们创建的用户名称，需要保持一致
[root@k8s-master01 pki]# openssl x509 -req -in qiangungun.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out qiangungun.crt -days 3650
Signature ok
subject=/CN=qiangungun
Getting CA Private Key
```
2、查看证书内容
```
[root@k8s-master01 pki]# openssl x509 -in qiangungun.crt -text -noout
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number:
            b6:06:cb:30:86:e3:fe:84
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes  #由谁签署的
        Validity  #证书的有效时间
            Not Before: Nov 27 15:09:41 2018 GMT
            Not After : Nov 24 15:09:41 2028 GMT
        Subject: CN=qiangungun  #证书使用的用户
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048
                 ......

```
3、创建一个当前集群用户
```
[root@k8s-master01 pki]#  kubectl config set-credentials qiangungun --client-certificate=./qiangungun.crt --client-key=./qiangungun.key --embed-certs=true
User "qiangungun" set.
[root@k8s-master01 pki]# kubectl config view 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://172.16.150.212:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: qiangungun  #我们新建的用户
  user: 
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```
4、为qiangungun用户创建一个context
```
[root@k8s-master01 pki]# kubectl config set-context  qiangungun@kubernetes --cluster=kubernetes --user=qiangungun 
Context "qiangungun@kubernetes" created.
[root@k8s-master01 pki]# kubectl config view 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://172.16.150.212:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:  #新创建的context
    cluster: kubernetes
    user: qiangungun
  name: qiangungun@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED- name: qiangungun
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```
5、切换到serviceaccount
```
[root@k8s-master01 pki]# kubectl config use-context qiangungun@kubernetes 
Switched to context "qiangungun@kubernetes".
[root@k8s-master01 pki]# kubectl get pod
Error from server (Forbidden): pods is forbidden: User "qiangungun" cannot list pods in the namespace "default"
```
6、自定义一个cluster
```
[root@k8s-master01 pki]# kubectl config set-cluster  mycluster --kubeconfig=/tmp/test.conf --server="https://172.16.150.212:6443" --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true
Cluster "mycluster" set.
[root@k8s-master01 pki]# kubectl config view --kubeconfig=/tmp/test.conf 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://172.16.150.212:6443
  name: mycluster
contexts: []
current-context: ""
kind: Config
preferences: {}
users: []
```