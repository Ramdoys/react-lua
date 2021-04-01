-- upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/__tests__/ReactComponentLifeCycle-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
--[[*
 * TODO: We should make any setState calls fail in
 * `getInitialState` and `componentWillMount`. They will usually fail
 * anyways because `this._renderedComponent` is empty, however, if a component
 * is *reused*, then that won't be the case and things will appear to work in
 * some cases. Better to just block all updates in initialization.
 ]]
return function()
  local HttpService = game:GetService("HttpService")
  local Workspace = script.Parent.Parent.Parent
  local RobloxJest = require(Workspace.RobloxJest)

  local Packages = Workspace.Parent
  local Error = require(Packages.LuauPolyfill).Error

  -- deviation: Move all of the following into the test function body to match
  -- convention
  local React
  -- local ReactDOM
  local ReactNoop
  -- local ReactTestUtils
  -- local PropTypes

  local clone = function(o)
    return HttpService:JSONDecode(HttpService:JSONEncode(o))
  end

  local GET_INIT_STATE_RETURN_VAL = {
    hasWillMountCompleted = false,
    hasRenderCompleted = false,
    hasDidMountCompleted = false,
    hasWillUnmountCompleted = false,
  }

  local INIT_RENDER_STATE = {
    hasWillMountCompleted = true,
    hasRenderCompleted = false,
    hasDidMountCompleted = false,
    hasWillUnmountCompleted = false,
  }

  local DID_MOUNT_STATE = {
    hasWillMountCompleted = true,
    hasRenderCompleted = true,
    hasDidMountCompleted = false,
    hasWillUnmountCompleted = false,
  }

  local NEXT_RENDER_STATE = {
    hasWillMountCompleted = true,
    hasRenderCompleted = true,
    hasDidMountCompleted = true,
    hasWillUnmountCompleted = false,
  }

  local WILL_UNMOUNT_STATE = {
    hasWillMountCompleted = true,
    hasDidMountCompleted = true,
    hasRenderCompleted = true,
    hasWillUnmountCompleted = false,
  }

  local POST_WILL_UNMOUNT_STATE = {
    hasWillMountCompleted = true,
    hasDidMountCompleted = true,
    hasRenderCompleted = true,
    hasWillUnmountCompleted = true,
  }

  --[[
    Every React component is in one of these life cycles.
    * MOUNTED
      * Mounted components have a DOM node representation and are capable of
      receiving new props.
    * UNMOUNTED
      * Unmounted components are inactive and cannot receive new props.
  ]]
  type ComponentLifeCycle = string

  local function getLifeCycleState(instance): ComponentLifeCycle
    return instance.updater.isMounted(instance) and "MOUNTED" or "UNMOUNTED"
  end

  beforeEach(function()
    RobloxJest.resetModules()
    RobloxJest.useFakeTimers()
    -- deviation: In react, jest _always_ mocks Scheduler -> unstable_mock;
    -- in our case, we need to do it anywhere we want to use the scheduler,
    -- directly or indirectly, until we have some form of bundling logic
    RobloxJest.mock(Workspace.Scheduler, function()
      return require(Workspace.Scheduler.unstable_mock)
    end)

    React = require(Workspace.React)
    ReactNoop = require(Workspace.ReactNoopRenderer)
    -- ReactDOM = require('react-dom')
    -- ReactTestUtils = require('react-dom/test-utils')
    -- PropTypes = require('prop-types')
  end)

  -- xit('should not reuse an instance when it has been unmounted', function()
  --   local container = document.createElement('div')

  --   class StatefulComponent extends React.Component {
  --     state = {}

  --     render()
  --       return <div />
  --     end
  --   end

--     local element = <StatefulComponent />
--     local firstInstance = ReactDOM.render(element, container)
--     ReactDOM.unmountComponentAtNode(container)
--     local secondInstance = ReactDOM.render(element, container)
--     expect(firstInstance).not.toBe(secondInstance)
--   })

