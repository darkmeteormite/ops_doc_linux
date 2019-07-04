# -*- coding: utf-8 -*-

import argparse
import time
import re
import json
import math
from jinja2 import Template
import smtplib
from email.mime.text import MIMEText
from email.header import Header

""" 清洗数据
保存清洗后的数据到指定的文件
"""
def clean(file, mediate):
    f = open(file, 'r')
    s = open(mediate, 'w')
    n = 0
    res = ''

    for line in f:
        n += 1

        line = re.sub("^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}] ", '', line)
        line = re.sub("\s+\S*$", '', line)

        try:
            data = json.loads(line)
        except Exception as e:
            continue

        if len(data['api']) > 1 or len(data['api']) < 1:
            continue

        api = data['api'][0]
        queries = data['query']
        redises = data['redis']

        query_time = 0
        query_count = 0
        for query in queries:
            query_time += query['time']
            query_count += 1

        redis_time = 0
        redis_count = 0
        for redis in redises:
            redis_time += redis['time']
            redis_count += 1

        api_time = api['time']
        php_time = api_time - query_time - redis_time

        uri = re.sub("\d+", 'id', api['uri'])

        res += "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (
        ''.join([api['method'], uri]), api_time, query_time,
        php_time, redis_time, query_count, redis_count, n)

    s.write(res)
    f.close()
    s.close()

    return

""" 分析清洗后的数据
"""
def analyze(mediate):
    s = open(mediate, 'r')
    apis = {}
    all_api_count = 0
    all_api_time = 0.0

    for line in s:
        # print(line)
        info = line.split("\t")
        api_time = round(float(info[1]), 4)
        query_time = round(float(info[2]), 4)
        php_time = round(float(info[3]), 4)
        cache_time = round(float(info[4]), 4)
        query_count = int(info[5])
        cache_count = int(info[6])
        line_num = int(info[7])
        all_api_count += 1
        all_api_time += api_time

        # 按接口分组整理数据
        name = info[0]
        if name not in apis:
            apis[name] = {
                "count": 0, "total": 0.0, "max": 0.0, "min": 99999.9,
                "avg": 0.0, "tp95": 0.0, "max_line": 0, "times": [],
                "php": {"total": 0.0},
                "query": {"total": 0.0, "count": 0, "max_count": 0},
                "cache": {"total": 0.0, "count": 0, "max_count": 0}
            }

        apis[name]["count"] += 1
        apis[name]["total"] += api_time
        apis[name]["times"].append(api_time)

        apis[name]["php"]["total"] += php_time

        apis[name]["query"]["total"] += query_time
        apis[name]["query"]["count"] += query_count
        if query_count > apis[name]["query"]["max_count"]:
            apis[name]["query"]["max_count"] = query_count

        apis[name]["cache"]["total"] += cache_time
        apis[name]["cache"]["count"] += cache_count
        if cache_count > apis[name]["cache"]["max_count"]:
            apis[name]["cache"]["max_count"] = cache_count

        if apis[name]["max"] < api_time:
            apis[name]["max"] = api_time
            apis[name]["max_line"] = line_num
            apis[name]["query"]["max_time"] = query_time
            apis[name]["cache"]["max_time"] = cache_time
            apis[name]["php"]["max_time"] = php_time

        if apis[name]["min"] > api_time:
            apis[name]["min"] = api_time

    for name in apis:
        apis[name]["name"] = name
        apis[name]["avg"] = round(apis[name]["total"] / apis[name]["count"], 4)
        apis[name]["times"].sort()
        apis[name]["pct"] = round((apis[name]["total"] / all_api_time) * 100, 2)
        apis[name]["count_pct"] = round((apis[name]["total"] / all_api_count) * 100, 2)

        tp95 = math.ceil(apis[name]["count"] * 0.95) - 1
        apis[name]["tp95"] = apis[name]["times"][tp95]

        apis[name]["query"]["pct"] = round((apis[name]["query"]["total"] / apis[name]["total"]) * 100, 1)
        apis[name]["cache"]["pct"] = round((apis[name]["cache"]["total"] / apis[name]["total"]) * 100, 1)
        apis[name]["php"]["pct"] = round((100 - apis[name]["query"]["pct"] - apis[name]["cache"]["pct"]), 1)

        apis[name]["query"]["avg_count"] = round(apis[name]["query"]["count"] / apis[name]["count"], 1)
        apis[name]["cache"]["avg_count"] = round(apis[name]["cache"]["count"] / apis[name]["count"], 1)

        apis[name]["query"]["avg_time"] = round(apis[name]["query"]["total"] / apis[name]["count"], 4)
        apis[name]["cache"]["avg_time"] = round(apis[name]["cache"]["total"] / apis[name]["count"], 4)
        apis[name]["php"]["avg_time"] = round(apis[name]["php"]["total"] / apis[name]["count"], 4)

    return apis

