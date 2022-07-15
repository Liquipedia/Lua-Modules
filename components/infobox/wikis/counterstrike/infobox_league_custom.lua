---
-- @Liquipedia
-- wiki=counterstrike
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
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local MetadataGenerator = require('Module:MetadataGenerator')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _GAME_CS_16 = 'cs16'
local _GAME_CS_CZ = 'cscz'
local _GAME_CS_SOURCE = 'css'
local _GAME_CS_ONLINE = 'cso'
local _GAME_CS_GO = 'csgo'
local _GAME_MOD = 'mod'

local _DATE_TBA = 'tba'

local _TIER_VALVE_MAJOR = 'major'

local _MODE_1v1 = '1v1'
local _MODE_TEAM = 'team'

local _ICON_EPT_CHALLENGER = '[[File:ESL Pro Tour Challenger.png|20x20px|link='
local _ICON_EPT_MASTERS = '[[File:ESL Pro Tour Masters.png|20x20px|link='

local _league

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_league.args['publisherdescription'] = 'metadesc-valve'
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.createLiquipediaTierDisplay = CustomLeague.createLiquipediaTierDisplay

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _league.args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {(args.team_number or '') .. (args.team_slots and ('/' .. args.team_slots) or '')}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {CustomLeague:_createGameCell(args)}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _league.args
	if id == 'customcontent' then
		if not String.isEmpty(args.map1) then
			local game = not String.isEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {CustomLeague:_makeInternalLink(args.map1 .. game .. '|' .. args.map1)}
			local index = 2

			while not String.isEmpty(args['map' .. index]) do
				local map = args['map' .. index]
				table.insert(maps, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						CustomLeague:_makeInternalLink(map .. game .. '|' .. map)
					))
				)
				index = index + 1
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = maps})
		end


		if not String.isEmpty(args.team1) then
			local teams = {CustomLeague:_makeInternalLink(args.team1)}
			local index = 2

			while not String.isEmpty(args['team' .. index]) do
				table.insert(teams, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						CustomLeague:_makeInternalLink(args['team' .. index])
					))
				)
				index = index + 1
			end
			table.insert(widgets, Center{content = teams})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize Pool',
				content = {CustomLeague:_createPrizepool(args)}
			},
		}
	elseif id == 'liquipediatier' then
		table.insert(
			widgets,
			Cell{
				name = '[[File:ESL 2019 icon.png|20x20px|link=|ESL|alt=ESL]] Pro Tour Tier',
				content = {CustomLeague:_createEslProTierCell(args.eslprotier)}
			}
		)
		table.insert(
			widgets,
			Cell{
				name = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox') .. ' Tier',
				content = {CustomLeague:_createValveTierCell(args.valvetier)},
				classes = {'valvepremier-highlighted'}
			}
		)
	end

	mw.getCurrentFrame():extensionTag{name = 'metadescl', MetadataGenerator.tournament(_league.args)}

	return widgets
end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if String.isEmpty(args.game) then
		table.insert(categories, 'Tournaments without game version')
	end

	if not Logic.readBool(args.cancelled) and
		(not String.isEmpty(args.prizepool) and args.prizepool ~= 'Unknown') and
		String.isEmpty(args.prizepoolusd) then
		table.insert(categories, 'Infobox league lacking prizepoolusd')
	end

	if not String.isEmpty(args.prizepool) and String.isEmpty(args.localcurrency) then
		table.insert(categories, 'Infobox league lacking localcurrency')
	end

	if not String.isEmpty(args.sort_date) then
		table.insert(categories, 'Tournaments with custom sort date')
	end

	if not String.isEmpty(args.eslprotier) then
		table.insert(categories, 'ESL Pro Tour Tournaments')
	end

	if not String.isEmpty(args.valvetier) then
		table.insert(categories, 'Valve Sponsored Tournaments')
	end

	return categories
end

function CustomLeague:liquipediaTierHighlighted(args)
	return String.isEmpty(args.valvetier) and Logic.readBool(args.valvemajor)
end

function CustomLeague:createLiquipediaTierDisplay(args)
	local tier = args.liquipediatier

	if String.isEmpty(tier) then
		return nil
	end

	local tierDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay', {tier})
	local tierDisplayLink = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/link', {tier})
	local valvetier = args.valvetier
	local valvemajor = args.valvemajor
	local cstrikemajor = args.cstrikemajor

	local content = tierDisplayLink

	if String.isEmpty(valvetier) and Logic.readBool(valvemajor) then
		local logo = ' [[File:Valve_logo_black.svg|x12px|link=Valve_icon.png|x16px|' ..
			'link=Counter-Strike Majors|Counter-Strike Major]]'
		content = content .. logo
	end

	if Logic.readBool(cstrikemajor) then
		local logo = ' [[File:cstrike-icon.png|x16px|link=Counter-Strike Majors|Counter-Strike Major]]'
		content = content .. logo
	end

	content = content .. '[[Category:' .. tierDisplay.. ' Tournaments]]'

	return content
end

