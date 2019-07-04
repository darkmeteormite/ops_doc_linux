#查询主机
python zabbix_tools.py -H
#查询主机组
python zabbix_tools.py -G
#查询模板信息
python zabbix_tools.py -T
#添加主机组
python zabbix_tools.py -A "Host groups""
#添加主机
python zabbix_tools.py -C 192.168.1.11 huoban "Template OS Linux" node1
# python zabbix_tools.py -C "IP" "Group name" "Templates01,Templates02" hostname
