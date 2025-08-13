---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local TeamHistoryManualExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Manual')
local TeamHistoryStoreExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Store')
local Widget = Lua.import('Module:Widget')

local TeamHistoryDisplay = Lua.import('Module:Widget/Infobox/TeamHistory/Display')

---@class TeamHistoryManualWidget: Widget
---@operator call(table): TeamHistoryManualWidget
---@field props table
local TeamHistory = Class.new(Widget)
TeamHistory.defaultProps = {
	store = false,--move to config as `storeFromWikiCode`???
}

---@return Widget?
function TeamHistory:render()
	local firstElementParsed = Json.parseIfTable(self.props[1])
	local elements = firstElementParsed and {self.props} or self.props

	local transferList = Array.map(elements, TeamHistoryManualExtension.parse)

	if Logic.readBool(self.props.store) then
		TeamHistoryStoreExtension.store(transferList)
	end

	return TeamHistoryDisplay{transferList = transferList}
end

return TeamHistory
