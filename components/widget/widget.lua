---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local ErrorDisplay = require('Module:Error/Display')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

---@class Widget: BaseClass
---@operator call(table): self
---@field children (Widget|Html|string|number)[] @deprecated
---@field context Widget[]
---@field props table<string, any>
---@field makeChildren? fun(self:Widget, injector: WidgetInjector?): Widget[]?
local Widget = Class.new(function(self, props)
	self.props = Table.copy(props) or {}
	self.props.children = self.props.children or {}
	self.context = {} -- Populated by the parent
	---@deprecated Widget v1 backwards compability
	self.children = self.children or self.props.children
end)

---Asserts the existence of a value and copies it
---@param value string
---@return string
function Widget:assertExistsAndCopy(value)
	return assert(String.nilIfEmpty(value), 'Tried to set a nil value to a mandatory property')
end

---@return (string|Widget|Html|nil)[]|(string|Widget|Html|nil)
function Widget:render()
	error('A Widget must override the render() function!')
end

---@deprecated
---@param children string[]
---@return string|nil
function Widget:make(children)
	error('A Widget must override the make() function!')
end

---@param injector WidgetInjector?
---@return string
function Widget:tryMake(injector)
	local renderComponent
	if self.render == Widget.render then
		-- Widget v1 backwards compability
		renderComponent = function()
			local processedChildren = self:tryChildren(injector)
			if self.render == Widget.render then
				local ret = self:make(processedChildren)
				return ret ~= nil and ret or ''
			end
		end
	else
		renderComponent = function()
			local ret = self:render()
			if not Array.isArray(ret) then
				ret = {ret}
			end

			---@cast ret (string|Widget|Html|nil)[]
			return Array.reduce(ret, function(acc, val)
				if Class.instanceOf(val, Widget) then
					---@cast val Widget
					val.context = self:_nextContext()
					return acc .. val:tryMake(injector)
				end
				if val ~= nil then
					return acc .. tostring(val)
				end
				return acc
			end, '')
		end
	end

	return Logic.tryOrElseLog(
		renderComponent,
		FnUtil.curry(self.getDerivedStateFromError, self),
		Widget._updateErrorHeader
	)
end

---@deprecated
---@param injector WidgetInjector?
---@return string[]
function Widget:tryChildren(injector)
	local children = self.children
	if self.makeChildren then
		children = self:makeChildren(injector) or {}
	end
	return Array.map(children, function(child)
		if Class.instanceOf(child, Widget) then
			---@cast child Widget
			return Logic.tryOrElseLog(
				function() return child:tryMake(injector) end,
				FnUtil.curry(self.getDerivedStateFromError, self),
				Widget._updateErrorHeader
			)
		end
		---@cast child -Widget
		return tostring(child)
	end)
end

---@param widget WidgetContext
---@param default any
---@return any
function Widget:useContext(widget, default)
	local context = Array.find(self.context, function(node)
		return Class.instanceOf(node, widget)
	end)
	if context then
		---@cast context WidgetContext
		return context:getValue(default)
	end
	return default
end

---@param error Error
---@return string
function Widget:getDerivedStateFromError(error)
	return tostring(ErrorDisplay.InlineError(error))
end

---@return Widget[]
function Widget:_nextContext()
	return {self, unpack(self.context)}
end

---@param error Error
---@return Error
function Widget._updateErrorHeader(error)
	error.header = 'Error occured in widget building:'
	return error
end

---@return string
function Widget:__tostring()
	return self:tryMake()
end

--- Here to allow for Widget to be used as a node in the third part html library (mw.html).
---@param ret string[]
function Widget:_build(ret)
	table.insert(ret, self:__tostring())
end

return Widget
