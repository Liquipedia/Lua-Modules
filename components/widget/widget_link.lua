---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Link
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class LinkWidgetParameters: WidgetParameters
---@field link string
---@field linktype 'internal'|'external'|nil

---@class LinkWidget: Widget
---@operator call(LinkWidgetParameters): LinkWidget
---@field link string
---@field linktype 'internal'|'external'
local Link = Class.new(
	Widget,
	function(self, input)
		self.link = self:assertExistsAndCopy(input.link)
		self.linktype = input.linktype or 'internal'
	end
)

---@param children string[]
---@return string?
function Link:make(children)
	if self.linktype == 'external' then
		return '[' .. self.link .. ' '.. table.concat(children) .. ']'
	end
	return '[[' .. self.link .. '|'.. table.concat(children) .. ']]'
end

return Link
