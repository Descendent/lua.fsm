# API Reference

### StateMachine

#### Constructors

##### StateMachine New()
Creates and returns a new `StateMachine` instance.

#### Methods (Accessors)

##### dynamic GetCurrent()
Returns this `StateMachine` instance's current state.

#### Methods

##### In In(dynamic state)
Declares state `state` for this `StateMachine` instance. Returns a fluent context.

##### nil Start(dynamic state)
Starts this `StateMachine` instance by performing an initial transition to state `state`. Entry actions for the state and its superstates will be performed as normal.

##### nil Trigger(dynamic event)
##### nil Trigger(dynamic event, dynamic value)
Triggers event `event` for this `StateMachine` instance. Transitions and actions declared for the event will be examined in the order each was declared, starting with the current state, then proceeding up its chain of superstates; the first transition or action with a guard condition that evaluates to `true` (or with no guard condition) will be performed, and consume the event. If `value` is given, it will be passed as the argument to the functions for guard conditions, and actions. If this method is called while this `StateMachine` instance is processing another event, the new event will be queued.

### In

#### Methods

##### In Of(dynamic super)
Declares state `super` as the superstate of this context's state. States inherit event declarations (and associated guard conditions, and transitions and actions) from their superstate. Returns a fluent context.

##### On On(dynamic event)
Declares event `event` for this context's state. Returns a fluent context.

##### In OnEnter(function logic)
Declares `logic` as an entry action for this context's state. Returns a fluent context.

##### In OnLeave(function logic)
Declares `logic` as an exit action for this context's state. Returns a fluent context.

### On

#### Methods

##### If If(function guard)
Declares `guard` as the guard condition for a subsequent transition or action, for this context's event. `guard` must be a function that accepts a dynamic parameter, and returns a Boolean value. Returns a fluent context.

##### Do Go(dynamic state)
Declares state `state` as a transition for this context's event. If `state` is the same as this context's state, the state will be re-entered (its exit and entry actions will be performed) upon transition. Returns a fluent context.

##### Do Do(function logic)
Declares `logic` as an action for this context's event. `logic` must be a function that accepts a dynamic parameter. Returns a fluent context.

##### Do DoNothing()
Declares this context's event as ignored. Returns a fluent context.

##### Do Error()
Declares this context's event as invalid. Returns a fluent context.

### If

#### Methods

##### IfDo Go(dynamic state)
Declares state `state` as the transition for this context's event, when this context's guard condition evaluates to `true`. If `state` is the same as this context's state, the state will be re-entered (its exit and entry actions will be performed) upon transition. Returns a fluent context.

##### IfDo Do(function logic)
Declares `logic` as the action for this context's event, when this context's guard condition evaluates to `true`. `logic` must be a function that accepts a dynamic parameter. Returns a fluent context.

##### IfDo DoNothing()
Declares this context's event as ignored, when this context's guard condition evaluates to `true`. Returns a fluent context.

##### IfDo Error()
Declares this context's event as invalid, when this context's guard condition evaluates to `true`. Returns a fluent context.

### IfDo

#### Methods

##### On On(dynamic event)
Declares event `event` for this context's state. Returns a fluent context.

##### If If(function guard)
Declares `guard` as the guard condition for a subsequent transition or action, for this context's event. `guard` must be a function that accepts a dynamic parameter, and returns a Boolean value. Returns a fluent context.

##### Do Go(dynamic state)
Declares state `state` as a transition for this context's event. If `state` is the same as this context's state, the state will be re-entered (its exit and entry actions will be performed) upon transition. Returns a fluent context.

##### Do Do(function logic)
Declares `logic` as an action for this context's event. `logic` must be a function that accepts a dynamic parameter. Returns a fluent context.

##### Do DoNothing()
Declares this context's event as ignored. Returns a fluent context.

##### Do Error()
Declares this context's event as invalid. Returns a fluent context.

### Do

#### Methods

##### On On(dynamic event)
Declares event `event` for this context's state. Returns a fluent context.

# Examples

## Usage

### Example.lua

```lua
local StateMachine = require("StateMachine")

local _stateMachine = StateMachine.New()

local function TitleEnter()
    print("Enter Title")
end

local function TitleLeave()
    print("Leave Title")
end

local function WorldEnter()
    print("Enter World")
end

local function WorldLeave()
    print("Leave World")
end

local function InventoryEnter()
    print("Enter Inventory")
end

local function InventoryLeave()
    print("Leave Inventory")

    _focus = nil
end

local function Focus(id)
    print(string.format("Focus \"%s\"",
        id))

    _focus = id
end

local function DiscardPreviewEnter()
    print("Enter DiscardPreview")
end

local function DiscardPreviewLeave()
    print("Leave DiscardPreview")
end

local function Discard()
    print(string.format("Discard \"%s\"",
        _focus))
end

_stateMachine:In("Title")
    :OnEnter(TitleEnter)
    :OnLeave(TitleLeave)
    :On("Start"):Go("World")

_stateMachine:In("World")
    :OnEnter(WorldEnter)
    :OnLeave(WorldLeave)
    :On("Inventory"):Go("Inventory")

_stateMachine:In("Inventory")
    :Of("World")
    :OnEnter(InventoryEnter)
    :OnLeave(InventoryLeave)
    :On("Abort"):Go("World")
    :On("Focus"):Do(Focus)
    :On("Discard"):If(function () return _focus ~= nil end):Go("DiscardPreview")

_stateMachine:In("DiscardPreview")
    :Of("Inventory")
    :OnEnter(DiscardPreviewEnter)
    :OnLeave(DiscardPreviewLeave)
    :On("Abort"):Go("Inventory")
    :On("Discard"):Do(Discard)
    :On("DiscardConfirm"):Go("Inventory")

_stateMachine:Start("Title")

-- In Title
print("Trigger Start")
_stateMachine:Trigger("Start")

-- In World
print("Trigger Inventory")
_stateMachine:Trigger("Inventory")

-- In Inventory
print("Trigger Focus \"1\"")
_stateMachine:Trigger("Focus", 1)
print("Trigger Discard")
_stateMachine:Trigger("Discard")

-- In DiscardPreview
print("Trigger Discard")
_stateMachine:Trigger("Discard")
print("Trigger DiscardConfirm")
_stateMachine:Trigger("DiscardConfirm")

-- In Inventory
print("Trigger Abort")
_stateMachine:Trigger("Abort")
```

### 🧾 (Output)

```lua
Enter Title
Trigger Start
Leave Title
Enter World
Trigger Inventory
Enter Inventory
Trigger Focus "1"
Focus "1"
Trigger Discard
Enter DiscardPreview
Trigger Discard
Discard "1"
Trigger DiscardConfirm
Leave DiscardPreview
Trigger Abort
Leave Inventory
```
