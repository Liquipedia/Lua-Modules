---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local TeamHistoryManualExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Manual')
local TeamHistoryStoreExtension = Lua.import('Module:Infobox/Extension/TeamHistory/Store')

local Component = Lua.import('Module:Widget/Component')
local TeamHistoryDisplay = Lua.import('Module:Widget/Infobox/TeamHistory/Display')

---@return Renderable?
local function TeamHistory(props)
	if Logic.isEmpty(props) then return end
	local transferList = TeamHistoryManualExtension.parse(props)

	if not Logic.readBool(props.disableStorage) then
		TeamHistoryStoreExtension.store{
			transferList = transferList,
			isFromWikiCode = true,
			isManual = true,
		}
	end

	return TeamHistoryDisplay{
		transferList = transferList,
		alwaysShowPresent = true,
	}
end

return Component.component(TeamHistory)
