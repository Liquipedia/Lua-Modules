---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateClean = require('Module:DateTime')
local GameLookup = require('Module:GameLookup')
local GameModeLookup = require('Module:GameModeLookup')
local Lua = require('Module:Lua')
local MapMode = require('Module:MapMode')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _league
local categories = {}

local _TIER_SHOW_MATCH = 9

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.createLiquipediaTierDisplay = CustomLeague.createLiquipediaTierDisplay

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	local args = _league.args

	if id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Game & Version',
			content = CustomLeague:_getGameVersion(args)
		})

		table.insert(widgets, Cell{
			name = 'Game Mode',
			content = CustomLeague:_getGameModes(args, true)
		})
	elseif id == 'customcontent' then
		local playertitle = (not String.isEmpty(args.team_number)) and 'Teams' or 'Players'

		table.insert(widgets, Title{name = playertitle})

		table.insert(widgets, Cell{
			name = 'Number of Teams',
			content = {args.team_number}
		})

		table.insert(widgets, Cell{
			name = 'Number of Players',
			content = {args.player_number}
		})

		if not String.isEmpty(args.team1) then
			local teams = {Page.makeInternalLink(args.team1)}
			local index = 2

			while not String.isEmpty(args['team' .. index]) do
				table.insert(teams, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						Page.makeInternalLink(args['team' .. index])
					))
				)
				index = index + 1
			end

			table.insert(widgets, Center{content = teams})
		end

		if not String.isEmpty(args.map1) then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_displayMaps(CustomLeague:_getMaps())})
		end
	elseif id == 'sponsors' then
		if not String.isEmpty(args.sponsors) then
			local sponsors = mw.text.split(args.sponsors, ',', true)
			table.insert(widgets, Cell{
				name = 'Sponsor(s)',
				content = {table.concat(sponsors, '&nbsp;• ')}
			})
		end
	end

	return widgets
end


function CustomLeague:getWikiCategories(args)
	if String.isEmpty(args.game) then
		table.insert(categories, 'Tournaments without game version')
	else
		table.insert(categories, GameLookup.getName({args.game}) .. (args.beta and ' Beta' or '') .. ' Competitions')
	end

	local tier = Variables.varDefault('tournament_liquipediatier', '')
	local tiertype = Variables.varDefault('tournament_liquipediatiertype', '')

	if String.isEmpty(tier) then
		table.insert(categories, 'Pages with unsupported Tier')
	else
		table.insert(categories, Tier['text'][tier] .. ' Tournaments')
	end

	if not String.isEmpty(tiertype) then
		table.insert(categories, tiertype .. ' Tournaments')
	end

	return categories
end

