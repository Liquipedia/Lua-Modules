---
-- @Liquipedia
-- page=Module:MainPageLayout/AnalyticsMapping
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')
local BoxId = MainPageLayoutUtil.BoxId

---@type table<integer, string>
local AnalyticsMapping = {
	[1501] = 'Heroes panel',
	[1502] = 'Updates panel',
	[BoxId.USEFUL_ARTICLES] = 'Useful articles panel',
	[BoxId.WANT_TO_HELP] = 'Want to help panel',
	[1505] = 'Mobile app panel',
	[BoxId.MATCH_TICKER] = 'Matchticker',
	[BoxId.TOURNAMENTS_TICKER] = 'Tournament ticker',
	[BoxId.TRANSFERS] = 'Transfers panel',
	[BoxId.THIS_DAY] = 'This day panel',
	[BoxId.SPECIAL_EVENTS] = 'Featured panel',
	[1520] = 'Rankings panel',
}

return AnalyticsMapping
