七、Kubernetes系列之Kubernetes的弹性伸缩（HPA）


###前言
在kubernetes中，我们使用pod对外提供服务。这时候，我们需要以下两种情形需要关注：

 >Pod因为不明原因挂掉，导致服务不可用
>Pod在高负荷的情况下，不能支撑我们的服务

如果我们人工监控pods，人工进行调整副本那么这个工作量无疑是巨大的，但kubernetes已经有了相应的机制来应对了。

###HPA全称Horizontal Pod Autoscaler控制器工作流程（V1版本）

更详细的介绍参考官方文档[Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

- 流程
1. 创建HPA资源对象，关联对应资源例如Deployment，设定目标CPU使用率阈值，最大，最小replica数量。
前提：pod一定要设置资源限制，参数request，HPA才会工作。
2. HPA控制器每隔15秒钟（可以通过设置controller manager的–horizontal-pod-autoscaler-sync-period参数设定，默认15s）通过观测metrics值获取资源使用信息
3. HPA控制器将获取资源使用信息与HPA设定值进行对比，计算出需要调整的副本数量
4. 根据计算结果调整副本数量，使得单个POD的CPU使用率尽量逼近期望值，但不能照顾设定的最大，最小值。
5. 以上2,3,4周期循环

- 周期
1. HPA控制器观测资源使用率并作出决策是有周期的，执行是需要时间的，在执行自动伸缩过程中metrics不是静止不变的，可能降低或者升高，如果执行太频繁可能导致资源的使用快速抖动，因此控制器每次决策后的一段时间内不再进行新的决策。对于扩容这个时间是3分钟，缩容则是5分钟，对应调整参数
```
--horizontal-pod-autoscaler-downscale-delay
--horizontal-pod-autoscaler-upscale-delay
```
2. 自动伸缩不是一次到位的，而是逐渐逼近计算值，每次调整不超过当前副本数量的2倍或者1/2
本记录是对kubernetes HPA功能的验证，参考kubernetes[官方文档](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)，使用的是官方文档提供的镜像php-apache进行测试。
- metrics server
kubernetes集群需要配置好metrics server，配置参考文档[Kubernetes部署metrics-server](https://blog.csdn.net/oyym_mv/article/details/87166639)

###配置HPA实现应用横向扩展
1. 配置启动deployment：php-apache
```
cat hpa-deployment.ymal

apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
  labels:
    app: hpa-test
spec:
  replicas: 1
  selector:
    matchLabels:
      name: php-apache
      app: hpa-test
  template:
    metadata:
      labels:
        name: php-apache
        app: hpa-test
    spec:
      containers:
      - name: php-apache
        image: mirrorgooglecontainers/hpa-example:latest
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        resources:
          requests:
            cpu: 0.005
            memory: 64Mi
          limits:
            cpu: 0.05
            memory: 128Mi
```
2. 配置service: php-apache-svc
```
cat hpa-svc.yaml

apiVersion: v1
kind: Service
metadata:
  name: php-apache-svc
  labels:
    app: hpa-test
spec:
  selector:
    name: php-apache
    app: hpa-test
  ports:
  - name: http
    port: 80
    protocol: TCP
```
3. 配置hpa:php-apache-hpa
```
cat hpa-hpa.yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
  labels:
    app: hpa-test
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
```
4. 启动deployment,service,hpa,并验证
```
# kubectl apply -f ./
deployment.apps/php-apache configured
service/php-apache-svc unchanged
horizontalpodautoscaler.autoscaling/php-apache-hpa unchanged

# kubectl get all
NAME                              READY   STATUS    RESTARTS   AGE
pod/php-apache-6b9f498dc4-vwlfr   1/1     Running   0          3h14m


NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP   7d20h
service/php-apache-svc   ClusterIP   10.104.34.168   <none>        80/TCP    3h14m


NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/php-apache   1/1     1            1           3h14m

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/php-apache-6b9f498dc4   1         1         1       3h14m


NAME                                                 REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/php-apache-hpa   Deployment/php-apache   20%/50%   1         10        1          3h14m
```
###压力测试，观察HPA效果
>1.生成一个压测客户端，持续压力测试
```
kubectl run --generator=run-pod/v1 -i --tty load-generator --image=busybox /bin/sh
# while true; do wget -q -O- http://php-apache-svc.default.svc.cluster.local; done
OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!
```
>2.压测一下，观察结果
```
kubectl get hpa
    NAME             REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
    php-apache-hpa   Deployment/php-apache   800%/50%   1         10        1          27m

kubectl get hpa
    NAME             REFERENCE               TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
    php-apache-hpa   Deployment/php-apache   1000%/50%   1         10        2          27m

kubectl get hpa
    NAME             REFERENCE               TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
    php-apache-hpa   Deployment/php-apache   1000%/50%   1         10        4          27m

kubectl get hpa
    NAME             REFERENCE               TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
    php-apache-hpa   Deployment/php-apache   1000%/50%   1         10        8          27m


kubectl get hpa
    NAME             REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
    php-apache-hpa   Deployment/php-apache   120%/50%   1         10        10         27m

kubectl get deployment php-apache
    NAME         READY   UP-TO-DATE   AVAILABLE   AGE
    php-apache   10/10   10           10          28m
```
#####结论：随着压力测试进行，deployment下pod的CPU使用率增加，超过HPA设定的百分比50%,之后逐次翻倍扩容replicaset。达到上限停止扩容。根据replicaset设置的request QoS逐渐稳定资源的使用率。

>3.停止压测
```
while true; do wget -q -O- http://php-apache-svc.default.svc.cluster.local; done
OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!wget: can't connect to remote host (10.104.63.73): Connection refused
OK!OK!OK!OK!OK!OK!........OK!OK!OK! ^C
/ # exit
/ # Session ended, resume using 'kubectl attach load-generator -c load-generator -i -t' command when the pod is running
```
#####CPU使用率恢复到最初值20%，controller会周期观测，逐次缩容到最小值。
```
kubectl get hpa
	NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
	php-apache-hpa   Deployment/php-apache   20%/50%   1         10        10         36m

#等待几分钟之后(默认5分钟)，原因:
kubectl get hpa
NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   20%/50%   1         10        4          41m

#再次等待几分钟后(默认5分钟)
kubectl get hpa
NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   20%/50%   1         10        2          46m

#再次等待几分钟后（默认5分钟），稳定在最小副本数量
kubectl get hpa
NAME             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   20%/50%   1         10        1          53m
```
###其他
以上测试验证了HPA功能，使用的API版本是autoscaling/v1。通过kubectl api-versions可以查看到存在3个版本。v1版本只支持CPU，v2beta2版本支持多metrics(CPU，memory)以及自定义metrics。基于autoscaling/v2beta2的hpa yaml文件写法
```
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
  labels:
    app: hpa-test
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50

```