--   --[[*
--    * If a state update triggers rerendering that in turn fires an onDOMReady,
--    * that second onDOMReady should not fail.
--    ]]
--   xit('it should fire onDOMReady when already in onDOMReady', function()
--     local _testJournal = []

--     class Child extends React.Component {
--       componentDidMount()
--         _testJournal.push('Child:onDOMReady')
--       end

--       render()
--         return <div />
--       end
--     end

--     class SwitcherParent extends React.Component {
--       constructor(props)
--         super(props)
--         _testJournal.push('SwitcherParent:getInitialState')
--         this.state = {showHasOnDOMReadyComponent: false}
--       end

--       componentDidMount()
--         _testJournal.push('SwitcherParent:onDOMReady')
--         this.switchIt()
--       end

--       switchIt = function()
--         this.setState({showHasOnDOMReadyComponent: true})
--       end

--       render()
--         return (
--           <div>
--             {this.state.showHasOnDOMReadyComponent ? <Child /> : <div />}
--           </div>
--         )
--       end
--     end

--     ReactTestUtils.renderIntoDocument(<SwitcherParent />)
--     expect(_testJournal).toEqual([
--       'SwitcherParent:getInitialState',
--       'SwitcherParent:onDOMReady',
--       'Child:onDOMReady',
--     ])
--   })

  -- You could assign state here, but not access members of it, unless you
  -- had provided a getInitialState method.
  it("throws when accessing state in componentWillMount", function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect
    local StatefulComponent = React.Component:extend("StatefulComponent")

    function StatefulComponent:UNSAFE_componentWillMount()
      -- ROBLOX deviation: ensure self is non nil
      expect(self).never.toEqual(nil)

      return self.state.yada
    end

    function StatefulComponent:render()
      -- ROBLOX deviation: ensure self is non nil
      expect(self).never.toEqual(nil)
      return React.createElement("div")
    end

    local instance = React.createElement(StatefulComponent)
    expect(function()
      ReactNoop.act(function()
        instance = ReactNoop.render(instance)
      end)
    -- deviation
    end).toThrow("yada")
  end)

  it('should allow update state inside of componentWillMount', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect
    local StatefulComponent = React.Component:extend("StatefulComponent")

    function StatefulComponent:UNSAFE_componentWillMount()
      self:setState({stateField = "something"})
    end

    function StatefulComponent:render()
      return React.createElement("div")
    end

    local instance = React.createElement(StatefulComponent)
    expect(function()
      ReactNoop.act(function()
        instance = ReactNoop.render(instance)
      end)
    end).never.toThrow()
  end)

  it("warns if setting 'self.state = props'", function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect
    local StatefulComponent = React.Component:extend("StatefulComponent")

    function StatefulComponent:init()
      self.state = self.props
    end

    function StatefulComponent:render()
      return React.createElement("div")
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(StatefulComponent))
      end)
    end).toErrorDev(
      "StatefulComponent: It is not recommended to assign props directly to state " ..
        "because updates to props won't be reflected in state. " ..
        "In most cases, it is better to use props directly."
    )
  end)

  -- Not sure why I couldn't get this one to work
  -- ROBLOX deviation? setState doesn't exist on the instance during init()
  it('should not allow update state inside of getInitialState', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local StatefulComponent = React.Component:extend("StatefulComponent")

    function StatefulComponent:init()
      self:setState({stateField = 'something'})
      self.state = {stateField = 'somethingelse'}
    end

    function StatefulComponent:render()
      return React.createElement("div")
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(StatefulComponent))
      end)
    end).toErrorDev(
      "Warning: Can't call setState on a component that is not yet mounted. " ..
        "This is a no-op, but it might indicate a bug in your application. " ..
        "Instead, assign to `self.state` directly with the desired state " ..
        "in the StatefulComponent component's `init` method."
    )

    -- Check deduplication; (no extra warnings should be logged).
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(StatefulComponent))
    end)
  end)

  it('should correctly determine if a component is mounted', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local isMounted
    local Component = React.Component:extend("Component")

    function Component:init()
      isMounted = function()
        -- No longer a public API, but we can test that it works internally by
        -- reaching into the updater.
        return self.updater.isMounted(self)
      end
    end
    function Component:UNSAFE_componentWillMount()
      expect(isMounted()).to.equal(false)
    end
    function Component:componentDidMount()
      -- ROBLOX deviation: assert self is non nil
      expect(self).never.toEqual(nil)
      expect(isMounted()).to.equal(true)
    end
    function Component:render()
      expect(isMounted()).to.equal(false)
      return React.createElement("div")
    end

    local element = React.createElement(Component)

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(element)
      end)
      expect(isMounted()).to.equal(true)
    end).toErrorDev(
      {
        "Component is accessing isMounted inside its render()",
        "UNSAFE_componentWillMount in strict mode is not recommended",
      },
      {withoutStack = 1}
    )
  end)

  it('should correctly determine if a nil component is mounted', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local isMounted
    local Component = React.Component:extend("Component")

    function Component:init()
      isMounted = function()
        -- No longer a public API, but we can test that it works internally by
        -- reaching into the updater.
        return self.updater.isMounted(self)
      end
    end
    function Component:UNSAFE_componentWillMount()
      expect(isMounted()).to.equal(false)
    end
    function Component:componentDidMount()
      expect(isMounted()).to.equal(true)
    end
    function Component:render()
      expect(isMounted()).to.equal(false)
      return nil
    end

    local element = React.createElement(Component)

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(element)
      end)
      expect(isMounted()).to.equal(true)
    end).toErrorDev(
      {
        "Component is accessing isMounted inside its render()",
        "UNSAFE_componentWillMount in strict mode is not recommended",
      },
      {withoutStack = 1}
    )
  end)

  it('isMounted should return false when unmounted', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local isMounted
    local Component = React.Component:extend("Component")
    function Component:init()
      isMounted = function()
        return self.updater.isMounted(self)
      end
    end
    function Component:render()
      return React.createElement("div")
    end

    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component))
    end)

    -- No longer a public API, but we can test that it works internally by
    -- reaching into the updater.
    expect(isMounted()).to.equal(true)

    ReactNoop.act(function()
      ReactNoop.render(nil)
    end)

    expect(isMounted()).to.equal(false)
  end)

