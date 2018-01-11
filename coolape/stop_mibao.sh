#!/usr/bin/env bash

#条件关键机
condition="config_mibao"
ps -ef|grep ${condition}|grep -v grep |awk '{print $2}'|xargs -n1 kill -9
