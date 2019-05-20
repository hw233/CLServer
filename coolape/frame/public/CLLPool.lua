require("class")
require("CLLQueue")

---@class CLLPool
CLLPool = class("CLLPool")
--local queue;
--local cloneClass;

function CLLPool:ctor(classObj)
    self.queue = CLLQueue.new(100)
    self.cloneClass = classObj -- 类型，当为ni时，返回空table
end

function CLLPool:createObj()
    if self.cloneClass then
        return self.cloneClass.new()
    else
        return {}
    end
end

function CLLPool:borrow()
    if self.queue:isEmpty() then
        return self:createObj()
    end
    return self.queue:deQueue();
end

function CLLPool:retObj(obj)
    self.queue:enQueue(obj);
end

return CLLPool
