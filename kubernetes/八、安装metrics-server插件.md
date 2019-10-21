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