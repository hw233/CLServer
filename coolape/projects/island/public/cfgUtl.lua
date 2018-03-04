local skynet = require "skynet"
---@class cfgUtl
cfgUtl = {}

-- 取得主基地等级开放
function cfgUtl.getHeadquartersLevsByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFHeadquartersLevsData", id)
end

-- 取得地块的cfg
function cfgUtl.getTileByID(id)
    return skynet.call("CLCfg", "lua", "getDataCfg", "DBCFTileData", id)
end

return cfgUtl
