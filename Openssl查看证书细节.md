Openssl查看证书细节

打印证书的过期时间
openssl x509 -in signed.crt -noout -dates
打印出证书的内容：
openssl x509 -in cert.pem -noout -text
打印出证书的系列号
openssl x509 -in cert.pem -noout -serial
打印出证书的拥有者名字
openssl x509 -in cert.pem -noout -subject
以RFC2253规定的格式打印出证书的拥有者名字
openssl x509 -in cert.pem -noout -subject -nameopt RFC2253
在支持UTF8的终端一行过打印出证书的拥有者名字
openssl x509 -in cert.pem -noout -subject -nameopt oneline -nameopt -escmsb
打印出证书的MD5特征参数
openssl x509 -in cert.pem -noout -fingerprint
打印出证书的SHA特征参数
openssl x509 -sha1 -in cert.pem -noout -fingerprint
把PEM格式的证书转化成DER格式
openssl x509 -in cert.pem -inform PEM -out cert.der -outform DER
把一个证书转化成CSR
openssl x509 -x509toreq -in cert.pem -out req.pem -signkey key.pem
给一个CSR进行处理，颁发字签名证书，增加CA扩展项
openssl x509 -req -in careq.pem -extfile openssl.cnf -extensions v3_ca -signkey key.pem -out cacert.pem
给一个CSR签名，增加用户证书扩展项
openssl x509 -req -in req.pem -extfile openssl.cnf -extensions v3_usr -CA cacert.pem -CAkey key.pem -CAcreateserial
查看csr文件细节：
openssl req -in my.csr -noout -text