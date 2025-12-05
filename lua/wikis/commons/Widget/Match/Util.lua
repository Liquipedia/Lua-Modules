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

---@param match MatchGroupUtilMatch
---@return boolean
function MatchWidgetUtil.shouldShowStreams(match)
	if match.phase == 'ongoing' then
		return true
	end

	if match.phase == 'upcoming' and match.timestamp then
		local currentTimestamp = DateExt.getCurrentTimestamp()
		if not currentTimestamp then
			return false
		end
		return os.difftime(match.timestamp, currentTimestamp) < MatchWidgetUtil.STREAM_DISPLAY_THRESHOLD_SECONDS
	end

	return false
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchWidgetUtil.shouldShowMatchDetails(match)
	if match.phase == 'finished' or match.phase == 'ongoing' then
		return true
	end

	if match.phase == 'upcoming' and match.timestamp then
		local currentTimestamp = DateExt.getCurrentTimestamp()
		if not currentTimestamp then
			return false
		end
		return os.difftime(match.timestamp, currentTimestamp) < MatchWidgetUtil.STREAM_DISPLAY_THRESHOLD_SECONDS
	end

	return false
end

---@param match MatchGroupUtilMatch
---@return boolean
function MatchWidgetUtil.isMatchCloseToStart(match)
	if match.phase ~= 'upcoming' or not match.timestamp then
		return false
	end

	local currentTimestamp = DateExt.getCurrentTimestamp()
	if not currentTimestamp then
		return false
	end

	return os.difftime(match.timestamp, currentTimestamp) < MatchWidgetUtil.STREAM_DISPLAY_THRESHOLD_SECONDS
end

return MatchWidgetUtil
