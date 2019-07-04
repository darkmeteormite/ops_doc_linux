#!/usr/bin/env python
# -- coding: utf-8 -

import smtplib
import string

HOST = 'smtp.ym.163.com'
SUBJECT = 'Alarm server'
TO = '79076431@qq.com'
FROM = "yunwei@ph51.com"
test = "Dev doc server is stop"    #邮件内容
BODY = string.join((
    "From: %s" %FROM,
	"To: %s" %TO,
	"Subject: %s" %SUBJECT,
	"",
    test
    ),"\r\n")

server = smtplib.SMTP()
server.connect(HOST,"25")
server.starttls()
server.login("yunwei@ph51.com","123321")#登录邮件服务器
server.sendmail(FROM,[TO],BODY)
server.quit()