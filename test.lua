local profiler = require("profiler")
local Class = {}
function Class:Test1(str)
    Test2(str)
end

function Test2(str)
    local func = function(str)
        print(str)
    end
    func(str)
end

profiler.start()

Class:Test1("123")

profiler.stop()

profiler.report()