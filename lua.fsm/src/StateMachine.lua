local ERROR = {}

local EMPTY_GUARD = function (value)
	return true
end

local EMPTY_LOGIC = function (value)
end

--------------------------------------------------------------------------------

local Binding = {}
Binding.__index = Binding

function Binding.New()
	local self = setmetatable({}, Binding)

	return self
end

function Binding:Resolve(value)
end

--------------------------------------------------------------------------------

local ErrorBinding = setmetatable({}, {__index = Binding})
ErrorBinding.__index = ErrorBinding

function ErrorBinding.New()
	local self = setmetatable(Binding.New(), ErrorBinding)

	return self
end

function ErrorBinding:Resolve(value)
	return ERROR
end

--------------------------------------------------------------------------------

local LogicBinding = setmetatable({}, {__index = Binding})
LogicBinding.__index = LogicBinding

function LogicBinding.New(logic)
	local self = setmetatable(Binding.New(), LogicBinding)

	self._logic = logic

	return self
end

function LogicBinding:Resolve(value)
	self._logic(value)
end

--------------------------------------------------------------------------------

local StateBinding = setmetatable({}, {__index = Binding})
StateBinding.__index = StateBinding

function StateBinding.New(fsm, state)
	local self = setmetatable(Binding.New(), StateBinding)

	self._fsm = fsm
	self._state = state

	return self
end

function StateBinding:Resolve(value)
	self._fsm:SetCurrent(self._state)
end

--------------------------------------------------------------------------------

local Do = {}
Do.__index = Do

function Do.New(_in)
	local self = setmetatable({}, Do)

	self._in = _in

	return self
end

function Do:On(event)
	return self._in:On(event)
end

--------------------------------------------------------------------------------

local IfDo = {}
IfDo.__index = IfDo

function IfDo.New(_in, on)
	local self = setmetatable({}, IfDo)

	self._in = _in
	self._on = on

	return self
end

function IfDo:On(event)
	return self._in:On(event)
end

function IfDo:If(guard)
	return self._on:If(guard)
end

function IfDo:Go(state)
	return self._on:Go(state)
end

function IfDo:Do(logic)
	return self._on:Do(logic)
end

function IfDo:DoNothing()
	return self:Do(EMPTY_LOGIC)
end

function IfDo:Error()
	return self._on:Error()
end

--------------------------------------------------------------------------------

local FsmGuard = {}
FsmGuard.__index = FsmGuard

function FsmGuard.New(guard)
	local self = setmetatable({}, FsmGuard)

	self._guard = guard
	self._binding = nil

	return self
end

function FsmGuard:SetBinding(binding)
	self._binding = binding
end

function FsmGuard:Trigger(value)
	if not self._guard(value) then
		return false
	end

	local outcome = self._binding:Resolve(value)

	if outcome == ERROR then
		return outcome
	end

	return true
end

--------------------------------------------------------------------------------

local If = {}
If.__index = If

function If.New(fsm, fsmGuard, _in, on)
	local self = setmetatable({}, If)

	self._fsm = fsm
	self._fsmGuard = fsmGuard
	self._in = _in
	self._on = on

	return self
end

function If:Go(state)
	self._fsmGuard:SetBinding(StateBinding.New(self._fsm, state))

	return IfDo.New(self._in, self._on)
end

function If:Do(logic)
	self._fsmGuard:SetBinding(LogicBinding.New(logic))

	return IfDo.New(self._in, self._on)
end

function If:DoNothing()
	return self:Do(EMPTY_LOGIC)
end

function If:Error()
	self._fsmGuard:SetBinding(ErrorBinding.New())

	return IfDo.New(self._in, self._on)
end

--------------------------------------------------------------------------------

local FsmEvent = {}
FsmEvent.__index = FsmEvent

function FsmEvent.New()
	local self = setmetatable({}, FsmEvent)

	self._fsmGuard = {}

	return self
end

function FsmEvent:AddGuard(guard)
	local fsmGuard = FsmGuard.New(guard)
	table.insert(self._fsmGuard, fsmGuard)

	return fsmGuard
end

function FsmEvent:Trigger(value)
	for _, fsmGuard in ipairs(self._fsmGuard) do
		local outcome = fsmGuard:Trigger(value)

		if outcome then
			return outcome
		end
	end

	return false
end

--------------------------------------------------------------------------------

local On = {}
On.__index = On

function On.New(fsm, fsmEvent, _in)
	local self = setmetatable({}, On)

	self._fsm = fsm
	self._fsmEvent = fsmEvent
	self._in = _in

	return self
end

function On:If(guard)
	return If.New(self._fsm, self._fsmEvent:AddGuard(guard), self._in, self)
end

function On:Go(state)
	self:If(EMPTY_GUARD):Go(state)

	return Do.New(self._in)
end

function On:Do(logic)
	self:If(EMPTY_GUARD):Do(logic)

	return Do.New(self._in)
end

function On:DoNothing()
	return self:Do(EMPTY_LOGIC)
end

function On:Error()
	self:If(EMPTY_GUARD):Error()

	return Do.New(self._in)
end

--------------------------------------------------------------------------------

