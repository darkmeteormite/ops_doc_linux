因为要经常发布代码到线上环境, 之前用rsync+inotify写的shell脚本, 但是随着机器的增加同步会变得非常慢.

所以决定用saltstack+rsync进行同步(这个是异步的,同步速度非常快)

安装步骤如下:

环境(CentOS 6.7)

服务端安装(要先安装epel源)
```
yum install epel-release -y
yum install salt -y
service salt-master start
```
客户端安装
```
yum install epel-release -y
yum install salt-minion -y
sed -i 's@^#master:@master: 192.168.10.1' /etc/salt/minion #注意这里是master端IP
sed -i 's@^#id:@id: node' /etc/salt/minion  # 注意这里的id是

service salt-minion start
```
---
依赖包
```
yum install -y gcc make python-devel libffi-devel
pip install pyOpenSSL==0.15.1
```

借助Salt工具来生成证书
```
salt '*' tls.create_self_signed_cert

local:
    Created Private Key: '/etc/pki/tls/certs/localhost.key.' Created Certificate: '/etc/pki/tls/certs/localhost.crt.'
```

配置执行salt的用户及权限
```
useradd -M -s /sbin/nologinx eris
echo '123456' | passwd eris --stdin
```

在salt-master配置文件添加如下配置
```
external_auth:
  pam
    eris:
      - '*':
        - test.*
        - cmd.*
        
rest_cherrypy:
  port: 8888
  ssl_crt: /etc/pki/tls/certs/localhost.crt
  ssl_key: /etc/pki/tls/certs/localhost.key
  
service salt-api start
```

使用python来进行同步
```
#!/usr/bin/env python
#

import urllib, urllib2
import time
import sys

try:
    import json
except ImportError:
    import simplejson as json
    
class SaltAPI(object):
    __token_id = ''
    
    def __init__(self, url, username, password):
        self.__url = url.rstrip('/')
        self.__user = username
        self.__password = password
        
    def Token_Id(self):
        params = {'eauth': 'pam', 'username': self.__user, 'password': self.__password}
        encode = urllib.encode(params)
        obj = urllib.unquote(encode)
        request = urllib2.Request(self.__url + '/login',
                                  urllib.unquote(encode),
                                  {'X-Auth-Token': self.__token_id}
                                  )
        response = urllib2.urlopen(request)
        content = json.loads(response.read())
        try:
            self.__token_id = content['return'][0]['token']
        except KeyError:
            raise KeyError
        return self.__token_id
        
    def Rsync(self, name):
        params = {'client': 'local',
                  'tgt': 'nginx',
                  'fun': 'cmd.run',
                  'arg': '/usr/bin/rsync -zvrtopg --progress --password-file=/etc/rsync.passwd rsyncuser@192.168.56.101::{0}.betsungame.com /data/www/{0}.betsungame.com'.format(name),
                  'expr_form': 'nodegroup'}
        obj = json.dumps(aprams)
        headers = {'Content-Type': 'application/json',
                   'Accept': 'application/json',
                   'X-Auth-Token': self.Token_ID()}
        request = urllib2.Request(self.__url, obj, headers)
        response = urllib2.urlopen(request)
        content = json.loads(response.read())
        return content
        
def main():
    Sapi = SaltAPI(url = 'https://127.0.0.1:8888', 'username' = 'sa', 'password' = '123456')
    if len(sys.argv) == 2:
        Sapi.Rsync(sys.argv[1])
    else:
        print "parameters error"
        
if __name__ == '__main__':
    main()
```

使用方法比如说要同步front代码
python salt-api.py front
