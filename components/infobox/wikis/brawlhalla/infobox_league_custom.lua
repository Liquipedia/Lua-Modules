---
-- @Liquipedia
-- wiki=brawlhalla
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

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _MODES = {
	['1v1'] = '1v1',
	['2v2'] = '2v2',
	['3v3'] = '3v3',
}
_MODES.solo = _MODES['1v1']
_MODES.singles = _MODES['1v1']
_MODES.duo = _MODES['2v2']
_MODES.doubles = _MODES['2v2']
_MODES.default = _MODES['1v1']

local _league

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _league.args
	table.insert(widgets, Cell{
		name = 'Mode',
		content = {CustomLeague:_displayMode(args.mode)}
	})
	table.insert(widgets, Cell{
		name = 'Misc Mode:',
		content = {args.miscmode}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _league.args
	if id == 'customcontent' then
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
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia Tier',
				content = {CustomLeague:_createLiquipediaTierDisplay(args)}
			},
		}
	end
	return widgets
end

function CustomLeague:_createLiquipediaTierDisplay(args)
	local tier = args.liquipediatier or ''
	local tierType = args.liquipediatiertype or ''

	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierString(tierString)
		local tierText = Tier.text[tierString]
		if not tierText then
			table.insert(_league.warnings, tierString .. ' is not a known Liquipedia Tier/Tiertype')
			return ''
		else
			return '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		end
	end
	local tierDisplay = buildTierString(tier)
	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType) .. '&nbsp;(' .. tierDisplay .. ')'
	end

	return tierDisplay
end

function CustomLeague:_createPrizepool(args)
	if String.isEmpty(args.prizepool) and String.isEmpty(args.prizepoolusd) then
		return nil
	end

	local date
	if String.isNotEmpty(args.currency_rate) then
		date = args.currency_date
	end

	return PrizePoolCurrency._get({
		prizepool = args.prizepool,
		prizepoolusd = args.prizepoolusd,
		currency = args.localcurrency,
		rate = args.currency_rate,
		date = date or Variables.varDefault('tournament_enddate', _TODAY),
	})
end

function CustomLeague:_displayMode(mode)
	if String.isEmpty(mode) then
		return _MODES.default
	end

	return _MODES[mode:lower()] or _MODES.default 
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('tournament_ticker_name', args.tickername)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData['extradata'] = {
		region = args.region,
		mode = args.mode,
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
