---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:String')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local PageLink = require('Module:Page')

local _UBISOFT_ICON = '&nbsp;[[File:Ubisoft 2017 lightmode.png|x15px|middle|link=Ubisoft|'
	.. 'Ubisoft Tournaments.]]'
local _TODAY = os.date('%Y-%m-%d', os.time())

local _GAME_SIEGE = 'siege'
local _GAME_VEGAS2 = 'vegas2'

local _args

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

-- local _TIER_UBISOFT_SIX = 'six invitational'
-- local _TIER_UBISOFT_PL = 'pro league'
-- local _TIER_UBISOFT_NATIONAL = 'national league'
-- local _TIER_UBISOFT_MAJOR = 'six major'
-- local _TIER_UBISOFT_MINOR = 'six minor'

function CustomLeague.run(frame)
	local league = League(frame)
    _args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
    league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
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
	local args = _args
	if id == 'customcontent' then
		if not String.isEmpty(args.map1) then
			local game = not String.isEmpty(args.game) and ('/' .. args.game) or ''
			local maps = PageLink.makeInternalLink({}, args.map1, args.map1 .. game)
			local index = 2

			while not String.isEmpty(args['map' .. index]) do
				local map = args['map' .. index]
				table.insert(maps, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						PageLink.makeInternalLink({}, args.map1, args.map1 .. game)
					))
				)
				index = index + 1
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = maps})
		end


		if not String.isEmpty(args.team1) then
			local teams = PageLink.makeInternalLink({}, args.team1)
			local index = 2

			while not String.isEmpty(args['team' .. index]) do
				table.insert(teams, '&nbsp;• ' ..
					tostring(CustomLeague:_createNoWrappingSpan(
						PageLink.makeInternalLink({}, args.team1)
					))
				)
				index = index + 1
			end
			table.insert(widgets, Center{content = teams})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()}
			},
		}
	elseif id == 'liquipediatier' then
		local ubisoftTier = ubisofttier
		if not String.isEmpty(ubisoftTier) then
			widgets = {
				Cell{
					name = 'Ubisoft tier',
					content = {'[[Ubisoft|' .. ubisoftTier .. ']]'},
					classes = {'valvepremier-highlighted'}
				}
			}
		end
		table.insert(widgets, Cell{
			name = 'Liquipedia tier',
			content = {CustomLeague:_createLiquipediaTierDisplay()},
			classes = {String.isEmpty(['ubisoftmajor']) and '' or 'valvepremier-highlighted'}
		})
		table.insert(widgets, Cell{
			name = 'Ubisoft tier',
			content = {Tier['ubisoft'][string.lower(_args.eatier or '')]},
			classes = {'valvepremier-highlighted'}
		})
		return widgets
	end
	return widgets
end

function League:addToLpdb(lpdbData, args)
	lpdbData.maps = CustomLeague:_concatArgs('map')

	lpdbData.publishertier = args.ubisofttier
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.extradata = {
		individual = not String.isEmpty(args.player_number),
	}

	return lpdbData
end

function CustomLeague:_createPrizepool()
	local date
	if String.isEmpty(_args.prizepool) and String.isEmpty(_args.prizepoolusd) then
		return nil
	end
	if not String.isEmpty(_args.currency_rate) then
		date = _args.currency_date
	end


	return PrizePoolCurrency._get({
		prizepool = _args.prizepool,
		prizepoolusd = _args.prizepoolusd,
		currency = _args.localcurrency,
		rate = _args.currency_rate,
		date = date or Variables.varDefault('tournament_enddate', _TODAY),
	})
end

function CustomLeague:_createLiquipediaTierDisplay()
	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or ''
	if String.isEmpty(tier) then
		return nil
	end

	--clean tier from unallowed values
	--convert from text (old entries) to numbers
	local tierText = Tier.text[tier]
	local hasInvalidTier = tierText == nil
	local hasTypeSetAsTier
	--the following converts a tier that should be a tiertype
	if hasInvalidTier then
		local tempTypeForCheck = Tier.numberToType[tier] or tier
		tempTypeForCheck = Tier.types[string.lower(tempTypeForCheck)]
		if tempTypeForCheck then
			hasTypeSetAsTier = true
			hasInvalidTier = nil
			if String.isEmpty(tierType) then
				tierType = tempTypeForCheck
			end
		end
	end
	tierText = tierText or tier

	local hasInvalidTierType = false

	local tierDisplay = '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		.. '[[Category:' .. tierText .. ' Tournaments]]'


	if not String.isEmpty(tierType) then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil
		local tierTypeDIsplay
		tierTypeDIsplay = '[[' .. tierType .. ' Tournaments|' .. tierType .. ']]'
			.. '[[Category:' .. tierType .. ' Tournaments]]'
		if not hasTypeSetAsTier or tierType ~= tierTypeDIsplay  then
			tierDisplay = tierTypeDIsplay .. '&nbsp;(' .. tierDisplay .. ')'
		end
	end

	tierDisplay = tierDisplay ..
		(_args['ubisoftmajor'] == 'true' and _UBISOFT_ICON or '') ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '') ..
		(hasTypeSetAsTier and '[[Category:Pages with Tiertype set as Tier]]' or '')

	Variables.varDefine('tournament_tiertype', tierType)
	--overwrite wiki var `tournament_liquipediatiertype` to allow `args.tiertype` as alias entry point for tiertype
	return tierDisplay
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', _args.liquipediatiertype or '')
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_prizepool', _args.prizepool or '')
	Variables.varDefine('tournament_mode', _args.mode or '')
	Variables.varDefine('tournament_currency', _args.currency or '')
	
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

function CustomLeague.getWikiCategories(args)
	local categories = {}
	if not String.isEmpty(args.player_number) or not String.isEmpty(args.participants_number) then
		table.insert(categories, 'Individual Tournaments')
	end
	if not String.isEmpty(args.ubisofttier) or args['ubisoftmajor'] == 'true' then
		table.insert(categories, 'Ubisoft Tournaments')
	end
	return categories
end

function CustomLeague:_createGameCell(args)
	if String.isEmpty(args.game) and String.isEmpty(args.patch) then
		return nil
	end

	local content

	local betaTag = not String.isEmpty(args.beta) and 'Beta&nbsp;' or ''

	if args.game == _GAME_SIEGE then
		content = '[[Siege]][[Category:' .. betaTag .. 'Siege Competitions]]'
	elseif args.game == _GAME_VEGAS2 then
		content = '[[Vegas 2]][[Category:' .. betaTag .. 'Vegas 2 Competitions]]'
	else
		content = '[[Category:Tournaments without game version]]'
	end

	content = content .. betaTag

	if String.isEmpty(args.epatch) and not String.isEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	elseif not String.isEmpty(args.epatch) then
		content = content .. '<br> [[' .. args.patch .. ']] ' .. '&ndash;' .. ' [[' .. args.epatch .. ']]'
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
