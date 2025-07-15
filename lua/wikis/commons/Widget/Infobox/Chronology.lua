---
-- @Liquipedia
-- page=Module:Widget/Infobox/Chronology
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local ChronologyDisplay = Lua.import('Module:Widget/Infobox/ChronologyDisplay')

---@class ChronologyWidget: Widget
---@operator call(table): ChronologyWidget
---@field props {links: table<string, string|number|nil>?, title: string?, showTitle: boolean?, args: table?}
local Chronology = Class.new(Widget)

---@return Widget?
function Chronology:render()
	local links = self.props.links or Table.filterByKey(self.props.args or {}, function(key)
		return type(key) == 'string' and (key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
	end)
	return ChronologyDisplay{
		links = links,
		title = self.props.title,
		showTitle = self.props.showTitle,
	}
end

return Chronology

