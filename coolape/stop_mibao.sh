#!/usr/bin/env bash

#条件关键机
projectname="mibao"
ps -ef|grep config_${projectname}|grep -v grep |awk '{print $2}'|xargs -n1 kill -9
