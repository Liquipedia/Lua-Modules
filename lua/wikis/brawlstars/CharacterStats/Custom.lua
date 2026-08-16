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
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')

local CharacterStatsWidget = Lua.import('Module:Widget/CharacterStats')

---@class CharacterStatsGame
---@field opponents table
---@field globalBans table

---@class CharacterStatsData

---@class BrawlStarsCharacterStats
local BrawlStarsCharacterStats = {}

---@return string[]
---@diagnostic disable-next-line: duplicate-set-field
function BaseCharacterStats.getSides()
	return {}
end

---@param frame Frame
---@return Renderable
function BrawlStarsCharacterStats.run(frame)
	local args = Arguments.getArgs(frame)
	local games = BaseCharacterStats.queryGames(args)
	local processedData = BaseCharacterStats.processGames(games)
	return CharacterStatsWidget{
		characterType = 'Brawler',
		data = processedData.characterData,
		includeBans = Array.any(processedData.characterData, function (data)
			---@cast data CharacterStatsData
			return data.bans > 0
		end),
		includeGlobalBans = true,
		numGames = #games,
		sides = BaseCharacterStats.getSides(),
		sideWins = processedData.overall.wins,
		statspage = args.statspage
	}
end

-- Override functions from BaseCharacterStats

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function BaseCharacterStats.getTeamCharacters(game, opponentIndex)
	local players = ((game.opponents or {})[opponentIndex] or {}).players or {}
	return Array.filter(Array.map(players, Operator.property('brawler')), String.isNotEmpty)
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function BaseCharacterStats.getTeamGlobalBans(game, opponentIndex)
	local teamGlobalBans = (game.globalBans or {})['team' .. opponentIndex] or {}
	return Array.filter(teamGlobalBans, String.isNotEmpty)
end

return BrawlStarsCharacterStats
