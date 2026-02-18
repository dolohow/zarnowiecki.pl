#!/bin/bash

SSH_ADDRESS=$1
REMOTE_DIR=$2

build() {
  rm -r public
  hugo
}

ssh_run() {
  ssh $SSH_ADDRESS $1
}


build
ssh_run "rm -rf $REMOTE_DIR"
ssh_run "mkdir $REMOTE_DIR"
rsync -r public/ $SSH_ADDRESS:$REMOTE_DIR
ssh_run "chown -R nginx.nginx $REMOTE_DIR"
