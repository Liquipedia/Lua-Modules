---
-- @Liquipedia
-- page=Module:Infobox/Extension/RaceBreakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local Table = Lua.import('Module:Table')

local RaceBreakdown = {}

---Calculates the race breakdown values and builds the display contents for it
---@param args table
---@param factions string[]?
---@return {total: number, display: string[]}?
function RaceBreakdown.run(args, factions)
	if Table.isEmpty(factions) then
		factions = Array.map(Array.map(Faction.knownFactions, Faction.toName), string.lower)
	end
	---@cast factions -nil

	local playerBreakDown = {display = {}}

	local numbers = Array.map(factions, function(race) return tonumber(args[race .. '_number']) or 0 end)
	---@cast numbers table
	numbers.total = tonumber(args.player_number) or 0
	numbers.totalCalculated = 0

	for raceIndex, race in ipairs(factions) do
		if numbers[raceIndex] ~= 0 then
			numbers.totalCalculated = numbers.totalCalculated + numbers[raceIndex]
			table.insert(playerBreakDown.display, Faction.Icon{faction = race} .. ' ' .. numbers[raceIndex])
		end
	end

	playerBreakDown.total = numbers.total == 0 and numbers.totalCalculated or numbers.total

	if playerBreakDown.total == 0 then
		return
	end

	return playerBreakDown
end

return RaceBreakdown
