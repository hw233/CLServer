-- bio 工具
do
    require("BioInputStream")
    require("BioOutputStream")
    require("CLLPool")

    BioUtl = {}
    local inputStreemPool;
    local outputStreemPool;

    local isInited = false
    function BioUtl.init()
        if isInited then
            return
        end
        isInited = true;
        inputStreemPool = CLLPool.new(LuaB2InputStream);
        outputStreemPool = CLLPool.new(LuaB2OutputStream);
    end

    function BioUtl.writeObject(obj)
        BioUtl.init();
        --local os = LuaB2OutputStream.new();
        local os = outputStreemPool:borrow()
        local status = pcall(BioOutputStream.writeObject, os, obj);
        if status then
            local bytes = os:toBytes();
            os:release();
            --os = nil;
            outputStreemPool:retObj(os)
            return bytes;
        else
            outputStreemPool:retObj(os)
            print(result)
            return nil;
        end
    end

    function BioUtl.readObject(bytes)
        BioUtl.init();
        --local is = LuaB2InputStream.new(bytes);
        local is = inputStreemPool:borrow();
        is:init(bytes);
        local status, result = pcall(BioInputStream.readObject, is);
        if status then
            is:release();
            --is = nil;
            inputStreemPool:retObj(is)
            return result;
        else
            inputStreemPool:retObj(is)
            print(result)
            return nil;
        end
    end

    function BioUtl.int2bio(val)
        BioUtl.init();
        --local os = LuaB2OutputStream.new();
        local os = outputStreemPool:borrow()
        local status = pcall(BioOutputStream.writeInt, os, val);
        if status then
            local bytes = os:toBytes();
            os:release();
            --os = nil;
            outputStreemPool:retObj(os)
            return bytes;
        else
            outputStreemPool:retObj(os)
            print(result)
            return nil;
        end
    end

    function BioUtl.bio2int(bytes)
        BioUtl.init();
        --local is = LuaB2InputStream.new(bytes);
        local is = inputStreemPool:borrow();
        is:init(bytes)
        local status, result = pcall(BioInputStream.readObject, is);
        if status then
            is:release();
            --is = nil;
            inputStreemPool:retObj(is)
            return result;
        else
            print(result)
            inputStreemPool:retObj(is)
            return 0;
        end
    end
    --------------------------------------------
    return BioUtl;
end
