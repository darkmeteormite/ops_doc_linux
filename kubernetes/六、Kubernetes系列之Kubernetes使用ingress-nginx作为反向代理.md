六、Kubernetes系列之Kubernetes使用ingress-nginx作为反向代理

#一、Ingress简介
>在Kubernetes中，服务和Pod的IP地址仅可以在集群网络内部使用，对于集群外的应用是不可见的。为了使外部的应用能够访问集群内的服务，在Kubernetes 目前 提供了以下几种方案：
NodePort
LoadBalancer
Ingress
###1、Ingress组成
>ingress controller
　　将新加入的Ingress转化成Nginx的配置文件并使之生效
ingress服务
　　将Nginx的配置抽象成一个Ingress对象，每添加一个新的服务只需写一个新的Ingress的yaml文件即可
###2、Ingress工作原理
>1.ingress controller通过和kubernetes api交互，动态的去感知集群中ingress规则变化，
2.然后读取它，按照自定义的规则，规则就是写明了哪个域名对应哪个service，生成一段nginx配置，
3.再写到nginx-ingress-control的pod里，这个Ingress controller的pod里运行着一个Nginx服务，控制器会把生成的nginx配置写入/etc/nginx.conf文件中，
4.然后reload一下使配置生效。以此达到域名分配置和动态更新的问题。
###3、Ingress 可以解决什么问题
>1.动态配置服务
　　如果按照传统方式, 当新增加一个服务时, 我们可能需要在流量入口加一个反向代理指向我们新的k8s服务. 而如果用了Ingress, 只需要配置好这个服务, 当服务启动时, 会自动注册到Ingress的中, 不需要而外的操作.
2.减少不必要的端口暴露
　　配置过k8s的都清楚, 第一步是要关闭防火墙的, 主要原因是k8s的很多服务会以NodePort方式映射出去, 这样就相当于给宿主机打了很多孔, 既不安全也不优雅. 而Ingress可以避免这个问题, 除了Ingress自身服务可能需要映射出去, 其他服务都不要用NodePort方式
#二、部署配置[ingress-nginx](https://kubernetes.github.io/ingress-nginx/)
1、下载配置文件（下载的整合文件）
```
# cd /data/kubernetes/ingress-nginx
# wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
```
2、文件说明
```
可以分成五个单独的文件
1.namespace.yaml 
创建一个独立的命名空间 ingress-nginx

2.configmap.yaml 
ConfigMap是存储通用的配置变量的，类似于配置文件，使用户可以将分布式系统中用于不同模块的环境变量统一到一个对象中管理；而它与配置文件的区别在于它是存在集群的“环境”中的，并且支持K8S集群中所有通用的操作调用方式。
从数据角度来看，ConfigMap的类型只是键值组，用于存储被Pod或者其他资源对象（如RC）访问的信息。这与secret的设计理念有异曲同工之妙，主要区别在于ConfigMap通常不用于存储敏感信息，而只存储简单的文本信息。
ConfigMap可以保存环境变量的属性，也可以保存配置文件。
创建pod时，对configmap进行绑定，pod内的应用可以直接引用ConfigMap的配置。相当于configmap为应用/运行环境封装配置。
pod使用ConfigMap，通常用于：设置环境变量的值、设置命令行参数、创建配置文件。

3.default-backend.yaml 
如果外界访问的域名不存在的话，则默认转发到default-http-backend这个Service，其会直接返回404：

4.rbac.yaml 
负责Ingress的RBAC授权的控制，其创建了Ingress用到的ServiceAccount、ClusterRole、Role、RoleBinding、ClusterRoleBinding

5.with-rbac.yaml 
是Ingress的核心，用于创建ingress-controller。前面提到过，ingress-controller的作用是将新加入的Ingress进行转化为Nginx的配置
```
3、选择要部署的节点
```
#给master002和master003打上标签
kubectl label nodes huoban-k8s-master02 kubernetes.io=nginx-ingress
kubectl label nodes huoban-k8s-master03 kubernetes.io=nginx-ingress
```
4、修改配置文件
```
# vim mandatory.yaml 
---
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
          image: registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:0.25.1
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
 ```
5、部署
```   
# kubectl apply -f mandatory.yaml
namespace/ingress-nginx created
configmap/nginx-configuration created
configmap/tcp-services created
configmap/udp-services created
serviceaccount/nginx-ingress-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-role created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-role-nisa-binding created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-clusterrole-nisa-binding created
deployment.apps/nginx-ingress-controller created
service/ingress-nginx created
```
6、访问测试
```
# kubectl get pods -n ingress-nginx -o wide
NAME                                       READY   STATUS    RESTARTS   AGE   IP              NODE                  NOMINATED NODE   READINESS GATES
nginx-ingress-controller-b44c4d4d7-9rprz   1/1     Running   0          63s   172.16.17.192   huoban-k8s-master03   <none>           <none>
nginx-ingress-controller-b44c4d4d7-zfj5n   1/1     Running   0          63s   172.16.17.193   huoban-k8s-master02   <none>           <none>
[root@HUOBAN-K8S-MASTER01 mq1]# curl 172.16.17.192
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>openresty/1.15.8.1</center>
</body>
</html>
[root@HUOBAN-K8S-MASTER01 mq1]# curl 172.16.17.193
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>openresty/1.15.8.1</center>
</body>
</html>


# kubectl get svc -n ingress-nginx -o wide
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE    SELECTOR
ingress-nginx   ClusterIP   10.100.243.171   <none>        80/TCP,443/TCP   112s   app.kubernetes.io/name=ingress-nginx,app.kubernetes.io/part-of=ingress-nginx
# curl http://10.100.243.171
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>openresty/1.15.8.1</center>
</body>
</html>
```
7、部署一个应用测试一下
```
1、创建一个nginx应用
# vim app-nginx.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: app-nginx
  labels:
    app: app-nginx
spec:
  ports:
    - port: 80
  selector:
    app: app-nginx
    tier: production
---
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: app-nginx
spec:
  maxReplicas: 3
  minReplicas: 1
  scaleTargetRef:
    apiVersion: extensions/v1beta1
    kind: Deployment
    name: app-nginx
  targetCPUUtilizationPercentage: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-nginx
  labels:
    app: app-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-nginx
      tier: production
  template:
    metadata:
      labels:
        app: app-nginx
        tier: production
    spec:
      containers:
      - name: app-nginx
        image: harbor.huoban.com/open/huoban-nginx:v1.1
        imagePullPolicy: IfNotPresent
        resources:
          requests:
            memory: "50Mi"
            cpu: "25m"
        ports:
        - containerPort: 80
          name: nginx
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html

        - name: conf
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: html
        nfs:
          path: /open/web/app
          server: 192.168.101.11

      - name: conf
        nfs:
          path: /open/conf/app/nginx
          server: 192.168.101.11

2、创建TLS证书
kubectl create secret tls bjwf-ingress-secret --cert=server.crt --key=server.key --dry-run -o yaml > bjwf-ingress-secret.yaml

3、创建应用的ingress

# vim app-nginx-ingress.yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: app-ingress
  namespace: default
spec:
  tls:
  - hosts:
    - www.bjwf125.com
    secretName: bjwf-ingress-secret
  rules:
    - host: www.bjwf125.com
      http:
        paths:
        - path: /
          backend:
            serviceName: app-nginx
            servicePort: 80
```
8、访问服务（这块就不截图了。已经能正常跳转至443）
