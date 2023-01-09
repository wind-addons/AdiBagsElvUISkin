local n, ns = ...
local core = ns.core

local function error_handler(...)
    local message = strjoin(" ", ...)
    _G.geterror_handler()(format("%s |cffff3860[ERROR]|r\n%s", "AdiBagsElvUISkinAPI", message))
end

function ns.callApi(wType, frame)
    local funcList = ns.api[wType]
    if not funcList then
        return
    end

    for i = 1, #funcList do
        if funcList[i] then
            xpcall(funcList[i], error_handler, frame)
        end
    end
end

ns.api = {
    moduleButton = {},
    itemButton = {},
    frame = {}
}

-- USAGE:
-- [create your style function first]
-- local function myStyle(frame)
--     doSomething(frame)
-- end
-- [register your style function]
-- AddAdiBagsElvUISkinPostHook("frame", myStyle)

function AddAdiBagsElvUISkinPostHook(type, func)
    if not func or not ns.api[type] then
        return
    end
    tinsert(ns.api[type], func)
end

