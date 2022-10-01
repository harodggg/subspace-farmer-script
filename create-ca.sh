#!/bin/bash
#生成CA私有和公共密钥
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

#创建一个服务器密钥和证书签名请求(CSR)
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=39.97.225.128" -sha256 -new -key server-key.pem -out server.csr

#生成extfile.cnf 文件
cat>./extfile.cnf<<EOF
subjectAltName = DNS:39.97.225.128,IP:39.97.225.128,IP:127.0.0.1
extendedKeyUsage = serverAuth
EOF

#生成key：
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile ./extfile.cnf

#创建客户端密钥和证书签名请求:
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr

#修改extfile.cnf 改为clientAuth
sed -i 's/serverAuth/clientAuth/g' ./extfile.cnf

#生成签名私钥：
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf

#将ca证书和服务器相关密钥证书移到server目录下，将客户端相关密钥证书移动到client目录下。
mkdir ./server
cp ca.pem ./server
mv server-cert.pem ./server
mv server-key.pem ./server
mv ca-key.pem ./server

mkdir ./client
mv ca.pem ./client
mv cert.pem ./client
mv key.pem ./client

#清理csr证书请求文件和其它配置文件
rm -rf ./*.csr
rm -rf  ./ca.srl
rm -rf ./extfile.cnf