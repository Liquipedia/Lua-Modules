---
-- @Liquipedia
-- page=Module:MainPageLayout/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')

local MainPageLayoutUtil = {}

---@enum MainPageBoxId
MainPageLayoutUtil.BoxId = {
	USEFUL_ARTICLES = 1503,
	WANT_TO_HELP = 1504,
	MATCH_TICKER = 1507,
	TOURNAMENTS_TICKER = 1508,
	TRANSFERS = 1509,
	THIS_DAY = 1510,
	SPECIAL_EVENTS = 1516,
}

---@return string
function MainPageLayoutUtil.getQuarterlyTransferPage()
	return 'Player Transfers/' .. DateExt.getYearOf() .. '/' ..
		DateExt.quarterOf{ ordinalSuffix = true } .. ' Quarter'
end

return MainPageLayoutUtil