--   xit('warns if findDOMNode is used inside render', function()
--     class Component extends React.Component {
--       state = {isMounted: false}
--       componentDidMount()
--         this.setState({isMounted: true})
--       end
--       render()
--         if this.state.isMounted)
--           expect(ReactDOM.findDOMNode(this).tagName).toBe('DIV')
--      end
--         return <div />
--       end
--  end

--     expect(function()
--       ReactNoop.render(<Component />)
--     }).toErrorDev('Component is accessing findDOMNode inside its render()')
--   })

  it('should carry through each of the phases of setup', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local _testJournal: any = {}
    local getTestLifeCycleState, getInstanceState
    local LifeCycleComponent = React.Component:extend("LifeCycleComponent")
    function LifeCycleComponent:init()
      local initState = {
        hasWillMountCompleted = false,
        hasDidMountCompleted = false,
        hasRenderCompleted = false,
        hasWillUnmountCompleted = false,
      }
      getTestLifeCycleState = function()
        return getLifeCycleState(self)
      end
      getInstanceState = function()
        return self.state
      end
      _testJournal.returnedFromGetInitialState = clone(initState)
      _testJournal.lifeCycleAtStartOfGetInitialState = getTestLifeCycleState()
      self.state = initState
    end

    function LifeCycleComponent:UNSAFE_componentWillMount()
      _testJournal.stateAtStartOfWillMount = clone(self.state)
      _testJournal.lifeCycleAtStartOfWillMount = getTestLifeCycleState()
      self.state.hasWillMountCompleted = true
    end

    function LifeCycleComponent:componentDidMount()
      _testJournal.stateAtStartOfDidMount = clone(self.state)
      _testJournal.lifeCycleAtStartOfDidMount = getTestLifeCycleState()
      self:setState({hasDidMountCompleted = true})
    end

    function LifeCycleComponent:render()
        local isInitialRender = not self.state.hasRenderCompleted
        if isInitialRender then
          _testJournal.stateInInitialRender = clone(self.state)
          _testJournal.lifeCycleInInitialRender = getTestLifeCycleState()
        else
          _testJournal.stateInLaterRender = clone(self.state)
          _testJournal.lifeCycleInLaterRender = getTestLifeCycleState()
        end
        -- you would *NEVER* do anything like this in real code!
        self.state.hasRenderCompleted = true
        return React.createElement("TextLabel", { Text = "I am the inner DIV" })
      end

    function LifeCycleComponent:componentWillUnmount()
      -- ROBLOX deviation: assert self is non nil
      expect(self).never.toEqual(nil)

      _testJournal.stateAtStartOfWillUnmount = clone(self.state)
      _testJournal.lifeCycleAtStartOfWillUnmount = getTestLifeCycleState()
      self.state.hasWillUnmountCompleted = true
    end

    -- A component that is merely "constructed" (as in "constructor") but not
    -- yet initialized, or rendered.
    --
    -- local container = document.createElement('div')

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(LifeCycleComponent))
      end)
    end).toErrorDev(
      {
        "LifeCycleComponent is accessing isMounted inside its render() function",
        "UNSAFE_componentWillMount in strict mode is not recommended",
      },
      {withoutStack = 1}
    )

    -- getInitialState
    expect(_testJournal.returnedFromGetInitialState).toEqual(
      GET_INIT_STATE_RETURN_VAL
    )
    expect(_testJournal.lifeCycleAtStartOfGetInitialState).to.equal(
      'UNMOUNTED'
    )

    -- componentWillMount
    expect(_testJournal.stateAtStartOfWillMount).toEqual(
      _testJournal.returnedFromGetInitialState
    )
    expect(_testJournal.lifeCycleAtStartOfWillMount).to.equal('UNMOUNTED')

    -- componentDidMount
    expect(_testJournal.stateAtStartOfDidMount).toEqual(
      DID_MOUNT_STATE
    )
    expect(_testJournal.lifeCycleAtStartOfDidMount).to.equal('MOUNTED')

    -- initial render
    expect(_testJournal.stateInInitialRender).toEqual(
      INIT_RENDER_STATE
    )
    expect(_testJournal.lifeCycleInInitialRender).to.equal('UNMOUNTED')

    expect(getTestLifeCycleState()).to.equal('MOUNTED')

    -- Now *update the component*
    -- instance.forceUpdate()
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(LifeCycleComponent))
    end)

    -- render 2nd time
    expect(_testJournal.stateInLaterRender).toEqual(NEXT_RENDER_STATE)
    expect(_testJournal.lifeCycleInLaterRender).to.equal('MOUNTED')

    expect(getTestLifeCycleState()).to.equal('MOUNTED')

    ReactNoop.act(function()
      ReactNoop.render(nil)
    end)

    expect(_testJournal.stateAtStartOfWillUnmount).toEqual(
      WILL_UNMOUNT_STATE
    )
    -- componentWillUnmount called right before unmount.
    expect(_testJournal.lifeCycleAtStartOfWillUnmount).to.equal('MOUNTED')

    -- But the current lifecycle of the component is unmounted.
    expect(getTestLifeCycleState()).to.equal('UNMOUNTED')
    expect(getInstanceState()).toEqual(POST_WILL_UNMOUNT_STATE)
  end)

  -- getting to the real error here requires commenting out many try/catch, but here it is:
--   LoadedCode.RoactAlignment.Modules.Scheduler.forks.SchedulerHostConfig.mock:172: Already flushing work.
-- LoadedCode.RoactAlignment.Modules.Scheduler.forks.SchedulerHostConfig.mock:172
-- LoadedCode.RoactAlignment.Modules.ReactNoopRenderer.createReactNoop:1242 function noopAct
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.__tests__.ReactComponentLifeCycle.spec:538 function updateTooltip
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.__tests__.ReactComponentLifeCycle.spec:528 function componentDidMount
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberCommitWork.new:820
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberCommitWork.new:661 function recursivelyCommitLayoutEffects
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberCommitWork.new:613 function recursivelyCommitLayoutEffects
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberCommitWork.new:613 function recursivelyCommitLayoutEffects
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberWorkLoop.new:2103
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberWorkLoop.new:1906
-- LoadedCode.RoactAlignment.Modules.Scheduler.Scheduler:210 function unstable_runWithPriority
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.SchedulerWithReactIntegration.new:164 function runWithPriority
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberWorkLoop.new:1903
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberWorkLoop.new:980
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberWorkLoop.new:860
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.ReactFiberWorkLoop.new:758
-- LoadedCode.RoactAlignment.Modules.Scheduler.Scheduler:160
-- LoadedCode.RoactAlignment.Modules.Scheduler.Scheduler:129
-- LoadedCode.RoactAlignment.Modules.Scheduler.forks.SchedulerHostConfig.mock:180
-- LoadedCode.RoactAlignment.Modules.ReactNoopRenderer.createReactNoop:1242 function noopAct
-- LoadedCode.RoactAlignment.Modules.ReactReconciler.__tests__.ReactComponentLifeCycle.spec:575

