---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local DEFAULT_START_YEAR = Info.startYear
local DEFAULT_END_YEAR = tonumber(os.date('%Y')) --[[@as integer]]

local CustomTournamentsListing = Class.new()

---@param frame Frame
---@return Html|Widget?
function CustomTournamentsListing.run(frame)
	local args = Arguments.getArgs(frame)

	if Logic.readBool(args.byYear) then
		args.byYear = nil
		return CustomTournamentsListing.byYear(args)
	end

	return TournamentsListing(args):create():build()
end

---@param args table
---@return Widget?
function CustomTournamentsListing.byYear(args)
	args = args or {}

	args.order = 'enddate desc'

	local subPageName = mw.title.getCurrentTitle().subpageText
	local fallbackYearData = {}
	if subPageName:find('%d%-%d') then
		fallbackYearData = mw.text.split(subPageName, '-')
	end

	local startYear = tonumber(args.startYear) or tonumber(fallbackYearData[1]) or DEFAULT_START_YEAR
	local endYear = tonumber(args.endYear) or tonumber(fallbackYearData[2]) or DEFAULT_END_YEAR

	local children = {}
	Array.forEach(Array.reverse(Array.range(startYear, endYear)), function(year)
		local tournaments = CustomTournamentsListing.run(Table.merge(args, {year = year}))
		if not tournaments then return end
		Array.appendWith(children,
			HtmlWidgets.H3{children = year},
			tournaments
		)
	end)

	return HtmlWidgets.Fragment{children = children}
end

return CustomTournamentsListing
