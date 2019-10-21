十二、Kubernetes系列之从私有仓库中拉取镜像

1、登录docker-registry

```
➜  ~ docker login https://harbor.huoban.com
Username: admin
Password:
Login Succeeded
```

2、为k8s集群创建Secret

当Pod从私有仓库拉取镜像时，k8s集群使用类型为docker-registry的Secret来提供身份认证，创建一个名为huoban-harbor的Secret，执行如下命令

```
# kubectl -n open create secret generic huoban-harbor --from-file=.dockerconfigjson=/root/.docker/config.json --type=kubernetes.io/dockerconfigjson -o yaml --dry-run > huoban-harbor.yaml       #测试运行一下。并生产yaml文件

# -n open为指定名称空间，一般搭建k8s集群时，建议使用一个名称空间来隔离资源

# kubectl apply -f huoban-harbor.yaml 
secret/huoban-harbor created

```

检查Secret

```
# kubectl get secret -n open|grep huoban-harbor
huoban-harbor         kubernetes.io/dockerconfigjson        1      55s

# kubectl describe secret -n open huoban-harbor
Name:         huoban-harbor
Namespace:    open
Labels:       <none>
Annotations:  
Type:         kubernetes.io/dockerconfigjson

Data
====
.dockerconfigjson:  158 bytes

```

3、部署Pod测试

```
# vim nginx.yaml
---
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

# imagePullSecrets标签指定拉取镜像时的身份验证信息

# kubectl apply -f nginx.yaml

```


4、查看Pod是否能正常下载镜像





