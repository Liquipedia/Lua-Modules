---
-- @Liquipedia
-- wiki=ageofempires
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
local GameLookup = require('Module:GameLookup')
local PrizePool = require('Module:Prize pool currency')
local MapMode = require('Module:MapMode')

local CustomLeague = Class.new()

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
	local sponsors = mw.text.split(args.sponsors, ',', true)

	infobox:cell('Sponsor', table.concat(sponsors, '&nbsp;•'))
	infobox:cell('Game', CustomLeague:_makeInternalLink(GameLookup.getName({args.game})) .. (args.beta and ' Beta' or ''))
	infobox:cell('Version', CustomLeague:_makeVersionLink(args))
	infobox:cell('Patch', CustomLeague:_makePatchLink(args))
	infobox:cell('Voobly & WololoKingdoms', args.voobly)
	infobox:fcell(Cell:new('Game mode')
					:options({})
					:content(unpack(CustomLeague:_getGameModes(args)))
					:make())
	infobox:cell('Number of teams', args.team_number)
	infobox:cell('Number of players', args.player_number)

	if League:shouldStore(args) then
		infobox:categories(GameLookup.getName({args.game}) .. (args.beta and ' Beta' or '') .. 'Competitions')
	end

	return infobox
end

function CustomLeague:createTier(args)
	local cell =  Cell:new('Liquipedia Tier'):options({})

	local content = ''

	local tier = args.liquipediatier

	if String.isEmpty(tier) then
		return cell:content()
	end

	local tierDisplay = Template.safeExpand(mw.getCurrentFrame(),
										'TierDisplay/link',
										{ tier, GameLookup.getName({args.game})})
	local type = args.liquipediatiertype

	if not String.isEmpty(type) then
		local typeDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/link', type)
		content = content .. typeDisplay .. ' (' .. tierDisplay .. ')'
	else
		content = content .. tierDisplay
	end

	return cell:content(content)
end

function CustomLeague:createPrizepool(args)
	local cell = Cell:new('Prize pool'):options({})
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
			return cell:content()
	end

	local date
	if not String.isEmpty(args.currency_rate) then
		date = args.currency_date
	else
		date = args.edate or args.date
	end

	local content = PrizePool.get({
			prizepool = args.prizepool,
			prizepoolusd = args.prizepoolusd,
			currency = args.localcurrency,
			rate = args.currency_rate,
			date = date
		}
	)

	return cell:content(content)
end

function CustomLeague:addCustomContent(infobox, args)
	if not String.isEmpty(args.map1) then
		infobox:header('Maps', true)

		local map1mode = ''
		if not String.isEmpty(args.map1mode) then
			map1mode = MapMode.get({args.map1mode})
		end

		local maps = {CustomLeague:_makeInternalLink(args.map1 .. map1mode)}
		local index  = 2

		while not String.isEmpty(args['map' .. index]) do
			local mapmode = ''
			if not String.isEmpty(args['map' .. index .. 'mode']) then
				mapmode = MapMode.get({args['map' .. index .. 'mode']})
			end
			table.insert(maps, '&nbsp;• ' ..
				tostring(CustomLeague:_createNoWrappingSpan(
					CustomLeague:_makeInternalLink(args['map' .. index] .. mapmode)
				))
			)
			index = index + 1
		end
		infobox	:centeredCell(unpack(maps))
	end

	if not String.isEmpty(args.team1) then
		infobox:header('Teams', true)

		local teams = {CustomLeague:_makeInternalLink(args.team1)}
		local index  = 2

		while not String.isEmpty(args['team' .. index]) do
			table.insert(teams, '&nbsp;• ' ..
				tostring(CustomLeague:_createNoWrappingSpan(
					CustomLeague:_makeInternalLink(args['team' .. index])
				))
			)
			index = index + 1
		end
		infobox	:centeredCell(unpack(teams))
	end

    return infobox
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('game', GameLookup.getName({args.game}))

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
	if String.isEmpty(args.tickername) then
		lpdbData['tickername'] = args.name
	end

	lpdbData['sponsors'] = args.sponsors
	lpdbData['maps'] = CustomLeague:_concatArgs(args, 'map')

	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData['extradata'] = {
		region = args.region,
		mode = not String.empty(args.gamemode) and args.gamemode or 'rm',
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

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague:_makeInternalLink(content)
	return '[[' .. content .. ']]'
end

function CustomLeague:_makeVersionLink(args)
	if String.isEmpty(args.version) then return nil end
	local content = GameLookup.getName({args.game}) .. '/' .. args.version
	content = content .. '|' .. args.version

	return CustomLeague:_makeInternalLink(content)
end

function CustomLeague:_makePatchLink(args)
	if String.isEmpty(args.patch) then return nil end

	local content
	local patch =  GameLookup.getName({args.game}) .. '/' .. args.version .. '/' .. args.patch
	patch = patch .. '|' .. args.patch
	content = CustomLeague:_makeInternalLink(patch)

	if not String.isEmpty(args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		local epatch = GameLookup.getName({args.game}) .. '/' .. args.version .. '/' .. args.epatch
		epatch = epatch .. '|' .. args.epatch
		epatch = CustomLeague:_makeInternalLink(epatch)
		content = content .. epatch
	end

	return content
end

function CustomLeague:_getGameModes(args)
	if String.isEmpty(args.gamemode) then return nil end

	local gameModes = mw.text.split(args.gamemode, ',', true)
	table.foreach(gameModes,
		function(index, mode)
			gameModes[index] = CustomLeague:_makeInternalLink(
								Template.safeExpand(mw.getCurrentFrame(),
								'GamemodeLookup',
								{mode}))
		end
	)

	return gameModes
end

return CustomLeague
