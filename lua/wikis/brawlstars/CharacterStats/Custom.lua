---
-- @Liquipedia
-- page=Module:CharacterStats/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local BaseCharacterStats = Lua.import('Module:CharacterStats')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local CharacterStatsWidget = Lua.import('Module:Widget/CharacterStats')

---@class BSCharacterStats: CharacterStats
---@operator call(table): BSCharacterStats
local BSCharacterStats = Class.new(BaseCharacterStats)

---@return string[]
function BSCharacterStats:getSides()
	return {}
end

---@param frame Frame
---@return Widget
function BSCharacterStats.run(frame)
	local args = Arguments.getArgs(frame)
	local stats = BSCharacterStats(args)

	local games = stats:queryGames()
	local processedData = stats:processGames(games)
	return CharacterStatsWidget{
		characterType = 'Champion',
		data = processedData.characterData,
		includeBans = Array.any(processedData.characterData, function (data)
			return data.bans > 0
		end),
		numGames = #games,
		sides = stats:getSides(),
		sideWins = processedData.overall.wins,
		statspage = args.statspage
	}
end

-- Override functions from BaseCharacterStats

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function BSCharacterStats:getTeamCharacters(game, opponentIndex)
	local players = ((game.opponents or {})[opponentIndex] or {}).players or {}
	local characters = {}
	for _, player in ipairs(players) do
		if type(player) == 'table' and String.isNotEmpty(player.brawler) then
			table.insert(characters, player.brawler)
		end
	end
	return characters
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function BSCharacterStats:getTeamBans(game, opponentIndex)
	local teamBans = ((game.extradata or {}).bans or {})['team' .. opponentIndex] or {}
	local bans = {}
	for _, ban in pairs(teamBans) do
		if String.isNotEmpty(ban) then
			table.insert(bans, ban)
		end
	end
	return bans
end

return BSCharacterStats
