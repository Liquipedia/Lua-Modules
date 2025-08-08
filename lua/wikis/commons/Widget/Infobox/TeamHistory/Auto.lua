---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local TeamHistoryAutoExtension = Lua.import('Module:Infobox/Extension/TeamHistoryAuto')
local Widget = Lua.import('Module:Widget')

---@class TeamHistoryAutoWidget: Widget
---@operator call(table): TeamHistoryAutoWidget
---@field props {player: string, store: boolean}
local TeamHistory = Class.new(Widget)
TeamHistory.defaultProps = {
	player = mw.title.getCurrentTitle().subpageText:gsub('^%l', string.upper),
	store = false,
}

---@return Widget?
function TeamHistory:render()
	local teamHistory = TeamHistoryAutoExtension{player = self.props.player}
		:fetch()

	if Logic.readBool(self.props.store) then
		teamHistory:store()
	end

	return teamHistory:build()
end

return TeamHistory
