---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class BrawlhallaLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local TODAY = os.date('%Y-%m-%d') --[[@as string]]

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'customcontent' then
		if not String.isEmpty(args.player_number) or not String.isEmpty(args.doubles_number) then
			table.insert(widgets, Title{children = 'Player Breakdown'})
			table.insert(widgets, Cell{
				name = 'Number of Players',
				content = {args.player_number}
			})
			table.insert(widgets, Cell{
				name = 'Doubles Players',
				content = {args.doubles_number}
			})
		end
	end
	return widgets
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	local sdate = self.data.startDate or TODAY
	local edate = self.data.endDate or TODAY
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)

	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_link', mw.title.getCurrentTitle().prefixedText)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.region = args.region
	lpdbData.extradata.mode = args.mode

	return lpdbData
end

return CustomLeague
