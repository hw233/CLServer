#!/usr/bin/env bash

#生成协议
skynet="./skynet/"
protocolCfg="./coolape/projects/mibao/protocolEditor/defProtocol.lua"
outPath="./coolape/projects/mibao/protocol/"
${skynet}3rd/lua/lua coolape/frame/protoTool/genProtocol.lua ${protocolCfg} ${outPath}
