local LuaUnit = require("luaunit")

local StateMachine = require("StateMachine")

local StateMachineTest = {}

local State = {
	STATE_O = "O",
	STATE_A = "A",
	STATE_B = "B",
	STATE_X = "X",
	STATE_XX = "XX",
	STATE_XXX = "XXX",
	STATE_Y = "Y",
	STATE_YY = "YY",
	STATE_YYY = "YYY",
	STATE_Z = "Z",
	STATE_ZZ = "ZZ",
	STATE_ZZZ = "ZZZ"
}

local Event = {
	EVENT_O = "O",
	EVENT_A = "A",
	EVENT_B = "B",
	EVENT_X = "X",
	EVENT_XX = "XX",
	EVENT_XXX = "XXX",
	EVENT_Y = "Y",
	EVENT_YY = "YY",
	EVENT_YYY = "YYY",
	EVENT_Z = "Z",
	EVENT_ZZ = "ZZ",
	EVENT_ZZZ = "ZZZ"
}

local GUARD_SUCCESS = function ()
	return true
end

local GUARD_FAILURE = function ()
	return false
end

function StateMachineTest:TestStart()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)

	stateMachine:Start(State.STATE_O)

	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_O)
end

function StateMachineTest:TestStart_WhereNotValid()
	local stateMachine = StateMachine.New()

	LuaUnit.assertError(function ()
		stateMachine:Start(State.STATE_O)
	end)
end

function StateMachineTest:TestStart_TestOnEnter()
	local stateMachine = StateMachine.New()

	local enter

	stateMachine:In(State.STATE_O)
		:OnEnter(function ()
			enter = true
		end)

	stateMachine:Start(State.STATE_O)

	LuaUnit.assertTrue(enter)
	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_O)
end

function StateMachineTest:TestTrigger_TestGo()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Go(State.STATE_A)

	stateMachine:In(State.STATE_A)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_A)
end

function StateMachineTest:TestTrigger_TestDo()
	local stateMachine = StateMachine.New()

	local logic

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Do(function ()
			logic = true
		end)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertTrue(logic)
	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_O)
end

function StateMachineTest:TestTrigger_TestDo_WithValue()
	local stateMachine = StateMachine.New()

	local logic

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Do(function (value)
			logic = value
		end)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertEquals(logic, value)
	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_O)
end

function StateMachineTest:TestTrigger_TestError()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Error()

	stateMachine:Start(State.STATE_O)

	LuaUnit.assertError(function ()
		stateMachine:Trigger(Event.EVENT_A)
	end)
end

function StateMachineTest:TestTrigger_WhereNotValid()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)

	stateMachine:Start(State.STATE_O)

	LuaUnit.assertError(function ()
		stateMachine:Trigger(Event.EVENT_A)
	end)
end

function StateMachineTest:TestTrigger_TestOnEnter()
	local stateMachine = StateMachine.New()

	local enter

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Go(State.STATE_A)

	stateMachine:In(State.STATE_A)
		:OnEnter(function ()
			enter = true
		end)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertTrue(enter)
	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_A)
end

function StateMachineTest:TestTrigger_TestOnLeave()
	local stateMachine = StateMachine.New()

	local leave

	stateMachine:In(State.STATE_O)
		:OnLeave(function ()
			leave = true
		end)
		:On(Event.EVENT_A):Go(State.STATE_A)

	stateMachine:In(State.STATE_A)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertTrue(leave)
	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_A)
end

function StateMachineTest:TestTrigger_TestOnEnter_TestOnLeave_WhereStateReenter()
	local stateMachine = StateMachine.New()

	local log = {}

	stateMachine:In(State.STATE_O)
		:OnEnter(function ()
			table.insert(log, "enter")
		end)
		:OnLeave(function ()
			table.insert(log, "leave")
		end)
		:On(Event.EVENT_O):Go(State.STATE_O)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_O)

	LuaUnit.assertEquals(log, {"enter", "leave", "enter"})
	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_O)
end

function StateMachineTest:TestTrigger_TestIf_WhereGuardSuccess()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):If(GUARD_SUCCESS):Go(State.STATE_A)

	stateMachine:In(State.STATE_A)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_A)
end

function StateMachineTest:TestTrigger_TestIf_WhereGuardFailure()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):If(GUARD_FAILURE):Go(State.STATE_A)

	stateMachine:In(State.STATE_A)

	stateMachine:Start(State.STATE_O)

	LuaUnit.assertError(function ()
		stateMachine:Trigger(Event.EVENT_A)
	end)
end

function StateMachineTest:TestTrigger_TestIf_WhereGuardFailureAndGuardSuccess()
	local stateMachine = StateMachine.New()

	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):If(GUARD_FAILURE):Go(State.STATE_A)
		:On(Event.EVENT_A):If(GUARD_SUCCESS):Go(State.STATE_X)

	stateMachine:In(State.STATE_A)

	stateMachine:In(State.STATE_X)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_X)
end