""" 渲染模板
"""
def render(apis, sort, file="unknown file"):

    if sort not in ["pct", "count", "max", "min", "tp95", "avg"]:
        sort = "count"

    # 对结果重新排序
    apis = list(apis.values())
    apis = sorted(apis, key = lambda x:x[sort], reverse=True)
    apis = apis[:50]

    datetime = time.strftime("%Y-%m-%d %H:%m:%S", time.localtime())

    tpl = """
# Profile from {{ file }} at {{ datetime }}

# API Profile List (pct = time percentage of all api)
# Rank API Query ID                                          pct   count     max     min     avg    tp95  Max line
# ==== ===========================                        ======  ======  ======  ======  ======  ======  ========
{%- for api in apis %}
# {{ "%-5s"|format(loop.index) }}{{ "%-50s"|format(api["name"]) }}{{ "%6s"|format(api["pct"]) }}%{{ "%8s"|format(api["count"]) }}{{ "%8s"|format(api["max"]) }}{{ "%8s"|format(api["min"]) }}{{ "%8s"|format(api["avg"]) }}{{ "%8s"|format(api["tp95"]) }}{{ "%10s"|format(api["max_line"]) }}
{%- endfor %}

{% for api in apis %}
# Query {{ loop.index }}: ID {{ api["name"] }}, Count {{ api["count"] }}, account for {{ api["count_pct"] }}% APIs
# Query detail (pct = time percentage, mc = max count, ac = avg count, mt = max time, at = avg time)
# Attribute        pct   mc    ac      mt      at
# ============  ======  ===  ====  ======  ======
# Query DB      {{ "%5s"|format(api["query"]["pct"]) }}%{{ "%5s"|format(api["query"]["max_count"]) }}{{ "%6s"|format(api["query"]["avg_count"]) }}{{ "%8s"|format(api["query"]["max_time"]) }}{{ "%8s"|format(api["query"]["avg_time"]) }}
# Req cache     {{ "%5s"|format(api["cache"]["pct"]) }}%{{ "%5s"|format(api["cache"]["max_count"]) }}{{ "%6s"|format(api["cache"]["avg_count"]) }}{{ "%8s"|format(api["cache"]["max_time"]) }}{{ "%8s"|format(api["cache"]["avg_time"]) }}
# Exec PHP      {{ "%5s"|format(api["php"]["pct"]) }}%    -     -{{ "%8s"|format(api["php"]["max_time"]) }}{{ "%8s"|format(api["php"]["avg_time"]) }}
{% endfor %}
"""

    template = Template(tpl)
    return template.render(apis=apis, file=file, datetime=datetime)

""" 发送邮件
"""
def send_mail(content):

    sender = 'system2@system.huoban.com'
    receivers = ['joshua@huoban.com', 'aragorn@huoban.com', 'zhujinhe@huoban.com', 'suixiantong@huoban.com', 'yanzhe@huoban.com', 'leo@huoban.com', 'max@huoban.com', 'jeff@huoban.com', 'hanyang@huoban.com', 'zhujiansheng@huoban.com']

    mail_host="smtpdm.aliyun.com"  #设置服务器
    mail_user="system2@system.huoban.com"    #用户名
    mail_pass="GTxN33K78d2f3esV"   #口令

    message = MIMEText("<pre> %s </pre>" % content, 'html', 'utf-8')
    date = time.strftime("%Y-%m-%d", time.localtime())
    subject = '【%s】接口性能分析报告' % date
    message['Subject'] = Header(subject, 'utf-8')
    message['From'] = Header('huoban_v4_mq.monitor <system2@system.huoban.com>', 'utf-8')

    try:
        smtpObj = smtplib.SMTP('smtpdm.aliyun.com')
        smtpObj.connect(mail_host, 25)
        smtpObj.login(mail_user, mail_pass)
        smtpObj.sendmail(sender, receivers, message.as_string())
        print("发送邮件成功")
    except smtplib.SMTPException as e:
        print(e)
        print("Error: 无法发送邮件")

    return smtpObj.quit()


# 处理请求参数
parser = argparse.ArgumentParser()
parser.add_argument('-step', '-s', help='巡检步骤，第1步：数据清洗；第2步，数据分析；', required=False, default='1')
parser.add_argument('-file', '-f', help='待巡检的日志文件', required=False)
parser.add_argument('-mediate', '-m', required=False,
    help='数据清洗后生成的中间文件，如果指定步骤为2且这个文件存在，则直接使用该文件做数据分析')
parser.add_argument('-sort', '-r', required=False, default='count',
    help='对分析数据按某列倒序排列，默认为请求数量')
parser.add_argument('-mail', '-i', required=False, type=int, default=0,
    help='是否发送邮件')

args = parser.parse_args()
# print(args)

report = ''
if args.step == '1':
    clean(args.file, args.mediate)
elif args.step == '2':
    report = render(analyze(args.mediate), args.sort, args.file)
else:
    clean(args.file, args.mediate)
    report = render(analyze(args.mediate), args.sort, args.file)

print(report)

if (args.mail == 1):
    send_mail(report)
