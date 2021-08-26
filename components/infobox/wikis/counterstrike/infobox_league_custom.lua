---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local Cell = require('Module:Infobox/Cell')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Class = require('Module:Class')
local Logic = require('Module:Logic')

local CustomLeague = Class.new()

local _GAME_CS_16 = 'cs16'
local _GAME_CS_CZ = 'cscz'
local _GAME_CS_SOURCE = 'css'
local _GAME_CS_ONLINE = 'cso'
local _GAME_CS_GO = 'csgo'
local _GAME_MOD = 'mod'

function CustomLeague.run(frame)
	local league = League(frame)
	league.addCustomCells = CustomLeague.addCustomCells
	league.createTier = CustomLeague.createTier
	league.createPrizepool = CustomLeague.createPrizepool
	league.addCustomContent = CustomLeague.addCustomContent
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb

	return league:createInfobox(frame)
end

function CustomLeague:addCustomCells(infobox, args)
	infobox:cell('Game', CustomLeague:_createGameCell(args))
	return infobox
end

function CustomLeague:createTier(args)
	local cell =  Cell:new('Liquipedia Tier'):options({})

	local content = ''

	local tier = args.liquipediatier

	if String.isEmpty(tier) then
		return cell:content()
	end

	local tierDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/link', { tier })
	local valvetier = args.valvetier
	local valvemajor = args.valvetier
	local cstrikemajor = args.cstrikemajor

	content = content .. tierDisplay

	if String.isEmpty(valvetier) and Logic.readBool(valvemajor) then
		cell:addClass('valvepremier-highlighted')
		local logo = ' [[File:Valve_logo_black.svg|x12px|link=Valve_icon.png|x16px|' .. 
			'link=Counter-Strike Majors|Counter-Strike Major]]'
		content = content .. logo
	end

	if Logic.readBool(cstrikemajor) then
		local logo = ' [[File:cstrike-icon.png|x16px|link=Counter-Strike Majors|Counter-Strike Major]]'
		content = content .. logo
	end

	content = content .. '[[Category:' .. tierDisplay .. ' Tournaments]]'

	return cell:content(content)
end

function CustomLeague:createPrizepool(args)
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

function CustomLeague:addCustomContent(infobox, args)
	if not String.isEmpty(args.map1) then
		infobox:header('Maps', true)

		local maps = {CustomLeague:_makeInternalLink(args.map1)}
		local index  = 2

		while not String.isEmpty(args['map' .. index]) do
			table.insert(maps, '&nbsp;• ' ..
				tostring(CustomLeague:_createNoWrappingSpan(
					CustomLeague:_makeInternalLink(args['map' .. index])
				))
			)
			index = index + 1
		end
		infobox	:centeredCell(unpack(maps))
	end

	infobox	:header('Teams', not String.isEmpty(args.team_number))
			:cell('Number of teams', args.team_number)

    return infobox
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', CustomLeague:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', CustomLeague:_concatArgs(args, 'sponsor'))
	Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
	Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))

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
end

function CustomLeague:addToLpdb(lpdbData, args)
	if not String.isEmpty(args.liquipediatiertype) then
		lpdbData['liquipediatier'] = args.liquipediatiertype
	end

	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData['extradata'] = {
		region = args.region,
		mode = args.mode,
		liquipediatier2 =
			(not String.isEmpty(args.liquipediatiertype) and args.liquipediatier) or args.liquipediatier2,
		liquipediatiertype2 = args.liquipediatiertype2,
		participantsnumber =
			not String.isEmpty(args.team_number) and args.team_number or args.player_number,
	}

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

function CustomLeague:_createGameCell(args)
	if String.isEmpty(args.game) and String.isEmpty(args.patch) then
		return nil
	end

	local content

	local betaTag = not String.isEmpty(args.beta) and 'Beta&nbsp;' or ''

	if args.game == _GAME_CS_16 then
		content = '[[Counter-Strike]][[Category:' .. betaTag .. 'CS1.6 Competitions]]'
	elseif args.game == _GAME_CS_CZ then
		content = '[[Counter-Strike: Condition Zero|Condition Zero]][[Category:' .. betaTag .. 'CSCZ Competitions]]'
	elseif args.game == _GAME_CS_SOURCE then
		content = '[[Counter-Strike: Source|Source]][[Category:' .. betaTag .. 'CSS Competitions]]'
	elseif args.game == _GAME_CS_ONLINE then
		content = '[[Counter-Strike Online|Online]][[Category:' .. betaTag .. 'CSO Competitions]]'
	elseif args.game == _GAME_CS_GO then
		content = '[[Counter-Strike: Global Offensive|Global Offensive]][[Category:' .. betaTag ..
			'CSGO Competitions]]|[[Category:{{#if:{{{beta|}}}|Beta&nbsp;}}Competitions]]'
	else
		content = args.modname
	end

	content = content .. betaTag

	if String.isEmpty(args.epatch) and not String.isEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	elseif not String.isEmpty(args.epatch) then
		content = content .. '<br> [[' .. args.patch .. ']]' .. '&ndash;' .. '[[' .. args.epatch .. ']]'
	end

	return content
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