-- ROBLOX TODO: throws LoadedCode.RoactAlignment.Packages.Modules.Scheduler.forks.SchedulerHostConfig.mock:172: Already flushing work.
xit('should not throw when updating an auxiliary component', function()
    local Tooltip = React.Component:extend("Tooltip")
    function Tooltip:render()
      return React.createElement("div", nil, self.props.children)
    end

    function Tooltip:componentDidMount()
      self.container = "some container"
      self:updateTooltip()
    end

    function Tooltip:componentDidUpdate()
      self:updateTooltip()
    end

    function Tooltip:updateTooltip()
      -- Even though this.props.tooltip has an owner, updating it shouldn't
      -- throw here because it's mounted as a root component
      ReactNoop.act(function()
        ReactNoop.renderToRootWithID(self.props.tooltip, self.container)
      end)
    end

    local Component = React.Component:extend("Component")

    function Component:render()
      return React.createElement(Tooltip,
        {tooltip = React.createElement("div", nil, self.props.tooltipText)},
        self.props.text
      )
    end

    ReactNoop.act(function()
      ReactNoop.render(
        React.createElement(Component, {text = "uno", tooltipText = "one"})
      )
    end)

    -- Since `instance` is a root component, we can set its props. This also
    -- makes Tooltip rerender the tooltip component, which shouldn't throw.
    ReactNoop.act(function()
    ReactNoop.render(
      React.createElement(Component, {text="dos", tooltipText="two"})
    )
    end)
  end)

  it('should allow state updates in componentDidMount', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local getComponentState
    --[[*
     * calls setState in an componentDidMount.
     ]]
    local SetStateInComponentDidMount = React.Component:extend("SetStateInComponentDidMount")
    function SetStateInComponentDidMount:init()
      self.state = {
        stateField = self.props.valueToUseInitially,
      }
      getComponentState = function()
        return self.state
      end
    end

    function SetStateInComponentDidMount:componentDidMount()
      self:setState({stateField = self.props.valueToUseAfterMount})
    end

    function SetStateInComponentDidMount:render()
      return React.createElement("div")
    end

    local element =
      React.createElement(SetStateInComponentDidMount, {
        valueToUseInitially = "hello",
        valueToUseAfterMount = "goodbye",
      })
    ReactNoop.act(function()
      ReactNoop.render(element)
    end)
    expect(getComponentState().stateField).to.equal("goodbye")
  end)

  it('should call nested legacy lifecycle methods in the right order', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local log
    local logger = function(msg)
      return function()
        -- return true for shouldComponentUpdate
        table.insert(log, msg)
        return true
      end
    end

    local Outer = React.Component:extend("Outer")
    -- pre-declare
    local Inner = React.Component:extend("Inner")
    Outer.UNSAFE_componentWillMount = logger("outer componentWillMount")
    Outer.componentDidMount = logger("outer componentDidMount")
    Outer.UNSAFE_componentWillReceiveProps = logger(
      "outer componentWillReceiveProps"
    )
    Outer.shouldComponentUpdate = logger("outer shouldComponentUpdate")
    Outer.UNSAFE_componentWillUpdate = logger("outer componentWillUpdate")
    Outer.componentDidUpdate = logger("outer componentDidUpdate")
    Outer.componentWillUnmount = logger("outer componentWillUnmount")
    function Outer:render()
      return React.createElement("Frame", {},
        React.createElement(Inner, {
          x = self.props.x
        })
      )
    end

    Inner.UNSAFE_componentWillMount = logger("inner componentWillMount")
    Inner.componentDidMount = logger("inner componentDidMount")
    Inner.UNSAFE_componentWillReceiveProps = logger(
        "inner componentWillReceiveProps"
      )
    Inner.shouldComponentUpdate = logger("inner shouldComponentUpdate")
    Inner.UNSAFE_componentWillUpdate = logger("inner componentWillUpdate")
    Inner.componentDidUpdate = logger("inner componentDidUpdate")
    Inner.componentWillUnmount = logger("inner componentWillUnmount")
    function Inner:render()
      return React.createElement("TextLabel", { Text = self.props.x })
    end

    log = {}
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Outer, {x = 1}))
    end)
    expect(log).toEqual({
      "outer componentWillMount",
      "inner componentWillMount",
      "inner componentDidMount",
      "outer componentDidMount",
    })

    -- Dedup warnings
    log = {}
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Outer, {x = 2}))
    end)
    expect(log).toEqual({
      "outer componentWillReceiveProps",
      "outer shouldComponentUpdate",
      "outer componentWillUpdate",
      "inner componentWillReceiveProps",
      "inner shouldComponentUpdate",
      "inner componentWillUpdate",
      "inner componentDidUpdate",
      "outer componentDidUpdate",
    })

    log = {}
    ReactNoop.act(function()
      ReactNoop.render(nil)
    end)
    expect(log).toEqual({
      "outer componentWillUnmount",
      "inner componentWillUnmount",
    })
  end)

  it('should call nested new lifecycle methods in the right order', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local log
    local logger = function(msg)
      return function()
        -- return true for shouldComponentUpdate
        table.insert(log, msg)
        return true
      end
    end
    local Outer = React.Component:extend("Outer")
    -- pre-declare
    local Inner = React.Component:extend("Inner")
    function Outer:init()
      self.state = {}
    end
    function Outer.getDerivedStateFromProps(props, prevState)
      table.insert(log, "outer getDerivedStateFromProps")
      return nil
    end
    Outer.componentDidMount = logger("outer componentDidMount")
    Outer.shouldComponentUpdate = logger("outer shouldComponentUpdate")
    Outer.getSnapshotBeforeUpdate = logger("outer getSnapshotBeforeUpdate")
    Outer.componentDidUpdate = logger("outer componentDidUpdate")
    Outer.componentWillUnmount = logger("outer componentWillUnmount")
    function Outer:render()
      return React.createElement("Frame", {},
        React.createElement(Inner, {x = self.props.x})
      )
    end

    function Inner:init()
      self.state = {}
    end
    function Inner.getDerivedStateFromProps(props, prevState)
      table.insert(log, "inner getDerivedStateFromProps")
      return nil
    end
    Inner.componentDidMount = logger("inner componentDidMount")
    Inner.shouldComponentUpdate = logger("inner shouldComponentUpdate")
    Inner.getSnapshotBeforeUpdate = logger("inner getSnapshotBeforeUpdate")
    Inner.componentDidUpdate = logger("inner componentDidUpdate")
    Inner.componentWillUnmount = logger("inner componentWillUnmount")
    function Inner:render()
      return React.createElement("TextLabel", {Text = self.props.x})
    end

    log = {}
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Outer, {x = 1}))
    end)
    expect(log).toEqual({
      "outer getDerivedStateFromProps",
      "inner getDerivedStateFromProps",
      "inner componentDidMount",
      "outer componentDidMount",
    })

    -- Dedup warnings
    log = {}
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Outer, {x = 2}))
    end)
    expect(log).toEqual({
      "outer getDerivedStateFromProps",
      "outer shouldComponentUpdate",
      "inner getDerivedStateFromProps",
      "inner shouldComponentUpdate",
      "inner getSnapshotBeforeUpdate",
      "outer getSnapshotBeforeUpdate",
      "inner componentDidUpdate",
      "outer componentDidUpdate",
    })

    log = {}
    ReactNoop.act(function()
      ReactNoop.render(nil)
    end)
    expect(log).toEqual({
      "outer componentWillUnmount",
      "inner componentWillUnmount",
    })
  end)

  it('should not invoke deprecated lifecycles (cWM/cWRP/cWU) if new static gDSFP is present', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local Component = React.Component:extend("Component")
    function Component:init()
      self.state = {}
    end
    function Component.getDerivedStateFromProps()
      return nil
    end
    function Component:componentWillMount()
      error(Error('unexpected'))
    end
    function Component:componentWillReceiveProps()
      -- ROBLOX deviation: assert self is non nil
      expect(self).never.toEqual(nil)

      error(Error('unexpected'))
    end
    function Component:componentWillUpdate()
      error(Error('unexpected'))
    end
    function Component:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(Component))
        end)
      end).toErrorDev(
        'Unsafe legacy lifecycles will not be called for components using new component APIs.'
      )
    end).toWarnDev(
      -- We should consider removing this altogether; the old behavior referred
      -- to here is unique to React. None of Roact's old behavior is reflected
      -- by these messages and is likely to confuse existing users
      {
        'componentWillMount has been renamed',
        'componentWillReceiveProps has been renamed',
        'componentWillUpdate has been renamed',
      },
      {withoutStack = true}
    )
  end)

  -- ROBLOX FIXME: outputs none of the toWarnDev() expected messages in DEV mode
  it('should not invoke deprecated lifecycles (cWM/cWRP/cWU) if new getSnapshotBeforeUpdate is present', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local Component = React.Component:extend("Component")
    function Component:init()
      self.state = {}
    end
    function Component:getSnapshotBeforeUpdate()
        return nil
    end
    function Component:componentWillMount()
      error(Error('unexpected'))
    end
    function Component:componentWillReceiveProps()
      error(Error('unexpected'))
    end
    function Component:componentWillUpdate()
      -- ROBLOX deviation: assert self is non nil
      expect(self).never.toEqual(nil)
      error(Error('unexpected'))
    end
    function Component:componentDidUpdate()
      -- ROBLOX deviation: assert self is non nil
      expect(self).never.toEqual(nil)
    end
    function Component:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(Component, {value=1}))
        end)
      end).toErrorDev(
        'Unsafe legacy lifecycles will not be called for components using new component APIs.'
      )
    end).toWarnDev(
      {
        'componentWillMount has been renamed',
        'componentWillReceiveProps has been renamed',
        'componentWillUpdate has been renamed'
      },
      {withoutStack = true}
    )
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component, {value=2}))
    end)
  end)

  it('should not invoke new unsafe lifecycles (cWM/cWRP/cWU) if static gDSFP is present', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local Component = React.Component:extend("Component")
    function Component:init()
      self.state = {}
    end
    function Component.getDerivedStateFromProps()
      return nil
    end
    function Component:UNSAFE_componentWillMount()
      error(Error('unexpected'))
    end
    function Component:UNSAFE_componentWillReceiveProps()
      error(Error('unexpected'))
    end
    function Component:UNSAFE_componentWillUpdate()
      error(Error('unexpected'))
    end
    function Component:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(Component, {value = 1}))
      end)
    end).toErrorDev({
      "Unsafe legacy lifecycles will not be called for components using new component APIs.",
      -- deviation: ReactNoop runs with a StrictMode root and logs more warnings
      "Using UNSAFE_componentWillMount in strict mode is not recommended",
      "Using UNSAFE_componentWillReceiveProps in strict mode is not recommended",
      "Using UNSAFE_componentWillUpdate in strict mode is not recommended",
    }, {withoutStack = 3})
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(Component, {value = 2}))
    end)
  end)

  it('should warn about deprecated lifecycles (cWM/cWRP/cWU) if new static gDSFP is present', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local AllLegacyLifecycles = React.Component:extend("AllLegacyLifecycles")
    function AllLegacyLifecycles:init()
      self.state = {}
    end
    function AllLegacyLifecycles.getDerivedStateFromProps()
      return nil
    end
    function AllLegacyLifecycles:componentWillMount() end
    function AllLegacyLifecycles:UNSAFE_componentWillReceiveProps() end
    function AllLegacyLifecycles:componentWillUpdate() end
    function AllLegacyLifecycles:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(AllLegacyLifecycles))
        end)
      end).toErrorDev(
        {
          "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
            "AllLegacyLifecycles uses getDerivedStateFromProps() but also contains the following legacy lifecycles:\n" ..
            "  componentWillMount\n" ..
            "  UNSAFE_componentWillReceiveProps\n" ..
            "  componentWillUpdate\n\n" ..
            "The above lifecycles should be removed. Learn more about this warning here:\n" ..
            "https://reactjs.org/link/unsafe-component-lifecycles",
          "UNSAFE_componentWillReceiveProps in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end).toWarnDev(
      {
        "componentWillMount has been renamed",
        "componentWillUpdate has been renamed",
      },
      {withoutStack = true}
    )

    local WillMount = React.Component:extend("WillMount")
    function WillMount:init()
      self.state = {}
    end
    function WillMount.getDerivedStateFromProps()
      return nil
    end
    function WillMount:UNSAFE_componentWillMount() end
    function WillMount:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(WillMount))
      end).toErrorDev(
        {
          "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
            "WillMount uses getDerivedStateFromProps() but also contains the following legacy lifecycles:\n" ..
            "  UNSAFE_componentWillMount\n\n" ..
            "The above lifecycles should be removed. Learn more about this warning here:\n" ..
            "https://reactjs.org/link/unsafe-component-lifecycles",
          "UNSAFE_componentWillMount in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end)

    local WillMountAndUpdate = React.Component:extend("WillMountAndUpdate")
    function WillMountAndUpdate:init()
      self.state = {}
    end
    function WillMountAndUpdate.getDerivedStateFromProps()
      return nil
    end
    function WillMountAndUpdate:componentWillMount() end
    function WillMountAndUpdate:UNSAFE_componentWillUpdate() end
    function WillMountAndUpdate:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(WillMountAndUpdate))
        end)
      end).toErrorDev(
        {
          "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
            "WillMountAndUpdate uses getDerivedStateFromProps() but also contains the following legacy lifecycles:\n" ..
            "  componentWillMount\n" ..
            "  UNSAFE_componentWillUpdate\n\n" ..
            "The above lifecycles should be removed. Learn more about this warning here:\n" ..
            "https://reactjs.org/link/unsafe-component-lifecycles",
          "UNSAFE_componentWillUpdate in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end).toWarnDev({"componentWillMount has been renamed"}, {
      withoutStack = true,
    })

    local WillReceiveProps = React.Component:extend("WillReceiveProps")
    function WillReceiveProps:init()
      self.state = {}
    end
    function WillReceiveProps.getDerivedStateFromProps()
      return nil
    end
    function WillReceiveProps:componentWillReceiveProps() end
    function WillReceiveProps:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(WillReceiveProps))
        end)
      end).toErrorDev(
        "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
          "WillReceiveProps uses getDerivedStateFromProps() but also contains the following legacy lifecycles:\n" ..
          "  componentWillReceiveProps\n\n" ..
          "The above lifecycles should be removed. Learn more about this warning here:\n" ..
          "https://reactjs.org/link/unsafe-component-lifecycles"
      )
    end).toWarnDev({"componentWillReceiveProps has been renamed"}, {
      withoutStack = true,
    })
  end)

  it('should warn about deprecated lifecycles (cWM/cWRP/cWU) if new getSnapshotBeforeUpdate is present', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local AllLegacyLifecycles = React.Component:extend("AllLegacyLifecycles")
    function AllLegacyLifecycles:init()
      self.state = {}
    end
    function AllLegacyLifecycles:getSnapshotBeforeUpdate() end
    function AllLegacyLifecycles:componentWillMount() end
    function AllLegacyLifecycles:UNSAFE_componentWillReceiveProps() end
    function AllLegacyLifecycles:componentWillUpdate() end
    function AllLegacyLifecycles:componentDidUpdate() end
    function AllLegacyLifecycles:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(AllLegacyLifecycles))
        end)
      end).toErrorDev(
        {
          "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
            "AllLegacyLifecycles uses getSnapshotBeforeUpdate() but also contains the following legacy lifecycles:\n" ..
            "  componentWillMount\n" ..
            "  UNSAFE_componentWillReceiveProps\n" ..
            "  componentWillUpdate\n\n" ..
            "The above lifecycles should be removed. Learn more about this warning here:\n" ..
            "https://reactjs.org/link/unsafe-component-lifecycles",
          "UNSAFE_componentWillReceiveProps in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end).toWarnDev(
      {
        "componentWillMount has been renamed",
        "componentWillUpdate has been renamed"
      },
      {withoutStack = true}
    )

    local WillMount = React.Component:extend("WillMount")
    function WillMount:init()
      self.state = {}
    end
    function WillMount:getSnapshotBeforeUpdate() end
    function WillMount:UNSAFE_componentWillMount() end
    function WillMount:componentDidUpdate() end
    function WillMount:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(WillMount))
      end)
    end).toErrorDev(
      {
        "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
          "WillMount uses getSnapshotBeforeUpdate() but also contains the following legacy lifecycles:\n" ..
          "  UNSAFE_componentWillMount\n\n" ..
          "The above lifecycles should be removed. Learn more about this warning here:\n" ..
          "https://reactjs.org/link/unsafe-component-lifecycles",
        "UNSAFE_componentWillMount in strict mode is not recommended",
      },
      {withoutStack = 1}
    )

    local WillMountAndUpdate = React.Component:extend("WillMountAndUpdate")
    function WillMountAndUpdate:init()
      self.state = {}
    end
    function WillMountAndUpdate:getSnapshotBeforeUpdate() end
    function WillMountAndUpdate:componentWillMount() end
    function WillMountAndUpdate:UNSAFE_componentWillUpdate() end
    function WillMountAndUpdate:componentDidUpdate() end
    function WillMountAndUpdate:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(WillMountAndUpdate))
        end)
      end).toErrorDev(
        {
          "Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n" ..
            "WillMountAndUpdate uses getSnapshotBeforeUpdate() but also contains the following legacy lifecycles:\n" ..
            "  componentWillMount\n" ..
            "  UNSAFE_componentWillUpdate\n\n" ..
            "The above lifecycles should be removed. Learn more about this warning here:\n" ..
            "https://reactjs.org/link/unsafe-component-lifecycles",
          "UNSAFE_componentWillUpdate in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end).toWarnDev({"componentWillMount has been renamed"}, {
      withoutStack = true
    })

    local WillReceiveProps = React.Component:extend("WillReceiveProps")
    function WillReceiveProps:init()
      self.state = {}
    end
    function WillReceiveProps:getSnapshotBeforeUpdate() end
    function WillReceiveProps:componentWillReceiveProps() end
    function WillReceiveProps:componentDidUpdate() end
    function WillReceiveProps:render()
      return nil
    end

    expect(function()
      expect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(WillReceiveProps))
        end)
      end).toErrorDev(
        'Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n' ..
          'WillReceiveProps uses getSnapshotBeforeUpdate() but also contains the following legacy lifecycles:\n' ..
          '  componentWillReceiveProps\n\n' ..
          'The above lifecycles should be removed. Learn more about this warning here:\n' ..
          'https://reactjs.org/link/unsafe-component-lifecycles'
      )
    end).toWarnDev({'componentWillReceiveProps has been renamed'}, {
      withoutStack = true,
    })
  end)

