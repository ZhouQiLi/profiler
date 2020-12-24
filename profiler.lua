local maxInteger = math.maxinteger
local getInfo = debug.getinfo
local remove = table.remove
local format = string.format
local gsub = string.gsub
local getTime = os.clock
local collectgarbage = collectgarbage
local invokeStack = {}
local startTime = 0
local stopTime = 0


local function selectFileName(fileName)
    local result
    gsub(fileName, "([^/]+)", function(c) result = c end)
    return result or "unknown"
end

local index = 0
local function ClosureId()
    index = index + 1
    return "closure" .. index
end

local arrays = {}
local maps = {}
local function record(info, used)
    local fileName = selectFileName(info.short_src)
    local func = fileName..info.linedefined
    local data = maps[func]
    if not data then
        maps[func] = {
            total = 0,
            count = 0,
            min = maxInteger,
            max = 0,
            file = fileName,
            funcName = info.name or ClosureId(),
            line = info.linedefined
        }
        data = maps[func]
        arrays[#arrays+1] = data
    end
    data.total = data.total + used
    data.count = data.count + 1
    if data.min > used then
        data.min = used
    end
    if data.max < used then
        data.max = used
    end
end

local function hook(event)
    local info = getInfo(2, "lSfn")
    if info.what ~= "Lua" then
        return
    end
    if event == "return" then
        if #invokeStack > 0 then
            local used = getTime() - remove(invokeStack)
            record(info, used)
            collectgarbage("step", 100)
        end
    else
        invokeStack[#invokeStack + 1] = getTime()
    end
end

local accuracy = 10 ^ 4
local function SetAccuracy(num)
    if not num then
        return 0
    end
    return math.floor(num * accuracy) / accuracy
end

local fileName = "profiler.csv"
local invokeInfoFormat =  "%s,%s,%s,%s,%s,%s,%s,%s,%s\n"
local function report(s)
    if s then
        fileName = s
    end
    table.sort(arrays, function(a, b) return a.total > b.total end)
    local file = io.open(fileName, "w+")
    if not file then
        file = io.open(os.time() .. fileName, "w+")
    end
    if not file then
        return
    end
    file:write("FILE,FUNCTION,LINE,TOTAL,AVG,MIN,MAX,%,COUNT\n")
    local totalUsed = (stopTime or getTime()) - startTime
    local invokeInfo
    local total, avg, min, max, percent = 0, 0, 0, 0, 0
    for i, info in ipairs(arrays) do
        total = SetAccuracy(info.total)
        avg = SetAccuracy(info.total / info.count)
        min = SetAccuracy(info.min)
        max = SetAccuracy(info.max)
        percent = SetAccuracy(info.total == 0 and 0 or (total / totalUsed))
        invokeInfo = format(invokeInfoFormat, info.file, info.funcName, info.line, total, avg, min, max, percent, info.count)
        file:write(invokeInfo)
    end
    file:close()
end

local profiler = {}

function profiler.start()
    startTime = getTime()
    debug.sethook(hook, "cr")
end

function profiler.stop()
    stopTime = getTime()
    debug.sethook()
end

function profiler.report(filePath)
    report(filePath)
end

return profiler