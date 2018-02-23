local skynet = require "skynet"
---@class cfgUtl
cfgUtl = {}

function cfgUtl.getHeadquartersLevsByID(id)
    local d = skynet.call("CLCfg", "lua", "getDataCfg", "DBCFHeadquartersLevsData", id)
    for k,v in pairs(d) do
        print(k.."=="..v)
    end
    return d
end

return cfgUtl
