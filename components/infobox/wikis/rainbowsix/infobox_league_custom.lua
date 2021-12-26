---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local PageLink = require('Module:Page')
local PrizePoolCurrency = require('Module:Prize pool currency')

local _TODAY = os.date('%Y-%m-%d', os.time())

local _DEFAULT_PLATFORM = 'PC'
local _PLATFORM_ALIAS = {
	computer = 'PC',
	desktop = 'PC',
	xone = 'Xbox',
	['xbox one'] = 'Xbox',
	['x one'] = 'Xbox',
	xb = 'Xbox',
	one = 'Xbox',
	ps = 'Playstation',
	ps4 = 'Playstation',
	['ps 4'] = 'Playstation',
	['playstation 4'] = 'Playstation',
}

local _GAME_SIEGE = 'siege'
local _GAME_VEGAS2 = 'vegas2'

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _UBISOFT_TIERS = {
	si = 'Six Invitational',
	pl = 'Pro League',
	cl = 'Challenger League',
	national = 'National',
	major = 'Six Major',
	minor = 'Minor',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb

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
		name = 'Platform',
		content = {CustomLeague:_createPlatformCell(args)}
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
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(_league:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()}
			},
		}
	elseif id == 'liquipediatier' then
		widgets = {
			Cell{
				name = 'Liquipedia tier',
				content = {CustomLeague:_createLiquipediaTierDisplay()},
			}
		}
		if String.isNotEmpty(args.ubisofttier) and _UBISOFT_TIERS[args.ubisofttier:lower()] then
			table.insert(widgets,
				Cell{
					name = 'Ubisoft tier',
					content = {'[['.._UBISOFT_TIERS[args.ubisofttier:lower()]..']]'},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase('map'), ';')

	lpdbData.publishertier = args.ubisofttier
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
		startdatetext = CustomLeague:_standardiseRawDate(args.sdate or args.date),
		enddatetext = CustomLeague:_standardiseRawDate(args.edate or args.date),
	}

	return lpdbData
end

function CustomLeague:_standardiseRawDate(dateString)
	-- Length 7 = YYYY-MM
	-- Length 10 = YYYY-MM-??
	if String.isEmpty(dateString) or (#dateString ~= 7 and #dateString ~= 10) then
		return ''
	end

	if #dateString == 7 then
		dateString = dateString .. '-??'
	end
	dateString = dateString:gsub('-XX', '-??')
	return dateString
end

function CustomLeague:_createPrizepool()
	if String.isEmpty(_args.prizepool) and String.isEmpty(_args.prizepoolusd) then
		return nil
	end
	local date
	if String.isNotEmpty(_args.currency_rate) then
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

	local function buildTierString(tierString)
		local tierText = Tier.text[tierString]
		if not tierText then
			table.insert(_league._warnings, tierString .. ' is not a known Liquipedia Tier')
			return ''
		else
			return '[[' .. tierText .. ' Tournaments|' .. tierText .. ']][[Category:' .. tierText .. ' Tournaments]]'
		end
	end

	local tierDisplay = buildTierString(tier)

	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType) .. '&nbsp;(' .. tierDisplay .. ')'
	end

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

function CustomLeague:_createGameCell(args)
	if String.isEmpty(args.game) and String.isEmpty(args.patch) then
		return nil
	end

	local content

	local betaTag = String.isNotEmpty(args.beta) and 'Beta&nbsp;' or ''

	if args.game == _GAME_SIEGE then
		content = '[[Siege]][[Category:' .. betaTag .. 'Siege Competitions]]'
	elseif args.game == _GAME_VEGAS2 then
		content = '[[Vegas 2]][[Category:' .. betaTag .. 'Vegas 2 Competitions]]'
	else
		content = '[[Category:Tournaments without game version]]'
	end

	content = content .. betaTag

	if String.isNotEmpty(args.epatch)  then
		content = content .. '<br> [[' .. args.patch .. ']] &ndash; [[' .. args.epatch .. ']]'
	elseif String.isNotEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	end

	return content
end

function CustomLeague:_createPlatformCell(args)
	if String.isEmpty(args.platform) then
		args.platform = _DEFAULT_PLATFORM
	end

	local platform = _PLATFORM_ALIAS[args.platform] or args.platform

	if String.isNotEmpty(platform) then
		return '[[' .. platform .. ']][[Category:' .. platform .. ' Tournaments]]'
	end

	return nil
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
