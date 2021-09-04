---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Class = require('Module:Class')
local GameLookup = require('Module:GameLookup')
local PrizePool = require('Module:Prize pool currency')
local MapMode = require('Module:MapMode')
local GameModeLookup = require('Module:GameModeLookup')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local Page = require('Module:Page')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _league

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.addCustomCells = CustomLeague.addCustomCells
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _league.args

	table.insert(widgets, Cell{
		name = 'Game',
		content = {Page.makeInternalLink(GameLookup.getName({args.game})) .. (args.beta and ' Beta' or '')}
	})

	table.insert(widgets, Cell{
		name = 'Version',
		content = {CustomLeague:_makeVersionLink(args)}
	})

	table.insert(widgets, Cell{
		name = 'Patch',
		content = {CustomLeague:_makePatchLink(args)}
	})

	table.insert(widgets, Cell{
		name = 'Voobly & WololoKingdoms',
		content = {args.voobly}
	})

	table.insert(widgets, Cell{
		name = 'Game mode',
		content = CustomLeague:_getGameModes(args)
	})

	table.insert(widgets, Cell{
		name = 'Number of teams',
		content = {args.team_number}
	})

	table.insert(widgets, Cell{
		name = 'Number of players',
		content = {args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _league.args

	if id == 'customcontent' then
		if not String.isEmpty(args.map1) then
			local map1mode = ''
			if not String.isEmpty(args.map1mode) then
				map1mode = MapMode.get({args.map1mode})
			end

			local maps = {Page.makeInternalLink(args.map1, args.map1 .. map1mode)}
			local index  = 2

			while not String.isEmpty(args['map' .. index]) do
				local mapmode = ''
				if not String.isEmpty(args['map' .. index .. 'mode']) then
					mapmode = MapMode.get({args['map' .. index .. 'mode']})
				end
				table.insert(maps, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						Page.makeInternalLink(args['map' .. index], args['map' .. index] .. mapmode)
					))
				)
				index = index + 1
			end

			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = maps})
		end

		if not String.isEmpty(args.team1) then
			local teams = {Page.makeInternalLink(args.team1)}
			local index  = 2

			while not String.isEmpty(args['team' .. index]) do
				table.insert(teams, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						Page.makeInternalLink(args['team' .. index])
					))
				)
				index = index + 1
			end

			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Center{content = teams})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool(args)}
			}
		}
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Tier',
				content = {CustomLeague:_createTier(args)}
			}
		}
	elseif id == 'organizer' then
		local sponsors = mw.text.split(args.sponsors, ',', true)
		table.insert(widgets, Cell{
			name = 'Sponsor(s)',
			content = table.concat(sponsors, '&nbsp;•')
		})
	end

	return widgets
end


function CustomLeague:getWikiCategories(args)
	local categories = {}

	if not (String.isEmpty(args.individual) and String.isEmpty(args.player_number)) then
		table.insert(categories, 'Individual Tournaments')
	end

	if String.isEmpty(args.game) then
		table.insert(categories, 'Tournaments without game version')
	else
		table.insert(categories, GameLookup.getName({args.game}) .. (args.beta and ' Beta' or '') .. 'Competitions')
	end

	return categories
end

function CustomLeague:_createTier(args)
	local cell = {name = 'Liquipedia Tier'}

	local content = ''

	local tier = args.liquipediatier

	if String.isEmpty(tier) then
		return cell
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

	cell.content = {content}
	return cell
end

function CustomLeague:_createPrizepool(args)
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
			return nil
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

	return content
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_organizer', CustomLeague:_concatArgs(args, 'organizer'))
	Variables.varDefine('tournament_sponsors', CustomLeague:_concatArgs(args, 'sponsor'))
	Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
	Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))

	Variables.varDefine('game', GameLookup.getName({args.game}))
	Variables.varDefine('tournament_patch', args.patch)
	Variables.varDefine('patch', args.patch)
	Variables.varDefine('tournament_mode',
		(not String.isEmpty(args.mode)) and args.mode or
		(not String.isEmpty(args.team_number)) and 'team' or
		'1v1'
	)
	Variables.varDefine('tournament_headtohead', args.headtohead)

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

function CustomLeague:_makeVersionLink(args)
	if String.isEmpty(args.version) then return nil end
	local content = GameLookup.getName({args.game}) .. '/' .. args.version
	content = content .. '|' .. args.version

	return Page.makeInternalLink(content)
end

function CustomLeague:_makePatchLink(args)
	if String.isEmpty(args.patch) then return nil end

	local content
	local patch =  GameLookup.getName({args.game}) .. '/' .. args.version .. '/' .. args.patch
	content = Page.makeInternalLink(patch, args.patch)

	if not String.isEmpty(args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		local epatch = GameLookup.getName({args.game}) .. '/' .. args.version .. '/' .. args.epatch
		epatch = Page.makeInternalLink(epatch, args.epatch)
		content = content .. epatch
	end

	return content
end

function CustomLeague:_getGameModes(args)
	if String.isEmpty(args.gamemode) then
		return Page.makeInternalLink(GameModeLookup.getDefault(args.game or ''))
	end

	local gameModes = mw.text.split(args.gamemode, ',', true)
	table.foreach(gameModes,
		function(index, mode)
			gameModes[index] = Page.makeInternalLink(GameModeLookup.getName(mode) or '')
		end
	)

	return gameModes
end

return CustomLeague
