#!/usr/bin/env bash

#条件关键机
projectname="frame"
host="127.0.0.1"
port=8800
#ps -ef|grep config_${projectname}|grep -v grep |awk '{print $2}'|xargs -n1 kill -9
./skynet/3rd/lua/lua ./coolape/frame/client/CLStopServer.lua ${projectname} ${host} ${port}
