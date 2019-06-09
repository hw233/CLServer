#!/usr/bin/env bash

#条件关键机
projectname="usermgr"
host="127.0.0.1"
#端口参见启动skynet的配置
port=8801
#ps -ef|grep config_${projectname}|grep -v grep |awk '{print $2}'|xargs -n1 kill -9
./skynet/3rd/lua/lua ./coolape/frame/client/CLStopServer.lua ${projectname} ${host} ${port}
