---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local CustomMatchSummary = {}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {teamStyle = 'short'})
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Renderable?
function CustomMatchSummary.createGame(game, gameIndex)
	return nil
end

return CustomMatchSummary
