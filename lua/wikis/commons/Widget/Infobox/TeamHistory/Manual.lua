---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local TeamHistoryManualExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Manual')
local TeamHistoryStoreExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Store')
local Widget = Lua.import('Module:Widget')

local TeamHistoryDisplay = Lua.import('Module:Widget/Infobox/TeamHistory/Display')

---@class TeamHistoryManualWidget: Widget
---@operator call(table): TeamHistoryManualWidget
---@field props string[]|table
local TeamHistory = Class.new(Widget)

---@return Widget?
function TeamHistory:render()
	if Logic.isEmpty(self.props) then return end
	local transferList = TeamHistoryManualExtension.parse(self.props)

	TeamHistoryStoreExtension.store{
		transferList = transferList,
		isFromWikiCode = true,
	}

	return TeamHistoryDisplay{transferList = {transferList}}
end

return TeamHistory
