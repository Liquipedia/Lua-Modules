---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local TournamentNotability = require('Module:TournamentNotability')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _SERIES_RLCS = 'Rocket League Championship Series'
local _MODE_2v2 = '2v2'
local _GAME_ROCKET_LEAGUE = 'rl'
local _GAME_SARPBC = 'sarpbc'

local _league

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.createLiquipediaTierDisplay = CustomLeague.createLiquipediaTierDisplay

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _league.args
	table.insert(widgets, Cell{
		name = 'Mode',
		content = {args.mode}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {CustomLeague:_createGameCell(args.game)}
	})
	table.insert(widgets, Cell{
		name = 'Misc Mode',
		content = {args.miscmode}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _league.args
	if id == 'customcontent' then
		if not String.isEmpty(args.map1) then
			local maps = {CustomLeague:_makeInternalLink(args.map1)}
			local index = 2

			while not String.isEmpty(args['map' .. index]) do
				table.insert(maps, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						CustomLeague:_makeInternalLink(args['map' .. index])
					))
				)
				index = index + 1
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = maps})
		end


		if not String.isEmpty(args.team_number) then
			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Cell{
				name = 'Number of teams',
				content = {args.team_number}
			})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool(args)}
			},
		}
	end
	return widgets
end

function CustomLeague:addCustomCells(infobox, args)
	infobox:cell('Mode', args.mode)
	infobox:cell('Game', CustomLeague:_createGameCell(args.game))
	infobox:cell('Misc Mode:', args.miscmode)
	return infobox
end

function CustomLeague:createLiquipediaTierDisplay(args)
	local content = ''

	local tier = args.liquipediatier
	local type = args.liquipediatiertype
	local type2 = args.liquipediatiertype2

	if String.isEmpty(tier) then
		return nil
	end

	local tierDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. tier)

	if not String.isEmpty(type) then
		local typeDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. type)
		content = content .. '[[' .. typeDisplay .. ' Tournaments|' .. type .. ']]'

		if not String.isEmpty(type2) then
			content = content .. ' ' .. type2
		end

		content = content .. ' ([[' .. tierDisplay .. ' Tournaments|' .. tierDisplay .. ']])'
	else
		content = content .. '[[' .. tierDisplay .. ' Tournaments|' .. tierDisplay .. ']]'
	end

	content = content .. '[[Category:' .. tierDisplay .. ' Tournaments]]'

	return content
end

function CustomLeague:_createPrizepool(args)
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
			return nil
	end

	local endDate = Variables.varDefault('tournament_enddate')
	if
		Logic.readBool(args.convertPrizePool) or
		String.isNotEmpty(endDate) and os.date('%Y-%m-%d') >= endDate
	then
		return _league:createPrizepool(args)
	end

	local content
	local prizepool = args.prizepool
	local prizepoolInUsd = args.prizepoolusd
	local localCurrency = args.localcurrency

	if String.isEmpty(prizepool) then
		content = '$' .. prizepoolInUsd .. ' ' .. Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD')
	else
		if not String.isEmpty(localCurrency) then
			content = Template.safeExpand(
				mw.getCurrentFrame(),
				'Local currency',
				{localCurrency:lower(), prizepool = prizepool}
			)
		else
			content = prizepool
		end

		if not String.isEmpty(prizepoolInUsd) then
			content = content .. '<br>(≃ $' .. prizepoolInUsd .. ' ' ..
				Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD') .. ')'
		end
	end

	if not String.isEmpty(prizepoolInUsd) then
		Variables.varDefine('tournament_prizepoolusd', prizepoolInUsd:gsub(',', ''):gsub('$', ''))
	end

	return content
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', CustomLeague:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', CustomLeague:_concatArgs(args, 'sponsor'))
	Variables.varDefine('tournament_rlcs_premier', args.series == _SERIES_RLCS and 1 or 0)
	Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
	Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))
	Variables.varDefine('tournament_rlcs_premier', args.series == _SERIES_RLCS and 1 or 0)

	-- Legacy tier vars
	Variables.varDefine('tournament_lptier', args.liquipediatier)
	Variables.varDefine('tournament_tier', args.liquipediatier)
	Variables.varDefine('tournament_tiertype', args.liquipediatiertype)
	Variables.varDefine('tournament_tiertype2', args.liquipediatiertype2)
	Variables.varDefine('ltier', args.liquipediatier == 1 and 1 or
		args.liquipediatier == 2 and 2 or
		args.liquipediatier == 3 and 3 or 4
	)

	-- Legacy notability vars
	Variables.varDefine('tournament_notability_mod', args.notabilitymod or 1)

	-- Rocket League specific
	Variables.varDefine('tournament_patch', args.patch)
	Variables.varDefine('tournament_mode', args.mode)
	Variables.varDefine('tournament_participant_number', 0)
	Variables.varDefine('tournament_participants', '(')
	Variables.varDefine('tournament_teamplayers', args.mode == _MODE_2v2 and 2 or 3)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData['game'] = 'rocket league'
	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData['extradata'] = {
		region = args.region,
		mode = args.mode,
		notabilitymod = args.notabilitymod,
		liquipediatiertype2 = args.liquipediatiertype2,
		participantsnumber =
			not String.isEmpty(args.team_number) and args.team_number or args.player_number,
		notabilitypercentage = args.edate ~= 'tba' and TournamentNotability.run() or ''
	}

	lpdbData['extradata']['is rlcs'] = Variables.varDefault('tournament_rlcs_premier', 0)
	return lpdbData
end

function CustomLeague:_createGameCell(game)
	if game == _GAME_ROCKET_LEAGUE then
		return '[[Rocket League]][[Category:Rocket League Competitions]]'
	elseif game == _GAME_SARPBC then
		return '[[Supersonic Acrobatic Rocket-Powered Battle-Cars]]' ..
			'[[Category:Supersonic Acrobatic Rocket-Powered Battle-Cars Competitions]]'
	end

	return nil
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
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague:_makeInternalLink(content)
	return '[[' .. content .. ']]'
end

return CustomLeague
