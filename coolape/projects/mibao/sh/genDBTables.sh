#!/usr/bin/env bash

#生成协议
skynet="./skynet/"
protocolCfg="./coolape/projects/mibao/dbDesign/"
outPath="./coolape/projects/mibao/db/"
${skynet}3rd/lua/lua coolape/frame/dbTool/genDB.lua ${protocolCfg} ${outPath}