--   if !require('shared/ReactFeatureFlags').disableModulePatternComponents)
--     it('calls effects on module-pattern component', function()
--       local log = []

--       function Parent()
--         return {
--           render()
--             expect(typeof this.props).toBe('table’')
--             log.push('render')
--             return <Child />
--           },
--           UNSAFE_componentWillMount()
--             log.push('will mount')
--           },
--           componentDidMount()
--             log.push('did mount')
--           },
--           componentDidUpdate()
--             log.push('did update')
--           },
--           getChildContext()
--             return {x: 2}
--           },
--      end
--       end
--       Parent.childContextTypes = {
--         x: PropTypes.number,
--       end
--       function Child(props, context)
--         expect(context.x).toBe(2)
--         return <div />
--       end
--       Child.contextTypes = {
--         x: PropTypes.number,
--       end

--       local div = document.createElement('div')
--       expect(() =>
--         ReactDOM.render(<Parent ref={c => c and log.push('ref')} />, div),
--       ).toErrorDev(
--         'Warning: The <Parent /> component appears to be a function component that returns a class instance. ' +
--           'Change Parent to a class that extends React.Component instead. ' +
--           "If you can't use a class try assigning the prototype on the function as a workaround. " +
--           '`Parent.prototype = React.Component.prototype`. ' +
--           "Don't use an arrow function since it cannot be called with `new` by React.",
--       )
--       ReactDOM.render(<Parent ref={c => c and log.push('ref')} />, div)

--       expect(log).toEqual([
--         'will mount',
--         'render',
--         'did mount',
--         'ref',

--         'render',
--         'did update',
--         'ref',
--       ])
--     })
--   end

