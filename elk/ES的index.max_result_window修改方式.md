ES的index.max_result_window修改方式

curl -XPUT "http://10.80.155.60:9200/huoban-stats-computation-*/_settings" -H 'Content-Type: application/json' -d'
{ 
"max_result_window" : "5000000" 
}'


curl -XPUT "http://10.80.155.60:9200/postgresql-log-*/_settings" -H 'Content-Type: application/json' -d'
{ 
"max_result_window" : "2000000000" 
}'