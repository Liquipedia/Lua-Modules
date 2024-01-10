---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Premier Tournament held by Riot Games]]'

---@class LeagueoflegendsLeagueInfobox: InfoboxLeagueTemp
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.tickername = league.args.tickername or league.args.shortname

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Teams', content = {args.team_number}},
			Cell{name = 'Players', content = {args.participants_number}},
			Cell{name = 'Version', content = {self.caller:_createPatchCell(args)}}
		)
	end

	return widgets
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args.riotpremier) then
		return ' ' .. RIOT_ICON
	end
	return ''
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.riotpremier)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.participants_number) or
			String.isNotEmpty(args.individual) and 'true' or ''

	lpdbData.extradata['is riot premier'] = String.isNotEmpty(args.riotpremier) and 'true' or ''

	return lpdbData
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = Logic.readBool(args.riotpremier) and '1' or nil
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Custom Vars
	Variables.varDefine('tournament_riot_premier', args.riotpremier)
	Variables.varDefine('tournament_publisher_major', args.riotpremier)

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))

	--Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	local displayText = '[[Patch ' .. args.patch .. ']]'
	if args.epatch then
		displayText = displayText .. ' &ndash; [[Patch ' .. args.epatch .. ']]'
	end
	return displayText
end

return CustomLeague
