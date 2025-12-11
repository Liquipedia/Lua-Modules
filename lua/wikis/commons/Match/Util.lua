---
-- @Liquipedia
-- page=Module:Match/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Table = Lua.import('Module:Table')

local MatchUtil = {}

MatchUtil.STREAM_DISPLAY_THRESHOLD_SECONDS = 2 * 60 * 60

---@param matchOpponent table
---@param gameOpponent table
function MatchUtil.enrichGameOpponentFromMatchOpponent(matchOpponent, gameOpponent)
	local newGameOpponent = Table.deepMerge(matchOpponent, gameOpponent)
	-- These values are only allowed to come from Game and not Match
	newGameOpponent.placement = gameOpponent.placement
	newGameOpponent.score = gameOpponent.score
	newGameOpponent.status = gameOpponent.status

	-- TODO: match2players vs players duplication. Which one to keep? How to merge?

	return newGameOpponent
end

---@param matchTimestamp number
---@return boolean
local function isWithinDisplayThreshold(matchTimestamp)
	local currentTimestamp = DateExt.getCurrentTimestamp()
	return os.difftime(matchTimestamp, currentTimestamp) < MatchUtil.STREAM_DISPLAY_THRESHOLD_SECONDS
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchUtil.shouldShowStreams(match)
	if match.phase == 'ongoing' then
		return true
	elseif match.phase == 'finished' then
		return false
	elseif not match.timestamp then
		return false
	end

	return isWithinDisplayThreshold(match.timestamp)
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchUtil.shouldShowMatchDetails(match)
	if match.phase == 'finished' or match.phase == 'ongoing' then
		return true
	elseif not match.timestamp then
		return false
	end

	return isWithinDisplayThreshold(match.timestamp)
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchUtil.isMatchCloseToStart(match)
	if match.phase ~= 'upcoming' then
		return false
	elseif not match.timestamp then
		return false
	end

	return isWithinDisplayThreshold(match.timestamp)
end

return MatchUtil
