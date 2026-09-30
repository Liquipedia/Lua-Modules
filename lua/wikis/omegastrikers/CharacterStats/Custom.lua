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
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')

local CharacterStatsWidget = Lua.import('Module:Widget/CharacterStats')

---@class OmegaStrikersCharacterStats: CharacterStats
---@operator call(table): OmegaStrikersCharacterStats
local OmegaStrikersCharacterStats = Class.new(BaseCharacterStats)

---@return string[]
function OmegaStrikersCharacterStats:getSides()
	return {}
end

---@param frame Frame
---@return Widget
function OmegaStrikersCharacterStats.run(frame)
	local args = Arguments.getArgs(frame)
	local stats = OmegaStrikersCharacterStats(args)

	local games = stats:queryGames()
	local processedData = stats:processGames(games)
	return CharacterStatsWidget{
		characterType = 'Strikers',
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
function OmegaStrikersCharacterStats:getTeamCharacters(game, opponentIndex)
	local players = ((game.opponents or {})[opponentIndex] or {}).players or {}
	return Array.filter(Array.map(players, Operator.property('striker')), String.isNotEmpty)
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function OmegaStrikersCharacterStats:getTeamBans(game, opponentIndex)
	local teamBans = ((game.extradata or {}).bans or {})['team' .. opponentIndex] or {}
	return Array.filter(teamBans, String.isNotEmpty)
end

return OmegaStrikersCharacterStats
