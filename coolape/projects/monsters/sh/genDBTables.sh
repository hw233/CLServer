#!/usr/bin/env bash

#生成协议
projectName="monsters"
database="monsters"
skynet="./skynet/"
protocolCfg="./coolape/projects/${projectName}/dbDesign/"
outPath="./coolape/projects/${projectName}/db/"
${skynet}3rd/lua/lua coolape/frame/dbTool/genDB.lua ${database} ${protocolCfg} ${outPath}
