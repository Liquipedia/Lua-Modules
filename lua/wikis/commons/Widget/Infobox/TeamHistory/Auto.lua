---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local TeamHistoryAutoExtension = Lua.import('Module:Infobox/Extension/TeamHistoryAuto')
local Widget = Lua.import('Module:Widget')

---@class TeamHistoryAutoWidget: Widget
---@operator call(table): TeamHistoryAutoWidget
---@field props {player: string, store: boolean}
local TeamHistory = Class.new(Widget)
TeamHistory.defaultProps = {
	player = String.upperCaseFirst(mw.title.getCurrentTitle().subpageText),
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
