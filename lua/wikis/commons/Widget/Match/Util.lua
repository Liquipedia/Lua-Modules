---
-- @Liquipedia
-- page=Module:Widget/Match/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')

---@class MatchWidgetUtil
local MatchWidgetUtil = {}

MatchWidgetUtil.STREAM_DISPLAY_THRESHOLD_SECONDS = 2 * 60 * 60

---@param matchTimestamp number
---@return boolean
local function isWithinDisplayThreshold(matchTimestamp)
	local currentTimestamp = DateExt.getCurrentTimestamp()
	return os.difftime(matchTimestamp, currentTimestamp) < MatchWidgetUtil.STREAM_DISPLAY_THRESHOLD_SECONDS
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchWidgetUtil.shouldShowStreams(match)
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
function MatchWidgetUtil.shouldShowMatchDetails(match)
	if match.phase == 'finished' or match.phase == 'ongoing' then
		return true
	elseif not match.timestamp then
		return false
	end

	return isWithinDisplayThreshold(match.timestamp)
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchWidgetUtil.isMatchCloseToStart(match)
	if match.phase ~= 'upcoming' then
		return false
	elseif not match.timestamp then
		return false
	end

	return isWithinDisplayThreshold(match.timestamp)
end

return MatchWidgetUtil