--   -- We have no distinction between nil and undefined, so this might not be
--   -- useful unless we want to try to capture missing return
--   xit('should warn if getDerivedStateFromProps returns undefined', function()
--     class MyComponent extends React.Component {
--       state = {}
--       static getDerivedStateFromProps() {}
--       render()
--         return nil
--       end
--  end

--     local div = document.createElement('div')
--     expect(() => ReactDOM.render(<MyComponent />, div)).toErrorDev(
--       'MyComponent.getDerivedStateFromProps(): A valid state object (or nil) must ' +
--         'be returned. You have returned undefined.',
--     )

--     -- De-duped
--     ReactDOM.render(<MyComponent />, div)
--   })

  it("should warn if state is not initialized before getDerivedStateFromProps", function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local MyComponent = React.Component:extend("MyComponent")
    function MyComponent.getDerivedStateFromProps()
      return nil
    end
    function MyComponent:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(MyComponent))
      end)
    end).toErrorDev(
      -- ROBLOX FIXME: This error message doesn't quite apply as written
      "`MyComponent` uses `getDerivedStateFromProps` but its initial state is " ..
        "nil. This is not recommended. Instead, define the initial state by " ..
        "assigning an object to `self.state` in the `init` method of `MyComponent`. " ..
        "This ensures that `getDerivedStateFromProps` arguments have a consistent shape."
    )

    -- De-duped
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(MyComponent))
    end)
  end)

  it("should invoke both deprecated and new lifecycles if both are present", function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect
    local log = {}

    local MyComponent = React.Component:extend("MyComponent")
    function MyComponent:componentWillMount()
      table.insert(log, "componentWillMount")
    end
    function MyComponent:componentWillReceiveProps()
      table.insert(log, "componentWillReceiveProps")
    end
    function MyComponent:componentWillUpdate()
      table.insert(log, "componentWillUpdate")
    end
    function MyComponent:UNSAFE_componentWillMount()
      table.insert(log, "UNSAFE_componentWillMount")
    end
    function MyComponent:UNSAFE_componentWillReceiveProps()
      table.insert(log, "UNSAFE_componentWillReceiveProps")
    end
    function MyComponent:UNSAFE_componentWillUpdate()
      table.insert(log, "UNSAFE_componentWillUpdate")
    end
    function MyComponent:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(MyComponent, {foo = "bar"}))
      end)
    end).toWarnDev(
      {
        "componentWillMount has been renamed",
        "componentWillReceiveProps has been renamed",
        "componentWillUpdate has been renamed",
      },
      {withoutStack = true}
    )
    expect(log).toEqual({"componentWillMount", "UNSAFE_componentWillMount"})

    log = {}

    ReactNoop.act(function()
      ReactNoop.render(React.createElement(MyComponent, {foo = "baz"}))
    end)
    expect(log).toEqual({
      "componentWillReceiveProps",
      "UNSAFE_componentWillReceiveProps",
      "componentWillUpdate",
      "UNSAFE_componentWillUpdate",
    })
  end)

