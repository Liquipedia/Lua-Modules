---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Score
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---The wins followed by the negated losses, shown as the game record
---@class TiebreakerGameScore : StandingsTiebreaker
local TiebreakerGameScore = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return StandingsTiebreakerValue
function TiebreakerGameScore:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent, self.options.walkoverGames)
	return {games.w, -games.l}
end

---@return string
function TiebreakerGameScore:headerTitle()
	return 'Game'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameScore:display(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent, self.options.walkoverGames)
	-- With overtime, regulation and overtime results are shown separately
	if opponent.overtime then
		local overtimeGames = TiebreakerGameUtil.getOvertimeGames(opponent)
		return table.concat({
			games.w - overtimeGames.w, overtimeGames.w, overtimeGames.l, games.l - overtimeGames.l
		}, ' - ')
	end
	if self:showsDraws('game') then
		return games.w .. ' - ' .. games.d .. ' - ' .. games.l
	end
	return games.w .. ' - ' .. games.l
end

return TiebreakerGameScore
