#!/usr/bin/python
import os
import json
 
data = {}
tcp_list = []
port_list = []
command = "ss -tln | sed -n '3,$p' | awk '{print $4}' | awk -F':' '{print $NF}'"
lines = os.popen(command).readlines()
for line in lines:
    port=line.strip('\n')
#   port = line.split(':')[1]
    port_list.append(port)
 
for port in list(set(port_list)):
    port_dict = {}
    port_dict['{#TCP_PORT}'] = port
    tcp_list.append(port_dict)
 
data['data'] = tcp_list
jsonStr = json.dumps(data, sort_keys=True, indent=4)
print jsonStr
