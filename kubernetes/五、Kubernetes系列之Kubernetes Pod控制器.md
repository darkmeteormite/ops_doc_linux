五、Kubernetes系列之Kubernetes Pod控制器


#一、常见Pod控制器及含义

###1、 [ReplicaSets](https://www.kubernetes.org.cn/replicasets)
>ReplicaSet是下一代复本控制器。ReplicaSet和 Replication Controller之间的唯一区别是现在的选择器支持。Replication Controller只支持基于等式的selector（env=dev或environment!=qa），但ReplicaSet还支持新的，基于集合的selector（version in (v1.0, v2.0)或env notin (dev, qa)）。
大多数kubectl支持Replication Controller的命令也支持ReplicaSets。rolling-update命令有一个例外 。如果想要滚动更新功能，请考虑使用Deployments。此外， rolling-update命令是必须的，而Deployments是声明式的，因此我们建议通过rollout命令使用Deployments。
虽然ReplicaSets可以独立使用，但是今天它主要被 Deployments 作为协调pod创建，删除和更新的机制。当使用Deployments时，不必担心管理他们创建的ReplicaSets。Deployments拥有并管理其ReplicaSets。
###2、 [Deployment](https://www.kubernetes.org.cn/deployment)
>Deployment为Pod和Replica Set（下一代Replication Controller）提供声明式更新。
你只需要在Deployment中描述你想要的目标状态是什么，Deployment controller就会帮你将Pod和Replica Set的实际状态改变到你的目标状态。你可以定义一个全新的Deployment，也可以创建一个新的替换旧的Deployment。

>一个典型的用例如下：
1.使用Deployment来创建ReplicaSet。ReplicaSet在后台创建pod。检查启动状态，看它是成功还是失败。
2.然后，通过更新Deployment的PodTemplateSpec字段来声明Pod的新状态。这会创建一个新的ReplicaSet，Deployment会按照控制的速率将pod从旧的ReplicaSet移动到新的ReplicaSet中。
3.如果当前状态不稳定，回滚到之前的Deployment revision。每次回滚都会更新Deployment的revision。
4.扩容Deployment以满足更高的负载。
5.暂停Deployment来应用PodTemplateSpec的多个修复，然后恢复上线。
6.根据Deployment 的状态判断上线是否hang住了。
7.清除旧的不必要的ReplicaSet。

###3、 [StatefulSet](https://www.kubernetes.org.cn/statefulset)
>StatefulSet是为了解决有状态服务的问题（对应Deployments和ReplicaSets是为无状态服务而设计），其应用场景包括
1.稳定的持久化存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC来实现
2.稳定的网络标志，即Pod重新调度后其PodName和HostName不变，基于Headless Service（即没有Cluster IP的Service）来实现
3.有序部署，有序扩展，即Pod是有顺序的，在部署或者扩展的时候要依据定义的顺序依次依次进行（即从0到N-1，在下一个Pod运行之前所有之前的Pod必须都是Running和Ready状态），基于init containers来实现
4.有序收缩，有序删除（即从N-1到0）

>从上面的应用场景可以发现，StatefulSet由以下几个部分组成：
1.用于定义网络标志（DNS domain）的Headless Service
2.用于创建PersistentVolumes的volumeClaimTemplates
3.定义具体应用的StatefulSet

>StatefulSet中每个Pod的DNS格式为statefulSetName-{0..N-1}.serviceName.namespace.svc.cluster.local，其中
1.serviceName为Headless Service的名字
2.0..N-1为Pod所在的序号，从0开始到N-1
3.statefulSetName为StatefulSet的名字
4.namespace为服务所在的namespace，Headless Servic和StatefulSet必须在相同的namespace
5.svc.cluster.local为Cluster Domain
###4、[DaemonSet](https://www.kubernetes.org.cn/daemonset)
>DaemonSet保证在每个Node上都运行一个容器副本，常用来部署一些集群的日志、监控或者其他系统管理应用。典型的应用包括：
日志收集，比如fluentd，logstash等
系统监控，比如Prometheus Node Exporter，collectd，New Relic agent，Ganglia gmond等
系统程序，比如kube-proxy, kube-dns, glusterd, ceph等
#二、常用Pod控制器示例
###1、Deployment
```
apiVersion: apps/v1
kind: Deployment
metadata: 
  name: myapp-deploy
spec:
  replicas: 5
  selector: 
    matchLabels:
      app: myapp
      release: canary
  template:
    metadata:
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
```
###2、Deployment + DaemonSet
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      role: logstor
  template:
    metadata:
      labels:
        app: redis
        role: logstor
    spec:
      containers:
      - name: redis
        image: redis:4.0-alpine
        ports:
        - name: redis
          containerPort: 6379
  
---
apiVersion: apps/v1
kind: DaemonSet
metadata: 
  name: filebeat-ds
