#!/bin/bash
set -e

# Defaults
: ${AWS_S3_AUTHFILE:='/root/.s3fs'}
: ${AWS_S3_MOUNTPOINT:='/home/ftpusers'}
: ${AWS_S3_URL:='https://s3.amazonaws.com'}
: ${S3FS_ARGS:=''}

# Configuration checks
if [ -z "$AWS_STORAGE_BUCKET_NAME" ]; then
    echo "Error: AWS_STORAGE_BUCKET_NAME is not specified"
    exit 128
fi

if [ ! -f "${AWS_S3_AUTHFILE}" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Error: AWS_ACCESS_KEY_ID not specified, or ${AWS_S3_AUTHFILE} not provided"
    exit 128
fi

if [ ! -f "${AWS_S3_AUTHFILE}" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_SECRET_ACCESS_KEY not specified, or ${AWS_S3_AUTHFILE} not provided"
    exit 128
fi

# Write auth file if it does not exist
if [ ! -f "${AWS_S3_AUTHFILE}" ]; then
   echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > ${AWS_S3_AUTHFILE}
   chmod 400 ${AWS_S3_AUTHFILE}
fi

echo "> Mounting S3 Filesystem"
mkdir -p ${AWS_S3_MOUNTPOINT}

chown -R ftpuser:ftpgroup ${AWS_S3_MOUNTPOINT}

# s3fs mount command
_COMMAND="s3fs $S3FS_ARGS -o passwd_file=${AWS_S3_AUTHFILE} -o allow_other -o url=${AWS_S3_URL} ${AWS_STORAGE_BUCKET_NAME} ${AWS_S3_MOUNTPOINT}"

echo $_COMMAND

`$_COMMAND`

ls /home/ftpusers

echo "> Running FTP Server"

# start rsyslog
rsyslogd


# build up flags passed to this file on run + env flag for additional flags
# e.g. -e "ADDED_FLAGS=--tls=2"
PURE_FTPD_FLAGS="$@ -c 5 -C 5 -l puredb:/etc/pure-ftpd/pureftpd.pdb -E -j -R -P $PUBLICHOST -p 30000:30009 -d -d -O w3c:/var/log/pure-ftpd/transfer.log"


# Load in any existing db from volume store
if [ -e /etc/pure-ftpd/passwd/pureftpd.passwd ]
then
    pure-pw mkdb /etc/pure-ftpd/pureftpd.pdb -f /etc/pure-ftpd/passwd/pureftpd.passwd
fi

echo "  pure-ftpd $PURE_FTPD_FLAGS"

exec /usr/sbin/pure-ftpd $PURE_FTPD_FLAGS
