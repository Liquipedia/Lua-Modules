---
-- @Liquipedia
-- wiki=commons
-- page=Module:TransferRow/Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')

local TransferRow = Lua.import('Module:TransferRow')

---@class FactionTransferRow: TransferRow
local FactionTransferRow = Class.new(TransferRow)

---@param frame Frame
---@return Html?
function FactionTransferRow.run(frame)
	return FactionTransferRow(Arguments.getArgs(frame)):read():store():build()
end

---@param playerIndex integer|string
---@return StarcraftStandardPlayer|WarcraftStandardPlayer|StormgateStandardPlayer
function FactionTransferRow:readPlayer(playerIndex)
	local args = self.args

	local name = args['name' .. playerIndex]
	local faction = args['faction' .. playerIndex] or args['race' .. playerIndex]

	return {
		displayName = name,
		flag = args['flag' .. playerIndex],
		pageName = args['link' .. playerIndex] or mw.getContentLanguage():ucfirst(name),
		race = faction,
		faction = faction,
	}
end

---@param player StarcraftStandardPlayer|WarcraftStandardPlayer|StormgateStandardPlayer
---@param playerIndex integer|string
---@return {icon: string?, icon2: string?, position: string?}
function FactionTransferRow:readIconsAndPosition(player, playerIndex)
	local faction = Faction.read(player.faction or player.race)
	return {
		icon = faction,
		icon2 = faction, --possibly remove due to redundancy?
		position = faction, --possibly remove due to redundancy?
	}
end

return FactionTransferRow