function CustomLeague:_createPrizepool(args)
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
			return nil
	end

	local content
	local prizepool = args.prizepool
	local prizepoolInUsd = args.prizepoolusd
	local localCurrency = args.localcurrency

	if String.isEmpty(prizepool) then
		content = '$' .. (prizepoolInUsd or '0') .. ' ' .. Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD')
	else
		if not String.isEmpty(localCurrency) then
			local converted = Template.safeExpand(
				mw.getCurrentFrame(),
				'Local currency',
				{localCurrency:lower(), prizepool = prizepool}
			)
			Variables.varDefine('prizepoollocal', converted)
			content = converted
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
	Variables.varDefine('tournament_short_name', args.shortname)
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('special_ticker_name', args.tickername_special)
	Variables.varDefine('tournament_organizer', CustomLeague:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', CustomLeague:_concatArgs(args, 'sponsor'))
	if not String.isEmpty(args.date) and args.date:lower() ~= _DATE_TBA then
		Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	end
	if not String.isEmpty(args.sdate) and args.sdate:lower() ~= _DATE_TBA then
		Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
	end
	if not String.isEmpty(args.edate) and args.edate:lower() ~= _DATE_TBA then
		Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))
	end

	Variables.varDefine('raw_sdate', ReferenceCleaner.clean(args.sdate))
	Variables.varDefine('raw_edate', ReferenceCleaner.clean(args.edate))

	if not String.isEmpty(args.edate) and args.edate:lower() ~= _DATE_TBA then
		Variables.varDefine('tournament_date', ReferenceCleaner.clean(args.edate or args.date))
	end
	if not String.isEmpty(args.sdate) and args.sdate:lower() ~= _DATE_TBA then
		Variables.varDefine('tournament_sdate', ReferenceCleaner.clean(args.sdate or args.date))
	end
	if not String.isEmpty(args.edate) and args.edate:lower() ~= _DATE_TBA then
		Variables.varDefine('tournament_edate', Variables.varDefault('tournament_date', ''))
	end

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

	Variables.varDefine('tournament_valve_major',
		(args.valvetier or ''):lower() == _TIER_VALVE_MAJOR and 'true' or args.valvemajor)
	Variables.varDefine('tournament_valve_tier',
		mw.getContentLanguage():ucfirst(args.valvetier or ''):lower())
	Variables.varDefine('tournament_cstrike_major', args.cstrikemajor)

	Variables.varDefine('tournament_mode',
		(not (String.isEmpty(args.individual) and String.isEmpty(args.player_number)))
		and _MODE_1v1 or _MODE_TEAM
	)
	Variables.varDefine('no team result',
		(args.series == 'ESEA Rank S' or
		args.series == 'FACEIT Pro League' or
		args.series == 'Danish Pro League' or
		args.series == 'Swedish Pro League') and 'true' or 'false')

end

function CustomLeague:addToLpdb(lpdbData, args)
	if Logic.readBool(args.charity) then
		lpdbData['prizepool'] = 0
	end

	lpdbData['liquipediatier'] = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/smw/number', {args.liquipediatier})
	lpdbData['publishertier'] = args.valvetier
	lpdbData['maps'] = CustomLeague:_concatArgs(args, 'map')
	lpdbData['game'] = args.game
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData['extradata'] = {
		prizepoollocal = Variables.varDefault('prizepoollocal', ''),
		startdate_raw = Variables.varDefault('raw_sdate', ''),
		enddate_raw = Variables.varDefault('raw_edate', '')

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
			'CSGO Competitions]]'
	elseif args.game == _GAME_MOD then
		content = args.modname
	else
		content = '[[Category:' .. betaTag .. 'Competitions]]'
	end

	content = content .. betaTag

	if String.isEmpty(args.epatch) and not String.isEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	elseif not String.isEmpty(args.epatch) then
		content = content .. '<br> [[' .. args.patch .. ']]' .. '&ndash;' .. '[[' .. args.epatch .. ']]'
	end

	return content
end

function CustomLeague:_createEslProTierCell(eslProTier)
	if String.isEmpty(eslProTier) then
		return nil
	end

	eslProTier = eslProTier:lower()

	if eslProTier == 'national challenger' or eslProTier == 'national championship' then
		return _ICON_EPT_CHALLENGER .. 'ESL National Championships|' ..
			'National Championship]] National Champ.'
	elseif eslProTier == 'international challenger' or eslProTier == 'challenger' then
		return _ICON_EPT_CHALLENGER .. 'ESL Pro Tour|Challenger]] Challenger'
	elseif eslProTier == 'regional challenger' then
		return _ICON_EPT_CHALLENGER .. 'ESL/Pro Tour|Regional Challenger]] Regional Challenger'
	elseif eslProTier == 'masters' then
		return _ICON_EPT_MASTERS .. 'ESL/Pro Tour|Masters]] Masters'
	elseif eslProTier == 'regional masters' then
		return _ICON_EPT_MASTERS .. 'ESL/Pro Tour|Regional Masters]] Regional Masters'
	elseif eslProTier == 'masters championship' then
		return _ICON_EPT_MASTERS .. 'ESL Pro Tour|Masters Championship]] Masters Champ.'
	elseif eslProTier == 'major championship' then
		return '[[File:Valve csgo tournament icon.png|20x20px|link=Majors|Major Championship]] Major Championship'
	end

	return ''
end

function CustomLeague:_createValveTierCell(valveTier)
	if String.isEmpty(valveTier) then
		return nil
	end

	valveTier = valveTier:lower()

	if valveTier == 'major' then
		Variables.varDefine('metadesc-valve', 'Major Championship')
		return '[[Majors|Major Championship]]'
	elseif valveTier == 'major qualifier' then
		Variables.varDefine('metadesc-valve', 'Major Championship main qualifier')
		return '[[Majors|Major Qualifier]]'
	elseif valveTier == 'minor' then
		Variables.varDefine('metadesc-valve', 'Regional Minor Championship')
		return '[[Minors|Minor Championship]]'
	elseif valveTier == 'rmr event' then
		Variables.varDefine('metadesc-valve', 'Regional Major Rankings evnt')
		return '[[Regional Major Rankings|RMR Event]]'
	end

	return valveTier
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
