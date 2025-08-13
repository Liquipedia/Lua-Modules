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
local TeamHistoryStoreExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Store')
local TransferModel = Lua.import('Module:Transfer/Model')
local Widget = Lua.import('Module:Widget')

local TeamHistoryDisplay = Lua.import('Module:Widget/Infobox/TeamHistory/Display')

local SPECIAL_ROLES = Lua.import('Module:Infobox/Extension/TeamHistory/SpecialRoles', {loadData = true})

---@class TeamHistoryAutoWidget: Widget
---@operator call(table): TeamHistoryAutoWidget
---@field props {player: string, store: boolean}
local TeamHistory = Class.new(Widget)
TeamHistory.defaultProps = {
	player = String.upperCaseFirst(mw.title.getCurrentTitle().subpageText),
	store = false,--move to config as `storeFromWikiCode`???
}

---@return Widget?
function TeamHistory:render()
	local transferList = TransferModel.getTeamHistoryForPerson{player = self.props.player, specialRoles = SPECIAL_ROLES}

	if Logic.readBool(self.props.store) then
		TeamHistoryStoreExtension.store(transferList, self.props.player)
	end

	return TeamHistoryDisplay{
		transferList = transferList,
		player = self.props.player,
	}
end

return TeamHistory
