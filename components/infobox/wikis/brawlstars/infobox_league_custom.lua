---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local SUPERCELL_SPONSORED_ICON = '[[File:Supercell icon.png|x18px|link=Supercell|Tournament sponsored by Supercell.]]'

local ORGANIZER_ICONS = {
	Supercell = '[[File:Supercell icon.png|x18px|link=Supercell|Supercell]] ',
	['Esports Engine'] = '[[File:Esports Engine icon allmode.png|x18px|link=Esports Engine|Esports Engine]] '
}

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'organizers' then
		local organizers = CustomLeague._createOrganizers()
		local title = Table.size(organizers) == 1 and 'Organizer' or 'Organizers'

		return {
			Cell{
				name = title,
				content = organizers
			}
		}
	end

	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})

	return widgets
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['supercell-sponsored'])
end

function CustomLeague:appendLiquipediatierDisplay()
	return Logic.readBool(_args['supercell-sponsored']) and ('&nbsp;' .. SUPERCELL_SPONSORED_ICON) or ''
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.publishertier = args['supercell-sponsored']
	lpdbData.participantsnumber = args.team_number

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('tournament_prizepool', _args.prizepool or '')

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

function CustomLeague._createOrganizers()
	if not _args.organizer then
		return {}
	end

	local organizers = {
		(ORGANIZER_ICONS[_args.organizer] or '') .. _league:createLink(
			_args.organizer, _args['organizer-name'], _args['organizer-link'], _args.organizerref),
	}

	local index = 2
	while not String.isEmpty(_args['organizer' .. index]) do
		table.insert(
			organizers,
			(ORGANIZER_ICONS[_args['organizer' .. index]] or '') .. _league:createLink(
				_args['organizer' .. index],
				_args['organizer' .. index .. '-name'],
				_args['organizer' .. index .. '-link'],
				_args['organizerref' .. index])
		)
		index = index + 1
	end

	return organizers
end

return CustomLeague