--   -- This would be hard to get working without more DOM logic simulation
--   xit('should not override state with stale values if prevState is spread within getDerivedStateFromProps', function()
--     local divRef = React.createRef()
--     local childInstance

--     class Child extends React.Component {
--       state = {local: 0}
--       static getDerivedStateFromProps(nextProps, prevState)
--         return {...prevState, remote: nextProps.remote}
--       end
--       updateState = function()
--         this.setState(state => ({local: state.local + 1}))
--         this.props.onChange(this.state.remote + 1)
--       end
--       render()
--         childInstance = this
--         return (
--           <div
--             onClick={this.updateState}
--             ref={
--               divRef
--             }>{`remote:${this.state.remote}, local:${this.state.local}`}</div>
--         )
--       end
--  end

--     class Parent extends React.Component {
--       state = {value: 0}
--       handleChange = value => {
--         this.setState({value})
--       end
--       render()
--         return <Child remote={this.state.value} onChange={this.handleChange} />
--       end
--  end

--     ReactNoop.act(function()
--       ReactNoop.render(<Parent />)
--     })

--     expect(divRef.current.textContent).toBe('remote:0, local:0')

--     -- Trigger setState() calls
--     childInstance.updateState()
--     expect(divRef.current.textContent).toBe('remote:1, local:1')

--     -- Trigger batched setState() calls
--     divRef.current.click()
--     expect(divRef.current.textContent).toBe('remote:2, local:2')
--   })

  it('should pass the return value from getSnapshotBeforeUpdate to componentDidUpdate', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect
    local log = {}

    local MyComponent = React.Component:extend("MyComponent")
    function MyComponent:init()
      self.state = {
        value = 0,
      }
    end
    function MyComponent.getDerivedStateFromProps(nextProps, prevState)
      return {
        value = prevState.value + 1,
      }
    end
    function MyComponent:getSnapshotBeforeUpdate(prevProps, prevState)
      table.insert(log, string.format(
        "getSnapshotBeforeUpdate() prevProps:%s prevState:%s",
          prevProps.value,
          prevState.value
        )
      )
      return "abc"
    end
    function MyComponent:componentDidUpdate(prevProps, prevState, snapshot)
      table.insert(log, string.format(
        "componentDidUpdate() prevProps:%s prevState:%s snapshot:%s",
          prevProps.value,
          prevState.value,
          snapshot
        )
      )
    end
    function MyComponent:render()
      table.insert(log, "render")
      return nil
    end

    ReactNoop.act(function()
      ReactNoop.render(React.createElement("Frame", {},
        React.createElement(MyComponent, {
          value = "foo",
        })
      ))
    end)
    expect(log).toEqual({"render"})
    log = {}

    ReactNoop.act(function()
      ReactNoop.render(React.createElement("Frame", {},
        React.createElement(MyComponent, {
          value = "bar",
        })
      ))
    end)
    expect(log).toEqual({
      "render",
      "getSnapshotBeforeUpdate() prevProps:foo prevState:1",
      "componentDidUpdate() prevProps:foo prevState:1 snapshot:abc",
    })
    log = {}

    ReactNoop.act(function()
      ReactNoop.render(React.createElement("Frame", {},
        React.createElement(MyComponent, {
          value = "baz",
        })
      ))
    end)
    expect(log).toEqual({
      "render",
      "getSnapshotBeforeUpdate() prevProps:bar prevState:2",
      "componentDidUpdate() prevProps:bar prevState:2 snapshot:abc",
    })
    log = {}

    ReactNoop.act(function()
      ReactNoop.render(React.createElement("Frame"))
    end)
    expect(log).toEqual({})
  end)

  it('should pass previous state to shouldComponentUpdate even with getDerivedStateFromProps', function()
    local divRef = React.createRef()
    local capturedValue
    local SimpleComponent = React.Component:extend("SimpleComponent")
    function SimpleComponent:init(props)
      self.state = {
        value = props.value,
      }
    end

    function SimpleComponent.getDerivedStateFromProps(nextProps, prevState)
      if nextProps.value == prevState.value then
        return nil
      end
      return {value = nextProps.value}
    end

    function SimpleComponent:shouldComponentUpdate(nextProps, nextState)
      return nextState.value ~= self.state.value
    end

    function SimpleComponent:render()
      capturedValue = self.state.value
      return React.createElement("Frame", { ref = divRef },
        React.createElement("TextLabel", { Text = self.state.value })
      )
    end

    ReactNoop.act(function()
      ReactNoop.render(React.createElement(SimpleComponent, {value = "initial"}))
    end)
    expect(capturedValue).to.equal("initial")
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(SimpleComponent, {value = "updated"}))
    end)
    expect(capturedValue).to.equal("updated")
  end)

