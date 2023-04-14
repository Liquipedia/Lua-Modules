---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Tournament supported by Riot Games]]'

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay

	_args.liquipediatier = Tier.toNumber(_args.liquipediatier)

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {(_args.team_number or '') .. (_args.team_slots and ('/' .. _args.team_slots) or '')}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {_args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		if String.isNotEmpty(_args.map1) then
			local game = String.isNotEmpty(_args.game) and ('/' .. _args.game) or ''
			local maps = {}

			for _, map in ipairs(_league:getAllArgsForBase(_args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					Page.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Patch',
			content = {CustomLeague:_createPatchCell(_args)}
		})
	end

	return widgets
end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if Logic.readBool(args.female) then
		table.insert(categories, 'Female Tournaments')
	end

	return categories
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')

	if Logic.readBool(args.riotpremier) then
		lpdbData.publishertier = 'major'
	elseif Logic.readBool(args['riot-sponsored']) then
		lpdbData.publishertier = 'Sponsored'
	end

	lpdbData.participantsnumber = args.player_number or args.team_number

	lpdbData.extradata.region = Template.safeExpand(mw.getCurrentFrame(), 'Template:Player region', {args.country})
	lpdbData.extradata.startdate_raw = args.sdate or args.date
	lpdbData.extradata.enddate_raw = args.edate or args.date
	lpdbData.extradata.female = args.female or 'false'

	return lpdbData
end

function CustomLeague:liquipediaTierHighlighted()
	return Logic.readBool(_args['riot-sponsored'])
end

function CustomLeague:appendLiquipediatierDisplay()
	if Logic.readBool(_args['riot-sponsored']) then
		return ' ' .. RIOT_ICON
	end
	return ''
end

function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end
	local content

	if String.isEmpty(args.epatch) then
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]'
	else
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]' .. ' &ndash; ' ..
		'[[Patch ' .. args.epatch .. '|'.. args.epatch .. ']]'
	end

	return content
end

function CustomLeague:defineCustomPageVariables()
	-- Wiki Custom
	Variables.varDefine('female', _args.female or 'false')
	Variables.varDefine('tournament_riot_premier', _args.riotpremier and 'true' or '')
	Variables.varDefine('tournament_mode', (_args.individual or _args. player_number) and '1v1' or 'team')
	Variables.varDefine('patch', _args.patch or '')

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername', ''))
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype', ''))

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
end

function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague
