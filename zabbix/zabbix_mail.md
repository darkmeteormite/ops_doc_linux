zabbix脚本发邮件
```
#!/usr/bin/env python
#_*_ coding:utf-8 _*_

import smtplib, sys
from email.mime.text import MIMEText
from email.utils import formataddr

def send_mail(to_email, subject, message):

    #邮箱地址和邮箱密码
    my_sender = 'alert@huoban.com'
    my_pass = 'Zabbix2018'
    my_user = to_email

    #发送邮件的信息主体，发件人，收件人，内容
    msg = MIMEText(message, 'plain', 'utf-8')
    msg['From'] = formataddr(["Zabbix", my_sender])
    msg['To'] = formataddr(["Ops", my_user])
    msg['Subject'] = subject

    #发送邮件
    server = smtplib.SMTP_SSL("smtp.exmail.qq.com", 465)
    server.login(my_sender, my_pass)
    server.sendmail(my_sender, [my_user, ], msg.as_string())
    server.quit()

if __name__ == '__main__':
    send_mail(sys.argv[1],sys.argv[2],sys.argv[3])
```
