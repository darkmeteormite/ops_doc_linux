k8s集群pod存活性和就绪性探测


一、livenessProbe存活性探测

# kubectl explain pods.spec.containers.livenessProbe
KIND:     Pod
VERSION:  v1

RESOURCE: livenessProbe <Object>

DESCRIPTION:
     Periodic probe of container liveness. Container will be restarted if the
     probe fails. Cannot be updated. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

     Probe describes a health check to be performed against a container to
     determine whether it is alive or ready to receive traffic.

FIELDS:
   exec	<Object>
     One and only one of the following should be specified. Exec specifies the
     action to take.

   failureThreshold	<integer>
     Minimum consecutive failures for the probe to be considered failed after
     having succeeded. Defaults to 3. Minimum value is 1.

   httpGet	<Object>
     HTTPGet specifies the http request to perform.

   initialDelaySeconds	<integer> 初始化探测，指定初始化时间
     Number of seconds after the container has started before liveness probes
     are initiated. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

   periodSeconds	<integer>
     How often (in seconds) to perform the probe. Default to 10 seconds. Minimum
     value is 1.

   successThreshold	<integer>
     Minimum consecutive successes for the probe to be considered successful
     after having failed. Defaults to 1. Must be 1 for liveness. Minimum value
     is 1.

   tcpSocket	<Object>
     TCPSocket specifies an action involving a TCP port. TCP hooks not yet
     supported

   timeoutSeconds	<integer>
     Number of seconds after which the probe times out. Defaults to 1 second.
     Minimum value is 1. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes


1、exec探针

# cat liveness-exec.yaml 
apiVersion: v1
kind: Pod
metadata: 
  name: liveness-exec-pod
  namespace: default
spec:
  containers:
  - name: liveness-exec-container
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh","-c","touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 3600"]
    livenessProbe:
      exec:
        command: ["test","-e","/tmp/healthy"]
      initialDelaySeconds: 2
      periodSeconds: 3

2、http探针

# cat liveness-httpget.yaml 
apiVersion: v1
kind: Pod
metadata: 
  name: nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    livenessProbe:
      httpGet:
        port: http
        path: /index.html
      initialDelaySeconds: 2
      periodSeconds: 3

# periodSeconds：代表每次探测时间间隔
# initialDelaySeconds：代表初始化延迟时间，即在一个容器启动后如果直接开始探测那么很有可能会直接探测失败，需要给一个系统初始化的时间

3、TCPSocketAction

# cat tcp-liveness.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-tcp
spec:
  containers:
  - name: liveness-tcp-demo
    image: nginx
    ports:
    - name: http
      containerPort: 80
    livenessProbe:
      tcpSocket:
        port: 80
      initialDelaySeconds: 30
      timeoutSeconds: 1



initialDelaySeconds <integer> ：存活性探测延迟时长，即容器启动多久后再开始第一次探测操作，显示为delay属性，默认为0秒，即容器启动后立刻开始进行探测。
timeoutSeconds <integer>：存活性探测的超时时长，显示为timeout属性，默认为1s，最小值也为1s。
periodSeconds <integer>：存活性探测的频度，显示为period属性，默认为10s，最小值为1s；过高的频率会对pod对象带来较大的额外开销，而过低的频率又会使得对错误的反应不及时。
successThreshold <integer>：处于失败状态时，探测操作至少连续多少次的成功才被认为是通过检测，显示为#success属性，默认值为1，最小值也为1。
failureThreshold：处于成功状态时，探测操作至少连续多少次的失败才被视为是检测不通过，显示为#failure属性，默认值为3，最小值为1。


二、readinessProbe就绪性探测


# vim rediness-httpget.yaml
apiVersion: v1
kind: Pod
metadata: 
  name: readiness-httpget-pod
  namespace: default
spec:
  containers:
  - name: readiness-httpget-container
    image: nginx
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    readinessProbe:
      httpGet:
        port: http
        path: /index.html
      initialDelaySeconds: 1
      periodSeconds: 3

[root@master1 manifests]# kubectl create -f rediness-httpget.yaml 
pod/readiness-httpget-pod created

# 现在已然处于就绪状态
[root@master1 manifests]# kubectl get pods readiness-httpget-pod
NAME                    READY   STATUS    RESTARTS   AGE
readiness-httpget-pod   1/1     Running   0          35s

# 通过删除和创建index文件来观察pod就绪性状态
[root@master1 manifests]# kubectl exec -it readiness-httpget-pod -- /bin/sh
/ # rm -f /usr/share/nginx/html/index.html  删除index.html文件
/ # echo "hi" >> /usr/share/nginx/html/index.html   创建index.html文件

# 实时观察readiness-httpget-pod就绪性
[root@master1 manifests]# kubectl get pods readiness-httpget-pod -w
NAME                    READY   STATUS    RESTARTS   AGE
readiness-httpget-pod   0/1     Running   0          117s
readiness-httpget-pod   1/1   Running   0     2m27s



三、示例

# cat nginx.yaml

apiVersion: apps/v1 
kind: Deployment 
metadata: 
  name: nginx 
  namespace: open 
  labels: 
    app: nginx 
spec: 
  replicas: 1 
  selector: 
    matchLabels: 
      app: nginx 
  template: 
    metadata: 
      labels: 
        app: nginx 
    spec: 
      imagePullSecrets:
      - name: huoban-harbor
      containers: 
      - name: nginx 
        image: harbor.huoban.com/open/huoban-nginx:v1.1 
        imagePullPolicy: IfNotPresent 
        resources: 
          requests: 
            memory: "25Mi" 
            cpu: "5m" 
          limits: 
            memory: "250Mi" 
            cpu: "50m" 
        ports: 
        - containerPort: 80 
          name: nginx 
		livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          timeoutSeconds: 2
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          timeoutSeconds: 2
