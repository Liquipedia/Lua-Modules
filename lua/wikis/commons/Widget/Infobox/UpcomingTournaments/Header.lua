---
-- @Liquipedia
-- page=Module:Widget/Infobox/UpcomingTournaments/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class UpcomingTournamentsHeader: Widget
---@operator call(table): UpcomingTournamentsHeader
local UpcomingTournamentsHeader = Class.new(Widget)

---@return Widget
function UpcomingTournamentsHeader:render()
	return Div{
		children = Div{
			classes = {'infobox-header', 'wiki-backgroundcolor-light'},
			children = 'Upcoming Tournaments'
		}
	}
end

return UpcomingTournamentsHeader
