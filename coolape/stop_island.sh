#!/usr/bin/env bash

#条件关键机
projectname="island"
port=8803
#ps -ef|grep config_${projectname}|grep -v grep |awk '{print $2}'|xargs -n1 kill -9
./skynet/skynet ./coolape/frame/service/CLStop_config ${projectname} ${port}