spec:
  selector: 
    matchLabels:
      app: filebeat
      release: stable
  template:
    metadata:
      labels:
        app: filebeat
        release: stable
    spec:
      containers:
      - name: filebeat
        image: ikubernetes/filebeat:5.6.5-alpine
        env:
        - name: REDIS_HOST
          value: redis.default.svc.cluster.local
        - name: REDIS_LOG_LEVEL
          value: info
```
###3、StatefulSet
```
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: gcr.io/google_containers/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
      annotations:
        volume.alpha.kubernetes.io/storage-class: anything
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```
#三、Pod完整示例字段讲解
```
# yaml格式的pod定义文件完整内容：
apiVersion: v1        #必选，版本号，例如v1
kind: Pod       #必选，Pod
metadata:       #必选，元数据
  name: string        #必选，Pod名称
  namespace: string     #必选，Pod所属的命名空间
  labels:       #自定义标签
    - name: string      #自定义标签名字
  annotations:        #自定义注释列表
    - name: string
spec:         #必选，Pod中容器的详细定义
  containers:       #必选，Pod中容器列表
  - name: string      #必选，容器名称
    image: string     #必选，容器的镜像名称
    imagePullPolicy: [Always | Never | IfNotPresent]  #获取镜像的策略 Alawys表示下载镜像 IfnotPresent表示优先使用本地镜像，否则下载镜像，Nerver表示仅使用本地镜像
    command: [string]     #容器的启动命令列表，如不指定，使用打包时使用的启动命令
    args: [string]      #容器的启动命令参数列表
    workingDir: string      #容器的工作目录
    volumeMounts:     #挂载到容器内部的存储卷配置
    - name: string      #引用pod定义的共享存储卷的名称，需用volumes[]部分定义的的卷名
      mountPath: string     #存储卷在容器内mount的绝对路径，应少于512字符
      readOnly: boolean     #是否为只读模式
    ports:        #需要暴露的端口库号列表
    - name: string      #端口号名称
      containerPort: int    #容器需要监听的端口号
      hostPort: int     #容器所在主机需要监听的端口号，默认与Container相同
      protocol: string      #端口协议，支持TCP和UDP，默认TCP
    env:        #容器运行前需设置的环境变量列表
    - name: string      #环境变量名称
      value: string     #环境变量的值
    resources:        #资源限制和请求的设置
      limits:       #资源限制的设置
        cpu: string     #Cpu的限制，单位为core数，将用于docker run --cpu-shares参数
        memory: string      #内存限制，单位可以为Mib/Gib，将用于docker run --memory参数
      requests:       #资源请求的设置
        cpu: string     #Cpu请求，容器启动的初始可用数量
        memory: string      #内存清楚，容器启动的初始可用数量
    livenessProbe:      #对Pod内个容器健康检查的设置，当探测无响应几次后将自动重启该容器，检查方法有exec、httpGet和tcpSocket，对一个容器只需设置其中一种方法即可
      exec:       #对Pod容器内检查方式设置为exec方式
        command: [string]   #exec方式需要制定的命令或脚本
      httpGet:        #对Pod内个容器健康检查方法设置为HttpGet，需要制定Path、port
        path: string
        port: number
        host: string
        scheme: string
        HttpHeaders:
        - name: string
          value: string
      tcpSocket:      #对Pod内个容器健康检查方式设置为tcpSocket方式
         port: number
       initialDelaySeconds: 0   #容器启动完成后首次探测的时间，单位为秒
       timeoutSeconds: 0    #对容器健康检查探测等待响应的超时时间，单位秒，默认1秒
       periodSeconds: 0     #对容器监控检查的定期探测时间设置，单位秒，默认10秒一次
       successThreshold: 0
       failureThreshold: 0
       securityContext:
         privileged: false
    restartPolicy: [Always | Never | OnFailure] #Pod的重启策略，Always表示一旦不管以何种方式终止运行，kubelet都将重启，OnFailure表示只有Pod以非0退出码退出才重启，Nerver表示不再重启该Pod
    nodeSelector: obeject   #设置NodeSelector表示将该Pod调度到包含这个label的node上，以key：value的格式指定
    imagePullSecrets:     #Pull镜像时使用的secret名称，以key：secretkey格式指定
    - name: string
    hostNetwork: false      #是否使用主机网络模式，默认为false，如果设置为true，表示使用宿主机网络
    volumes:        #在该pod上定义共享存储卷列表
    - name: string      #共享存储卷名称 （volumes类型有很多种）
      emptyDir: {}      #类型为emtyDir的存储卷，与Pod同生命周期的一个临时目录。为空值
      hostPath: string      #类型为hostPath的存储卷，表示挂载Pod所在宿主机的目录
        path: string      #Pod所在宿主机的目录，将被用于同期中mount的目录
      secret:       #类型为secret的存储卷，挂载集群与定义的secre对象到容器内部
        scretname: string  
        items:     
        - key: string
          path: string
      configMap:      #类型为configMap的存储卷，挂载预定义的configMap对象到容器内部
        name: string
        items:
        - key: string
          path: string    

```