local FsmState = {}
FsmState.__index = FsmState

function FsmState.New()
	local self = setmetatable({}, FsmState)

	self._super = nil

	self._fsmEvent = {}
	self._enter = {}
	self._leave = {}

	return self
end

function FsmState:GetSuper()
	return self._super
end

function FsmState:SetSuper(value)
	self._super = value
end

function FsmState:GetEvent(event)
	local fsmEvent = self._fsmEvent[event]

	if fsmEvent == nil then
		fsmEvent = FsmEvent.New()
		self._fsmEvent[event] = fsmEvent
	end

	return fsmEvent
end

function FsmState:AddEnter(logic)
	table.insert(self._enter, logic)
end

function FsmState:AddLeave(logic)
	table.insert(self._leave, logic)
end

function FsmState:Trigger(event, value)
	local fsmEvent = self._fsmEvent[event]

	if fsmEvent == nil then
		return false
	end

	return fsmEvent:Trigger(value)
end

function FsmState:OnEnter()
	for _, logic in ipairs(self._enter) do
		logic()
	end
end

function FsmState:OnLeave()
	for _, logic in ipairs(self._leave) do
		logic()
	end
end

--------------------------------------------------------------------------------

local In = {}
In.__index = In

function In.New(fsm, fsmState)
	local self = setmetatable({}, In)

	self._fsm = fsm
	self._fsmState = fsmState

	return self
end

function In:Of(super)
	self._fsmState:SetSuper(self._fsm:GetState(super))

	return self
end

function In:On(event)
	return On.New(self._fsm, self._fsmState:GetEvent(event), self)
end

function In:OnEnter(logic)
	self._fsmState:AddEnter(logic)

	return self
end

function In:OnLeave(logic)
	self._fsmState:AddLeave(logic)

	return self
end

--------------------------------------------------------------------------------

local Fsm = {}
Fsm.__index = Fsm

function Fsm.New()
	local self = setmetatable({}, Fsm)

	self._fsmState = {}

	self._start = false

	self._current = nil

	self._trigger = {}

	self._process = false

	self._leave = {}
	self._enter = {}

	return self
end

function Fsm:GetState(state)
	local fsmState = self._fsmState[state]

	if fsmState == nil then
		fsmState = FsmState.New()
		self._fsmState[state] = fsmState
	end

	return fsmState
end

function Fsm:GetCurrent()
	return self._current
end

local function SetCurrent_Reenter(self, state, a)
	a:OnLeave()
	self._current = state
	a:OnEnter()
end

local function Clear(table)
	for i = 1, #table do
		table[i] = nil
	end
end

local function SetCurrent_Process(self, state, a, b, leave, enter)
	local i
	local j

	Clear(leave)

	i = a
	repeat
		Clear(enter)

		j = b
		repeat
			if i == j then
				break
			end

			table.insert(enter, j)
			j = j:GetSuper()
		until j == nil

		if i == j then
			break
		end

		table.insert(leave, i)
		i = i:GetSuper()
	until i == nil

	while next(leave) ~= nil do
		table.remove(leave, 1):OnLeave()
	end

	self._current = state

	while next(enter) ~= nil do
		table.remove(enter):OnEnter()
	end
end

function Fsm:SetCurrent(state)
	local a = self._fsmState[self._current]
	local b = self._fsmState[state]

	assert(b ~= nil)

	if a == b then
		SetCurrent_Reenter(self, state, a)
	else
		SetCurrent_Process(self, state, a, b, self._leave, self._enter)
	end
end

local function Process_Trigger(self, event, value)
	local fsmState = self._fsmState[self._current]
	while fsmState ~= nil do
		local outcome = fsmState:Trigger(event, value)

		if outcome then
			return outcome
		end

		fsmState = fsmState:GetSuper()
	end

	return false
end

local function Process_Outcome(self, trigger)
	local success = Process_Trigger(self, trigger.event, trigger.value)

	if success == ERROR then
		success = false
	end

	if not success then
		error(string.format("%s:%s", tostring(self._current), tostring(trigger.event)))
	end
end

local function Process(self)
	if self._process then
		return
	end

	self._process = true

	while next(self._trigger) ~= nil do
		Process_Outcome(self, table.remove(self._trigger, 1))
	end

	self._process = false
end

function Fsm:Start(state)
	assert(not self._start)

	local b = self._fsmState[state]

	assert(b ~= nil)

	self._start = true

	SetCurrent_Process(self, state, nil, b, self._leave, self._enter)

	Process(self)
end

function Fsm:Trigger(event, value)
	assert(self._start)

	table.insert(self._trigger, {event = event, value = value})

	Process(self)
end

--------------------------------------------------------------------------------

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.New()
	local self = setmetatable({}, StateMachine)

	self._fsm = Fsm.New()

	return self
end

function StateMachine:GetCurrent()
	return self._fsm:GetCurrent()
end

function StateMachine:In(state)
	return In.New(self._fsm, self._fsm:GetState(state))
end

function StateMachine:Start(state)
	self._fsm:Start(state)
end

function StateMachine:Trigger(event, value)
	self._fsm:Trigger(event, value)
end

return StateMachine