function StateMachineTest:TestTrigger_TestOf()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Go(State.STATE_A)
		:On(Event.EVENT_B):Go(State.STATE_B)

	stateMachine:In(State.STATE_A)
		:Of(State.STATE_O)

	stateMachine:In(State.STATE_B)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)
	stateMachine:Trigger(Event.EVENT_B)

	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_B)
end

function StateMachineTest:TestTrigger_TestOf_WhereOverrides()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Go(State.STATE_A)
		:On(Event.EVENT_B):Error()

	stateMachine:In(State.STATE_A)
		:Of(State.STATE_O)
		:On(Event.EVENT_B):Go(State.STATE_B)

	stateMachine:In(State.STATE_B)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)
	stateMachine:Trigger(Event.EVENT_B)

	LuaUnit.assertEquals(stateMachine:GetCurrent(), State.STATE_B)
end

function StateMachineTest:TestTrigger_TestOf_WhereOverridesAndError()
	local stateMachine = StateMachine.New()

	stateMachine:In(State.STATE_O)
		:On(Event.EVENT_A):Go(State.STATE_A)
		:On(Event.EVENT_B):Go(State.STATE_B)

	stateMachine:In(State.STATE_A)
		:Of(State.STATE_O)
		:On(Event.EVENT_B):Error()

	stateMachine:In(State.STATE_B)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_A)

	LuaUnit.assertError(function ()
		stateMachine:Trigger(Event.EVENT_B)
	end)
end

function StateMachineTest:TestTrigger_TestOf_TestOnEnter_TestOnLeave()
	local stateMachine = StateMachine.New()

	local log = {}

	stateMachine:In(State.STATE_O)
		:OnEnter(function () table.insert(log, "enter(O)") end)
		:OnLeave(function () table.insert(log, "leave(O)") end)
		:On(Event.EVENT_XXX):Go(State.STATE_XXX)

	stateMachine:In(State.STATE_X)
		:Of(State.STATE_O)
		:OnEnter(function () table.insert(log, "enter(X)") end)
		:OnLeave(function () table.insert(log, "leave(X)") end)
		:On(Event.EVENT_Y):Go(State.STATE_Y)

	stateMachine:In(State.STATE_XX)
		:Of(State.STATE_X)
		:OnEnter(function () table.insert(log, "enter(XX)") end)
		:OnLeave(function () table.insert(log, "leave(XX)") end)

	stateMachine:In(State.STATE_XXX)
		:Of(State.STATE_XX)
		:OnEnter(function () table.insert(log, "enter(XXX)") end)
		:OnLeave(function () table.insert(log, "leave(XXX)") end)
		:On(Event.EVENT_X):Go(State.STATE_X)

	stateMachine:In(State.STATE_Y)
		:Of(State.STATE_O)
		:OnEnter(function () table.insert(log, "enter(Y)") end)
		:OnLeave(function () table.insert(log, "leave(Y)") end)
		:On(Event.EVENT_YYY):Go(State.STATE_YYY)

	stateMachine:In(State.STATE_YY)
		:Of(State.STATE_Y)
		:OnEnter(function () table.insert(log, "enter(YY)") end)
		:OnLeave(function () table.insert(log, "leave(YY)") end)

	stateMachine:In(State.STATE_YYY)
		:Of(State.STATE_YY)
		:OnEnter(function () table.insert(log, "enter(YYY)") end)
		:OnLeave(function () table.insert(log, "leave(YYY)") end)
		:On(Event.EVENT_ZZZ):Go(State.STATE_ZZZ)

	stateMachine:In(State.STATE_Z)
		:OnEnter(function () table.insert(log, "enter(Z)") end)
		:OnLeave(function () table.insert(log, "leave(Z)") end)

	stateMachine:In(State.STATE_ZZ)
		:Of(State.STATE_Z)
		:OnEnter(function () table.insert(log, "enter(ZZ)") end)
		:OnLeave(function () table.insert(log, "leave(ZZ)") end)

	stateMachine:In(State.STATE_ZZZ)
		:Of(State.STATE_ZZ)
		:OnEnter(function () table.insert(log, "enter(ZZZ)") end)
		:OnLeave(function () table.insert(log, "leave(ZZZ)") end)

	stateMachine:Start(State.STATE_O)

	stateMachine:Trigger(Event.EVENT_XXX)
	stateMachine:Trigger(Event.EVENT_X)
	stateMachine:Trigger(Event.EVENT_Y)
	stateMachine:Trigger(Event.EVENT_YYY)
	stateMachine:Trigger(Event.EVENT_ZZZ)

	LuaUnit.assertEquals(log, {
		"enter(O)",
		"enter(X)",
		"enter(XX)",
		"enter(XXX)",
		"leave(XXX)",
		"leave(XX)",
		"leave(X)",
		"enter(Y)",
		"enter(YY)",
		"enter(YYY)",
		"leave(YYY)",
		"leave(YY)",
		"leave(Y)",
		"leave(O)",
		"enter(Z)",
		"enter(ZZ)",
		"enter(ZZZ)"
	})
end

return StateMachineTest
