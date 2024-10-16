---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local ErrorDisplay = require('Module:Error/Display')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

---@class Widget: BaseClass
---@operator call(table): self
---@field context Widget[]
---@field props table<string, any>
local Widget = Class.new(function(self, props)
	self.props = Table.deepMerge(Table.deepCopy(self.defaultProps), props)

	if not Array.isArray(self.props.children) then
		self.props.children = {self.props.children}
	end

	self.context = {} -- Populated by the parent
end)

Widget.defaultProps = {}

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

---@return string
function Widget:tryMake()
	local function renderComponent()
		local ret = self:render()
		if not Array.isArray(ret) then
			ret = {ret}
		end
		---@cast ret (string|Widget|Html|nil)[]

		return table.concat(Array.map(ret, function(val)
			if Class.instanceOf(val, Widget) then
				---@cast val Widget
				val.context = self:_nextContext()
				return val:tryMake()
			end
			if val ~= nil then
				return tostring(val)
			end
			return nil
		end))
	end

	return Logic.tryOrElseLog(
		renderComponent,
		FnUtil.curry(self.getDerivedStateFromError, self),
		Widget._updateErrorHeader
	)
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
