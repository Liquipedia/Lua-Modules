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

---@class BrawlStarsCharacterStats: CharacterStats
---@operator call(table): BrawlStarsCharacterStats
local BrawlStarsCharacterStats = Class.new(BaseCharacterStats)

---@return string[]
function BrawlStarsCharacterStats:getSides()
	return {}
end

---@param frame Frame
---@return Widget
function BrawlStarsCharacterStats.run(frame)
	local args = Arguments.getArgs(frame)
	local stats = BrawlStarsCharacterStats(args)

	local games = stats:queryGames()
	local processedData = stats:processGames(games)
	return CharacterStatsWidget{
		characterType = 'Brawler',
		data = processedData.characterData,
		includeBans = Array.any(processedData.characterData, function (data)
			return data.bans > 0
		end),
		includeGlobalBans = true,
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
function BrawlStarsCharacterStats:getTeamCharacters(game, opponentIndex)
	return Array.filter(Array.mapIndexes(function (characterIndex)
		return game.extradata['team' .. opponentIndex .. 'brawler' .. characterIndex]
	end), String.isNotEmpty)
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function BrawlStarsCharacterStats:getTeamGlobalBans(game, opponentIndex)
	local teamGlobalBans = (game.globalBans or {})['team' .. opponentIndex] or {}
	return Array.filter(teamGlobalBans, String.isNotEmpty)
end

return BrawlStarsCharacterStats
