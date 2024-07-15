1. On RHEL/8
```
yum install bind bind-utils -y
systemctl restart named.service
systemctl enable named.service
systemctl status named.serviec
netstat -antp
```

2. Configure

```
vi /etc/named.conf
```