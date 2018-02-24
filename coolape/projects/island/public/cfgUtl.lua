local skynet = require "skynet"
---@class cfgUtl
cfgUtl = {}

function cfgUtl.getHeadquartersLevsByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFHeadquartersLevsData", id)
end

return cfgUtl
