---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class Dota2LeagueInfobox: InfoboxLeague
---@field publisherTier {meta: string, name: string, link: string}?

local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local VALVE_TIERS = {
	['international'] = {meta = '', name = 'The International', link = 'The International'},
	['major'] = {meta = 'Dota Major Championship', name = 'Major Championship', link = 'Dota Major Championships'},
	['dpc major'] = {meta = 'DPC Major', name = 'DPC Major', link = 'Dota Major Championships'},
	['dpc minor'] = {meta = 'DPC Minor', name = 'DPC Minor', link = 'Dota Minor Championships'},
	['dpc league'] = {meta = 'DPC Regional League', name = 'DPC Regional League', link = 'Regional League'}
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	-- Override links to allow one param to set multiple links
	league.args.datdota = league.args.leagueid
	league.args.dotabuff = league.args.leagueid
	league.args.stratz = league.args.leagueid

	-- Valve Tier stuff
	league.args.publisherdescription = 'metadesc-valve'
	league.publisherTier = VALVE_TIERS[(league.args.publishertier or ''):lower()]

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local points = tonumber(args.points)

		Array.appendWith(widgets,
			Cell{name = 'Game', content = {Game.text{game = args.game}}},
			Cell{name = 'Version', content = {self.caller:_createPatchCell(args)}},
			Cell{name = 'Teams', content = {args.team_number}},
			Cell{name = 'Players', content = {args.player_number}},
			Cell{name = 'Dota TV Ticket', content = {args.dotatv}},
			Cell{name = 'Pro Circuit Points', content = {points and mw.getContentLanguage():formatNum(points)}}
		)
	elseif id == 'liquipediatier' and self.caller.publisherTier then
		table.insert(
			widgets,
			Cell{
				name = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox') .. ' Tier',
				content = {self.caller:_createPublisherTierCell()},
				classes = {'valvepremier-highlighted'}
			}
		)
	end

	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''
	lpdbData.extradata.dpcpoints = String.isNotEmpty(args.points) or ''
	lpdbData.extradata.headtohead = self.data.headtohead
	lpdbData.extradata.leagueid = args.leagueid

	return lpdbData
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = (self.publisherTier or {}).name
	self.data.headtohead = tostring(Logic.readBool(args.headtohead))
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Custom Vars
	Variables.varDefine('headtohead', self.data.headtohead)
	Variables.varDefine('tournament_pro_circuit_points', args.points or '')
	local isIndividual = String.isNotEmpty(args.individual) or String.isNotEmpty(args.player_number)
	Variables.varDefine('tournament_individual', isIndividual and 'true' or '')
	if self.publisherTier then
		Variables.varDefine('metadesc-valve', self.publisherTier.meta)
	end

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', args.liquipediatiertype)
	Variables.varDefine('tournament_prizepool', args.prizepool or '')

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

	local displayText = '[['.. args.patch .. ']]'
	if args.epatch then
		displayText = displayText .. ' &ndash; [['.. args.epatch .. ']]'
	end
	return displayText
end

---@return string?
function CustomLeague:_createPublisherTierCell()
	if self.publisherTier then
		return '[[' .. self.publisherTier.link .. '|' .. self.publisherTier.name .. ']]'
	end
end

return CustomLeague
