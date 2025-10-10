---
-- @Liquipedia
-- page=Module:MainPageLayout/AnalyticsMapping
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@class MainPageAnalyticsMapping
local AnalyticsMapping = {}

AnalyticsMapping.BOX_ID_TO_ANALYTICS_NAME = {
	[1501] = 'Heroes panel',
	[1502] = 'Updates panel',
	[1503] = 'Useful articles panel',
	[1504] = 'Want to help panel',
	[1507] = 'Matchticker',
	[1508] = 'Tournament ticker',
	[1509] = 'Transfers panel',
	[1510] = 'This day panel',
	[1511] = 'Rankings panel',
	[1516] = 'Featured panel',
}

---@param boxId number
---@return string|nil
function AnalyticsMapping.getAnalyticsName(boxId)
	if not boxId then
		return nil
	end

	local numericBoxId = tonumber(boxId)
	return AnalyticsMapping.BOX_ID_TO_ANALYTICS_NAME[numericBoxId]
end

return AnalyticsMapping
