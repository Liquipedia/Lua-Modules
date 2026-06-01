---
-- @Liquipedia
-- page=Module:Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local ErrorDisplay = Lua.import('Module:Error/Display')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Renderer = Lua.import('Module:Widget/Renderer')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

---@class Widget: BaseClass
---@operator call(table): self
---@field context Widget[]
---@field props table<string, any>
local Widget = Class.new(function(self, props)
	self.props = Table.deepMerge(Table.deepCopy(self.defaultProps), props)

	if not Array.isArray(self.props.children) then
		self.props.children = {self.props.children}
	end
end)

Widget.defaultProps = {}

---Asserts the existence of a value and copies it
---@param value string
---@return string
function Widget:assertExistsAndCopy(value)
	return assert(String.nilIfEmpty(value), 'Tried to set a nil value to a mandatory property')
end

---@return Renderable|Renderable[]?
function Widget:render()
	error('A Widget must override the render() function!')
end

---@return string
function Widget:tryMake()
	local function renderComponent()
		return Renderer.render(self:render())
	end

	return Logic.tryOrElseLog(
		renderComponent,
		FnUtil.curry(self.getDerivedStateFromError, self),
		Widget._updateErrorHeader
	)
end

---@param error Error
---@return string
function Widget:getDerivedStateFromError(error)
	return tostring(ErrorDisplay.InlineError(error))
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