function CustomLeague:createLiquipediaTierDisplay(args)
	local content = ''

	local tierVar = Variables.varDefault('tournament_liquipediatier', '')
	local tier = Tier['text'][tierVar]
	local tierDisplay = tonumber(tierVar) == _TIER_SHOW_MATCH
		and Page.makeInternalLink({}, tier, GameLookup.getName({args.game}) .. '/' .. tier .. 'es')
		or Page.makeInternalLink({}, tier, GameLookup.getName({args.game}) .. '/' .. tier .. ' Tournaments')

	local type = Variables.varDefault('tournament_liquipediatiertype', '')
	if not String.isEmpty(type) then
		local typeNumber = Tier['number'][type]
		local typeDisplay = tonumber(typeNumber) == _TIER_SHOW_MATCH
			and Page.makeInternalLink({}, type, GameLookup.getName({args.game}) .. '/' .. type .. 'es')
			or Page.makeInternalLink({}, type, GameLookup.getName({args.game}) .. '/' .. type .. ' Tournaments')
		content = content .. typeDisplay .. ' (' .. tierDisplay .. ')'
	else
		content = content .. tierDisplay
	end

	return content
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', CustomLeague:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', args.sponsors)


	local dateclean = ReferenceCleaner.clean(args.date)
	local edateclean = ReferenceCleaner.clean(args.edate)
	local sdateclean = ReferenceCleaner.clean(args.sdate)
	local date = (not String.isEmpty(args.date)) and dateclean
					or edateclean
	local startdate = (not String.isEmpty(args.sdate)) and sdateclean
					or dateclean
	local enddate = (not String.isEmpty(args.edate)) and edateclean
					or dateclean
	Variables.varDefine('tournament_date', date)
	Variables.varDefine('tournament_sdate', startdate)
	Variables.varDefine('tournament_edate', enddate)
	Variables.varDefine('date', date)
	Variables.varDefine('sdate', startdate)
	Variables.varDefine('edate', enddate)

	Variables.varDefine('game', GameLookup.getName({args.game}))
	Variables.varDefine('tournament_game', GameLookup.getName({args.game}))
	-- Currently, args.patch shall be used for official patches,
	-- whereas voobly is used to denote non-official version played via voobly
	Variables.varDefine('tournament_patch', args.patch or args.voobly)
	Variables.varDefine('patch', args.patch or args.voobly)
	Variables.varDefine('tournament_gameversion', args.version)
	Variables.varDefine('tournament_mode',
		(not String.isEmpty(args.mode)) and args.mode or
		(not String.isEmpty(args.team_number)) and 'team' or
		'1v1'
	)
	Variables.varDefine('tournament_headtohead', args.headtohead)

	-- clean liquipediatiers:
	-- tier should be a number defining a tier
	local liquipediatier = args.liquipediatier
	if not tonumber(liquipediatier) then
		liquipediatier = Tier['number'][liquipediatier]
	end

	-- type should be the textual representation of the numbers
	local liquipediatiertype = args.liquipediatiertype
	if not tonumber(liquipediatiertype) then
		liquipediatiertype = Tier['number'][liquipediatiertype]
	end
	liquipediatiertype = Tier['text'][liquipediatiertype]

	Variables.varDefine('tournament_liquipediatier', liquipediatier)
	Variables.varDefine('tournament_liquipediatiertype', liquipediatiertype)

	-- Legacy tier vars
	Variables.varDefine('tournament_lptier', liquipediatier)
	Variables.varDefine('tournament_tier', liquipediatier)
	Variables.varDefine('tournament_tiertype', liquipediatiertype)
	Variables.varDefine('ltier', liquipediatier == 1 and 1 or
		liquipediatier == 2 and 2 or
		liquipediatier == 3 and 3 or 4
	)

	-- Legacy notability vars
	Variables.varDefine('tournament_notability_mod', args.notabilitymod or 1)

	-- Variables for extradata to be added again in
	-- Module:Prize pool, Module:Prize pool team, Module:TeamCard and Module:TeamCard2
	Variables.varDefine('tournament_deadline', DateClean._clean(args.deadline or ''))
	Variables.varDefine('tournament_gamemode', table.concat(CustomLeague:_getGameModes(args, false), ','))

	-- map links, to be used by brackets and mappool templates
	for _, map in ipairs(CustomLeague:_getMaps()) do
		Variables.varDefine('tournament_map_'.. map.displayName, map.link)
	end
end

function CustomLeague:addToLpdb(lpdbData, args)
	if String.isEmpty(args.tickername) then
		lpdbData['tickername'] = args.name
	end

	-- Prevent resolving redirects for series
	-- lpdbData.seriespage will still contain the resolved page
	lpdbData['series'] = args.series

	lpdbData['sponsors'] = args.sponsors

	local mapPages = Table.mapValues(_league.maps, function(map) return map.link end)
	lpdbData['maps'] = table.concat(mapPages, ';')

	lpdbData['game'] = GameLookup.getName({args.game})
	-- Currently, args.patch shall be used for official patches,
	-- whereas voobly is used to denote non-official version played via voobly
	lpdbData['patch'] = args.patch or args.voobly
	lpdbData['participantsnumber'] = args.team_number or args.player_number

	lpdbData.extradata.region = args.region
	lpdbData.extradata.deadline = DateClean._clean(args.deadline or '')
	lpdbData.extradata.gamemode = table.concat(CustomLeague:_getGameModes(args, false), ',')
	lpdbData.extradata.gameversion = args.version

	return lpdbData
