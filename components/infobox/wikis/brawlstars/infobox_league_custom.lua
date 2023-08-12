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

local SUPERCELL_SPONSORED_ICON = '[[File:Supercell lightmode.png|x18px|link=Supercell'
	.. '|Tournament sponsored by Supercell.|class=show-when-light-mode]][[File:Supercell darkmode.png'
	.. '|x18px|link=Supercell|Tournament sponsored by Supercell.|class=show-when-dark-mode]]'

local ORGANIZER_ICONS = {
	supercell = '[[File:Supercell lightmode.png|x18px|link=Supercell|Supercell|class=show-when-light-mode]]'
		.. '[[File:Supercell darkmode.png|x18px|link=Supercell|Supercell|class=show-when-dark-mode]] ',
	['esports engine'] = '[[File:Esports Engine icon allmode.png|x18px|link=Esports Engine|Esports Engine]] ',
	['esl'] = '[[File:ESL 2019 icon lightmode.png|x18px|link=ESL|ESL|class=show-when-light-mode]]'
		.. '[[File:ESL 2019 icon darkmode.png|x18px|link=ESL|ESL|class=show-when-dark-mode]] ',
	['faceit'] = '[[File:FACEIT icon allmode.png|x18px|link=Esports Engine|Esports Engine]] ',
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

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_publishertier', args['supercell-sponsored'])

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or '')
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('tournament_prizepool', args.prizepool or '')

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

function CustomLeague._organizerIcon(organizer)
	if not organizer then return '' end

	return ORGANIZER_ICONS[organizer:lower()] or ''
end

function CustomLeague._createOrganizers()
	if not _args.organizer then
		return {}
	end

	local organizers = {
		CustomLeague._organizerIcon(_args.organizer) .. _league:createLink(
			_args.organizer, _args['organizer-name'], _args['organizer-link'], _args.organizerref),
	}

	local index = 2
	while not String.isEmpty(_args['organizer' .. index]) do
		table.insert(
			organizers,
			CustomLeague._organizerIcon(_args['organizer' .. index]) .. _league:createLink(
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
