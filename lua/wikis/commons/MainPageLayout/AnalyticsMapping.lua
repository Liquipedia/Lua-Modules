-- @Liquipedia
-- page=Module:MainPageLayout/AnalyticsMapping
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')

---@type table<integer, string>
local AnalyticsMappingData = {
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

---@param props {analyticsKey: integer?, analyticsName: string?, children: any}
---@return any
local function AnalyticsMapping(props)
	local analyticsName = props.analyticsName
	if not analyticsName and props.analyticsKey then
		analyticsName = AnalyticsMappingData[props.analyticsKey]
	end

	if analyticsName then
		return AnalyticsWidget{
			analyticsName = analyticsName,
			children = props.children
		}
	else
		return props.children
	end
end

return AnalyticsMapping