end

function CustomLeague:_concatArgs(args, base)
	local foundArgs = {args[base] or args[base .. '1']}
	local index = 2
	while not String.isEmpty(args[base .. index]) do
		table.insert(foundArgs, args[base .. index])
		index = index + 1
	end

	return table.concat(foundArgs, ';')
end

function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

function CustomLeague:_getGameVersion(args)
	local gameversion = {}

	if not String.isEmpty(args.game) then
		local gameName = GameLookup.getName({args.game})
		if String.isEmpty(gameName) then
			error('Unknown or unsupported game: ' .. args.game)
		end
		table.insert(gameversion,
			Page.makeInternalLink(gameName) .. (args.beta and ' Beta' or '')
		)

		if not String.isEmpty(args.version) then
			table.insert(gameversion,
				GameLookup.makeVersionLink({game = args.game, version = args.version}) or args.version
			)
		end

		if not String.isEmpty(args.patch) then
			table.insert(gameversion,
				CustomLeague:_makePatchLink(args)
			)
		end

		if not String.isEmpty(args.voobly) then
			table.insert(gameversion, args.voobly)
		end
	end

	return gameversion
end


function CustomLeague:_makePatchLink(args)
	local content = GameLookup.makePatchLink({game = args.game, version = args.version, patch = args.patch})

	if not String.isEmpty(args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		local version = not String.isEmpty(args.eversion) and args.eversion or args.version

		content = content .. GameLookup.makePatchLink({game = args.game, version = version, patch = args.epatch})
	end
	return content
end

function CustomLeague:_getGameModes(args, makeLink)
	if String.isEmpty(args.gamemode) then
		local default = GameModeLookup.getDefault(args.game or '')
		table.insert(categories, default .. ' Tournaments')
		if makeLink then
			default = Page.makeInternalLink(default)
		end
		return {default}
	end

	local gameModes = mw.text.split(args.gamemode, ',', true)
	Array.forEach(gameModes,
		function(mode, index)
			gameModes[index] = GameModeLookup.getName(mode) or ''

			table.insert(categories, not String.isEmpty(gameModes[index])
				and gameModes[index] .. ' Tournaments'
				or 'Pages with unknown game mode'
			)

			if makeLink then
				gameModes[index] = Page.makeInternalLink(gameModes[index])
			end
		end
	)

	return gameModes
end

function CustomLeague:_getMaps()
	if _league.maps then
		return _league.maps
	end

	local args = _league.args
	local maps = {}
	for prefix, mapInput in Table.iter.pairsByPrefix(args, 'map') do
		local mode = String.isNotEmpty(args[prefix .. 'mode']) and MapMode.get({args[prefix .. 'mode']}) or ''

		mapInput = mw.text.split(mapInput, '|', true)
		local display, link

		if String.isNotEmpty(args[prefix .. 'link']) then
			link = args[prefix .. 'link']
			display = mapInput[1]
		else
			link = mapInput[1]
			-- only check for a map page when map has only one part,
			-- so no precise link is given
			if mapInput[2] == nil and Page.exists(link .. ' (map)') then
				link = link .. ' (map)'
			end
			display = mapInput[2] or mapInput[1]
		end
		link = mw.ext.TeamLiquidIntegration.resolve_redirect(link)

		table.insert(maps, {link = link, displayName = display, mode = mode})
	end

	_league.maps = maps

	return maps
end

function CustomLeague:_displayMaps(maps)
	local mapDisplay = function(map)
		return tostring(CustomLeague:_createNoWrappingSpan(
			Page.makeInternalLink({}, map.displayName .. map.mode, map.link)
		))
	end

	return {table.concat(
		Table.mapValues(maps, function(map) return mapDisplay(map) end),
		'&nbsp;• '
	)}
end

return CustomLeague