--   -- Don't think we can convert this, since it relies on refs and DOM objects
--   xit('should call getSnapshotBeforeUpdate before mutations are committed', function()
--     local log = []

--     class MyComponent extends React.Component {
--       divRef = React.createRef()
--       getSnapshotBeforeUpdate(prevProps, prevState)
--         log.push('getSnapshotBeforeUpdate')
--         expect(this.divRef.current.textContent).toBe(
--           `value:${prevProps.value}`,
--         )
--         return 'foobar'
--       end
--       componentDidUpdate(prevProps, prevState, snapshot)
--         log.push('componentDidUpdate')
--         expect(this.divRef.current.textContent).toBe(
--           `value:${this.props.value}`,
--         )
--         expect(snapshot).toBe('foobar')
--       end
--       render()
--         log.push('render')
--         return <div ref={this.divRef}>{`value:${this.props.value}`}</div>
--       end
--  end

--     local div = document.createElement('div')
--     ReactDOM.render(<MyComponent value="foo" />, div)
--     expect(log).toEqual(['render'])
--     log.length = 0

--     ReactDOM.render(<MyComponent value="bar" />, div)
--     expect(log).toEqual([
--       'render',
--       'getSnapshotBeforeUpdate',
--       'componentDidUpdate',
--     ])
--     log.length = 0
--   })

--   -- We have no distinction between nil and undefined, so this might not be
--   -- useful unless we want to try to capture missing return
--   xit('should warn if getSnapshotBeforeUpdate returns undefined', function()
--     class MyComponent extends React.Component {
--       getSnapshotBeforeUpdate() {}
--       componentDidUpdate() {}
--       render()
--         return nil
--       end
--  end

--     local div = document.createElement('div')
--     ReactDOM.render(<MyComponent value="foo" />, div)
--     expect(() => ReactDOM.render(<MyComponent value="bar" />, div)).toErrorDev(
--       'MyComponent.getSnapshotBeforeUpdate(): A snapshot value (or nil) must ' +
--         'be returned. You have returned undefined.',
--     )

--     -- De-duped
--     ReactDOM.render(<MyComponent value="baz" />, div)
--   })

  it("should warn if getSnapshotBeforeUpdate is defined with no componentDidUpdate", function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local MyComponent = React.Component:extend("MyComponent")
    function MyComponent:getSnapshotBeforeUpdate()
      return nil
    end
    function MyComponent:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(MyComponent))
      end).toErrorDev(
        "MyComponent: getSnapshotBeforeUpdate() should be used with componentDidUpdate(). " ..
          "This component defines getSnapshotBeforeUpdate() only."
      )
    end)

    -- De-duped
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(MyComponent))
    end)
  end)

  it('warns about deprecated unsafe lifecycles', function()
    -- ROBLOX FIXME: expect type
    local expect: any = expect

    local MyComponent = React.Component:extend("MyComponent")
    function MyComponent:componentWillMount() end
    function MyComponent:componentWillReceiveProps() end
    function MyComponent:componentWillUpdate() end
    function MyComponent:render()
      return nil
    end

    expect(function()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(MyComponent, {x = 1}))
      end)
    end).toWarnDev(
      {
        --[[ eslint-disable max-len ]]
        [[Warning: componentWillMount has been renamed, and is not recommended for use. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move code with side effects to componentDidMount, and set initial state in the constructor.
* Rename componentWillMount to UNSAFE_componentWillMount to suppress this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.

Please update the following components: MyComponent]],
        [[Warning: componentWillReceiveProps has been renamed, and is not recommended for use. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move data fetching code or side effects to componentDidUpdate.
* If you're updating state whenever props change, refactor your code to use memoization techniques or move it to static getDerivedStateFromProps. Learn more at: https://reactjs.org/link/derived-state
* Rename componentWillReceiveProps to UNSAFE_componentWillReceiveProps to suppress this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.

Please update the following components: MyComponent]],
        [[Warning: componentWillUpdate has been renamed, and is not recommended for use. See https://reactjs.org/link/unsafe-component-lifecycles for details.

* Move data fetching code or side effects to componentDidUpdate.
* Rename componentWillUpdate to UNSAFE_componentWillUpdate to suppress this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.

Please update the following components: MyComponent]],
        --[[ eslint-enable max-len ]]
      },
      {withoutStack = true}
    )

    -- Dedupe check (update and instantiate new)
    ReactNoop.act(function()
      ReactNoop.render(React.createElement(MyComponent, {x = 2}))
      ReactNoop.render(React.createElement(MyComponent, {key = "new", x = 1}))
    end)
  end)

--   describe('react-lifecycles-compat', function()
--     local {polyfill} = require('react-lifecycles-compat')

--     xit('should not warn for components with polyfilled getDerivedStateFromProps', function()
--       class PolyfilledComponent extends React.Component {
--         state = {}
--         static getDerivedStateFromProps()
--           return nil
--      end
--         render()
--           return nil
--      end
--       end

--       polyfill(PolyfilledComponent)

--       local container = document.createElement('div')
--       ReactDOM.render(
--         <React.StrictMode>
--           <PolyfilledComponent />
--         </React.StrictMode>,
--         container,
--       )
--     })

--     xit('should not warn for components with polyfilled getSnapshotBeforeUpdate', function()
--       class PolyfilledComponent extends React.Component {
--         getSnapshotBeforeUpdate()
--           return nil
--      end
--         componentDidUpdate() {}
--         render()
--           return nil
--      end
--       end

--       polyfill(PolyfilledComponent)

--       local container = document.createElement('div')
--       ReactDOM.render(
--         <React.StrictMode>
--           <PolyfilledComponent />
--         </React.StrictMode>,
--         container,
--       )
--     })
--   })
end