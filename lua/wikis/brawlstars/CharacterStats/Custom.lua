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
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
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
	local players = ((game.opponents or {})[opponentIndex] or {}).players or {}
	return Array.filter(Array.map(players, Operator.property('brawler')), String.isNotEmpty)
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function BrawlStarsCharacterStats:getTeamBans(game, opponentIndex)
	local teamBans = ((game.extradata or {}).bans or {})['team' .. opponentIndex] or {}
	return Array.filter(teamBans, String.isNotEmpty)
end

return BrawlStarsCharacterStats
