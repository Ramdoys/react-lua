-- upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react/src/React.js
local React = script.Parent
local Packages = React.Parent
local createMutableSource = require(React.ReactMutableSource)
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local ReactBaseClasses = require(React.ReactBaseClasses)
local ReactElementValidator = require(React.ReactElementValidator)
local ReactElement = require(React.ReactElement)
local ReactCreateRef = require(React.ReactCreateRef)
local ReactForwardRef = require(React.ReactForwardRef)
local ReactHooks = require(React.ReactHooks)
local ReactMemo = require(React.ReactMemo)
local ReactContext = require(React.ReactContext)
local ReactLazy = require(React.ReactLazy)
local ReactSymbols = require(Packages.Shared).ReactSymbols
local console = require(Packages.Shared).console

-- ROBLOX deviation: keep track of warnings
local warnedAbout = {}

local createElement = _G.__DEV__ and
	ReactElementValidator.createElementWithValidation or
	ReactElement.createElement
local cloneElement = _G.__DEV__ and
	ReactElementValidator.cloneElementWithValidation or
	ReactElement.cloneElement

return {
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ReactSharedInternals,
	Component = ReactBaseClasses.Component,
	PureComponent = ReactBaseClasses.PureComponent,
	createElement = createElement,
	cloneElement = cloneElement,
	createMutableSource = createMutableSource,
	isValidElement = ReactElement.	isValidElement,
	createRef = ReactCreateRef.createRef,
	forwardRef = ReactForwardRef.forwardRef,
	lazy = ReactLazy.lazy,
	createFragment = function(elements)
		if _G.__DEV__ and not warnedAbout["createFragment"] then
			console.warn("The legacy Roact createFragment API is deprecated, and will be removed in a future version.\n"..
			" Please use the supported createElement(React.Fragment, ...) API instead.")
			warnedAbout["createFragment"] = true
		end
		return createElement(ReactSymbols.REACT_FRAGMENT_TYPE, nil, elements)
	end,
	Fragment = ReactSymbols.REACT_FRAGMENT_TYPE,
	Profiler = ReactSymbols.REACT_PROFILER_TYPE,
	StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE,
	Suspense = ReactSymbols.REACT_SUSPENSE_TYPE,
	memo = ReactMemo.memo,
	useState = ReactHooks.useState,
	useReducer = ReactHooks.useReducer,
	useEffect = ReactHooks.useEffect,
	useImperativeHandle = ReactHooks.useImperativeHandle,
	useLayoutEffect = ReactHooks.useLayoutEffect,
	useRef = ReactHooks.useRef,
	useMemo = ReactHooks.useMemo,
	useMutableSource = ReactHooks.useMutableSource,
	useCallback = ReactHooks.useCallback,
	useContext = ReactHooks.useContext,
	createContext = ReactContext.createContext,
	unstable_LegacyHidden = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE
}
