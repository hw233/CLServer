#!/usr/bin/env bash

#生成协议
projectName="island"
skynet="./skynet/"
protocolCfg="./coolape/projects/${projectName}/protocolEditor/defProtocol.lua"
outPath="./coolape/projects/${projectName}/protocol/"
${skynet}3rd/lua/lua coolape/frame/protoTool/genProtocol.lua ${protocolCfg} ${outPath}
