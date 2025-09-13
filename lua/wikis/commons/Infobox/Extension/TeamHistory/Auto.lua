---
-- @Liquipedia
-- page=Module:Infobox/Extension/TeamHistory/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Storage = Lua.import('Module:Infobox/Extension/TeamHistory/Store')
local TransferModel = Lua.import('Module:Transfer/Model')

local TeamHistoryDisplay = Lua.import('Module:Widget/Infobox/TeamHistory/Display')

local SPECIAL_ROLES = Lua.import('Module:Infobox/Extension/TeamHistory/SpecialRoles', {loadData = true})

local TeamHistoryAuto = {}

---@param frame Frame|{player: string?, isFromWikiCode: boolean?}
---@return Widget?
function TeamHistoryAuto.run(frame)
	local args = Arguments.getArgs(frame)
	local player = Page.applyUnderScoresIfEnforced(args.player or String.upperCaseFirst(mw.title.getCurrentTitle().subpageText))

	local transferList = TransferModel.getTeamHistoryForPerson{player = player, specialRoles = SPECIAL_ROLES}

	if Logic.isEmpty(transferList) then return end

	Storage.store{
		transferList = transferList,
		player = player,
		isFromWikiCode = Logic.readBool(args.isFromWikiCode),
	}

	return TeamHistoryDisplay{
		transferList = transferList,
		player = player,
	}
end

return TeamHistoryAuto
