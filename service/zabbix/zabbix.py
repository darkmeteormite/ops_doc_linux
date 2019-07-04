#!/usr/local/python3/bin/python3
# -*- coding:utf-8 -*-
import requests
import json
import sys
 
 
 
# 企业号及应用相关信息
corp_id = 'xxxxxxx'
corp_secret = 'xxxxxxx'
agent_id = xxxxxx
# 存放access_token文件路径
file_path = '/tmp/access_token.log'
 
 
def get_access_token_from_file():
    try:
        f = open(file_path,'r+')
        this_access_token = f.read()
        print('get success %s' % this_access_token)
        f.close()
        return this_access_token
    except Exception as e:
        print(e)
 
# 获取token函数，文本里记录的token失效时调用
def get_access_token():
    get_token_url = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=%s&corpsecret=%s' % (corp_id, corp_secret)
    print(get_token_url)
    r = requests.get(get_token_url)
    request_json = r.json()
    this_access_token = request_json['access_token']
    print(this_access_token)
    r.close()
    # 把获取到的access_token写入文本
    try:
        f = open(file_path,'w+')
        f.write(this_access_token)
        f.close()
    except Exception as e:
        print(e)
 
    # 返回获取到的access_token值
    return this_access_token
 
 
# snedMessage
# 死循环，直到消息成功发送
flag = True
while(flag):
    # 从文本获取access_token
    access_token = get_access_token_from_file()
    try:
        to_user = '@all'
        message = sys.argv[3]
        send_message_url = 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s' % access_token
        print(send_message_url)
        message_params = {
                            "touser":to_user,
                            "msgtype":"text",
                            "agentid":agent_id,
                            "text":{
                                "content" : message
                            },
                            "safe":0
                        }
        r = requests.post(send_message_url, data=json.dumps(message_params))
        print('post success %s ' % r.text)
        # 判断是否发送成功，如不成功则跑出异常，让其执行异常处理里的函数
        request_json = r.json()
        errmsg = request_json['errmsg']
        if errmsg != 'ok': raise
        # 消息成功发送，停止死循环
        flag = False
    except Exception as e:
        print(e)
        access_token = get_access_token()