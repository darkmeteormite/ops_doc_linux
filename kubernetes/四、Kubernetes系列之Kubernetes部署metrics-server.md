四、Kubernetes系列之Kubernetes部署metrics-server

#一、metrics-server简介
自kubernetes 1.8开始，资源使用指标（如容器 CPU 和内存使用率）通过 Metrics API 在 Kubernetes 中获取，metrics-server 替代了heapster。Metrics Server 实现了Resource Metrics API，Metrics Server 是集群范围资源使用数据的聚合器。 
Metrics Server 从每个节点上的 Kubelet 公开的 Summary API 中采集指标信息。

Kubernetes中有些组件依赖资源指标API(metric API)的功能 ，如kubectl top 、hpa。如果没有资源指标API接口，这些组件无法运行。在之前使用的是Heapster，Heapster废弃后改用metrics-server。

- 通过Metrics API可以获取指定node或者pod的当前资源使用情况（而无法获取历史数据）
- Metrics API的api路径：/apis/metrics.k8s.io/
- Metrics API的使用需要在K8S集群中成功部署metrics server

kubernetes metrics server 参考文档 https://github.com/kubernetes-incubator/metrics-server

#二、安装metrics-server

```
1、下载所需文件
# mkdir ./metrics-server  
# cd metrics-server/  
# for file in aggregated-metrics-reader.yaml auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml; do  wget https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/$file;done 

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
 36           - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
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

3、查看pod状态  
metrics-server-55898485b6-pdhnz               1/1     Running   0          93m    10.244.4.2      huoban-k8s-node01  
  
4、查看node资源使用情况（ 一定要等几分钟，采集数据需要时间） 
kubectl top node  
NAME                  CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%     
huoban-k8s-master01   72m          3%     612Mi           16%         
huoban-k8s-master02   93m          4%     713Mi           19%         
huoban-k8s-master03   108m         5%     674Mi           18%         
huoban-k8s-node01     26m          1%     334Mi           9%          
huoban-k8s-node02     26m          1%     339Mi           9%        

5、查看pod资源使用情况
# kubectl top pods -n kube-system
NAME                                          CPU(cores)   MEMORY(bytes)
coredns-6967fb4995-4qlfb                      1m           13Mi
coredns-6967fb4995-frv2p                      1m           12Mi
etcd-huoban-k8s-master01                      22m          358Mi
etcd-huoban-k8s-master02                      25m          364Mi
etcd-huoban-k8s-master03                      23m          381Mi
kube-apiserver-huoban-k8s-master01            15m          267Mi
kube-apiserver-huoban-k8s-master02            13m          255Mi
kube-apiserver-huoban-k8s-master03            17m          249Mi
kube-controller-manager-huoban-k8s-master01   7m           69Mi
kube-controller-manager-huoban-k8s-master02   0m           14Mi
kube-controller-manager-huoban-k8s-master03   0m           14Mi
kube-flannel-ds-amd64-6bp76                   1m           21Mi
kube-flannel-ds-amd64-nrvvz                   1m           15Mi
kube-flannel-ds-amd64-shv4n                   1m           16Mi
kube-flannel-ds-amd64-t77n4                   1m           15Mi
kube-proxy-8d522                              1m           19Mi
kube-proxy-9ng4j                              1m           18Mi
kube-proxy-htw7p                              1m           20Mi
kube-proxy-n9r48                              1m           17Mi
kube-proxy-nsqgh                              1m           17Mi
kube-scheduler-huoban-k8s-master01            1m           27Mi
kube-scheduler-huoban-k8s-master02            0m           16Mi
kube-scheduler-huoban-k8s-master03            0m           13Mi
kubernetes-dashboard-86844cc55f-sz4gn         0m           13Mi
metrics-server-d9d75756b-l75wj                1m           17Mi   
```
