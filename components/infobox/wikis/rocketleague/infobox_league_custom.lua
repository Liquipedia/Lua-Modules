local League = require('Module:Infobox/League')
local Cell = require('Module:Infobox/Cell')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Class = require('Module:Class')
local TournamentNotability = require('Module:TournamentNotability')

local RLLeague = Class.new()

local _SERIES_RLCS = 'Rocket League Championship Series'
local _MODE_2v2 = '2v2'

function RLLeague.run(frame)
	local league = League(frame)
	league.addCustomCells = RLLeague.addCustomCells
	league.createTier = RLLeague.createTier
	league.createPrizepool = RLLeague.createPrizepool
	league.addCustomContent = RLLeague.addCustomContent
	league.defineCustomPageVariables = RLLeague.defineCustomPageVariables
	league.addToLpdb = RLLeague.addToLpdb

	return league:createInfobox(frame)
end

function RLLeague:addCustomCells(infobox, args)
	infobox:cell('Mode', args.mode)
	infobox:cell('Misc Mode:', args.miscmode)
	return infobox
end

function RLLeague:createTier(args)
	local cell =  Cell:new('Liquipedia Tier'):options({})

	local content = ''

	local tier = args.liquipediatier

	if String.isEmpty(tier) then
		return cell:content()
	end

	local tierDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. tier)
	local tier2 = args.liquipediatier2
	local type = args.liquipediatiertype
	local type2 = args.liquipediatiertype2

	if not String.isEmpty(type) then
		local typeDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. type)
		content = content .. '[[' .. typeDisplay .. ' Tournaments|' .. type .. ']]'

		if not String.isEmpty(type2) then
			content = content .. ' ' .. type2
		end

		content = content .. ' ([[' .. tierDisplay .. ' Tournaments|' .. tierDisplay .. ']])'
	else
		content = content .. '[[' .. tierDisplay .. ' Tournaments|' .. tierDisplay .. ']]'

		if not String.isEmpty(tier2) then
			local tier2Display = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. tier2)
			content = content .. ' ([[' .. tier2Display .. ' Tournaments|' .. tier2Display .. ']])'
		end
	end

	content = content .. '[[Category:' .. tierDisplay .. ' Tournaments]]'

	return cell:content(content)
end

function RLLeague:createPrizepool(args)
	local cell = Cell:new('Prize pool'):options({})
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
			return cell:content()
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

	return cell:content(content)
end

function RLLeague:addCustomContent(infobox, args)
	if String.isEmpty(args.map1) then
		return infobox
	end

	infobox:header('Maps', true)

	local maps = {RLLeague:_makeInternalLink(args.map1)}
	local index  = 2

	while not String.isEmpty(args['map' .. index]) do
		table.insert(maps, '&nbsp;• ' ..
			tostring(RLLeague:_createNoWrappingSpan(
				RLLeague:_makeInternalLink(args['map' .. index])
			))
		)
		index = index + 1
	end

	infobox	:centeredCell(unpack(maps))
			:header('Teams', true)
			:cell('Number of teams', args.team_number)

    return infobox
end

function RLLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', RLLeague:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', RLLeague:_concatArgs(args, 'sponsor'))
	Variables.varDefine('tournament_rlcs_premier', args.series == _SERIES_RLCS and 1 or 0)
	Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
	Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))
	Variables.varDefine('tournament_rlcs_premier', args.series == _SERIES_RLCS and 1 or 0)

	-- Legacy tier vars
	Variables.varDefine('tournament_lptier', args.liquipediatier)
	Variables.varDefine('tournament_tier', args.liquipediatiertype or args.liquipediatier)
	Variables.varDefine('tournament_tier2', args.liquipediatier2)
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

function RLLeague:addToLpdb(lpdbData, args)
	lpdbData['game'] = 'rocket league'
	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number
	lpdbData['extradata'] = {
		region = args.region,
		mode = args.mode,
		notabilitymod = args.notabilitymod,
		liquipediatier2 =
			(not String.isEmpty(args.liquipediatiertype) and args.liquipediatier) or args.liquipediatier2,
		liquipediatiertype2 = args.liquipediatiertype2,
		participantsnumber =
			not String.isEmpty(args.team_number) and args.team_number or args.player_number,
		notabilitypercentage = args.edate ~= 'tba' and TournamentNotability.run() or ''
	}

	lpdbData['extradata']['is rlcs'] = Variables.varDefault('tournament_rlcs_premier', 0)
	return lpdbData
end

function RLLeague:_concatArgs(args, base)
	local foundArgs = {args[base] or args[base .. '1']}
	local index = 2
	while not String.isEmpty(args[base .. index]) do
		table.insert(foundArgs, args[base .. index])
		index = index + 1
	end

	return table.concat(foundArgs, ';')
end

function RLLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function RLLeague:_makeInternalLink(content)
	return '[[' .. content .. ']]'
end

return RLLeague
