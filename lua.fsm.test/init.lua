local LuaUnit = require("luaunit")

local StateMachineTest = require("StateMachineTest")

local luaUnit = LuaUnit.LuaUnit.new()

luaUnit:runSuiteByInstances({
	{"StateMachineTest", StateMachineTest}})

os.exit((luaUnit.result.notSuccessCount == nil) or (luaUnit.result.notSuccessCount == 0))
