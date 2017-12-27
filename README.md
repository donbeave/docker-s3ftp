# docker-s3ftp

```bash
docker stop s3ftp
docker rm s3ftp

docker run --restart=always --name s3ftp -d --privileged -p 21:21 -p 30000-30009:30000-30009 \
  -e AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_HERE" \
  -e AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY_HERE" \
  -e AWS_STORAGE_BUCKET_NAME="YOUR_BUCKET_NAME" \
  donbeave/s3ftp:latest
```

## Create user

```bash
pure-pw useradd bob -f /etc/pure-ftpd/passwd/pureftpd.passwd -m -u ftpuser -d /home/ftpusers/bob
```
