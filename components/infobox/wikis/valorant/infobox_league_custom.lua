---
-- @Liquipedia
-- wiki=valorant
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
local RIOT_SPONSORED = '[[File:Riot Games Tier Icon.png|x18px|link=Riot Games|Tournament supported by Riot Games.]]'

local _TODAY = os.date('%Y-%m-%d', os.time())

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

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
		content = (args.team_number)
	})
	table.insert(widgets, Cell{
		name = 'Patch',
		content = {CustomLeague:_createPatchCell(args)}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _args
	if id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local maps = {}

			for _, map in ipairs(_league:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map)
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
		local tierDisplay = CustomLeague:_createLiquipediaTierDisplay()
		local class
		if args['riot-sponsored'] == 'true' then
			tierDisplay = (tierDisplay or '').. '&nbsp;' .. RIOT_SPONSORED
			class = {'valvepremier-highlighted'}
		end
		return {
			Cell{
				name = 'Liquipedia Tier',
				content = {tierDisplay},
				classes = class
			}
		}
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)	
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')
	lpdbData.participantsnumber = args.team_number
	lpdbData.liquipediatiertype = args.liquipediatiertype
	lpdbData.publishertier = args['riotpremier'] == 'true' and 'major' or args['riot-sponsored'] == 'true' and 'Sponsored'
	lpdbData.extradata = {
		prizepoollocal = args.prizepoollocal or 'false',
		startdate_raw = CustomLeague:_standardiseRawDate(args.sdate or args.date),
		enddate_raw = CustomLeague:_standardiseRawDate(args.edate or args.date),
		female = args.female or 'false',
		region = args.country or 'false',
		icon_darkmode = args.icon_darkmode or args.icon,
		banner_darkmode = args.banner_darkmode or args.banner,
	}
	return lpdbData
end


function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end
	local content

	if String.isEmpty(args.epatch) and not String.isEmpty(args.patch) then
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]'
	elseif not String.isEmpty(args.epatch) then
		content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]' .. '&ndash;' ..
		'[[Patch ' .. args.epatch .. '|'.. args.epatch .. ']]'
	end

	return content
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
	dateString = dateString:gsub('%-XX', '-??')
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

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('tournament_prizepool', _args.prizepool or '')
	Variables.varDefine('tournament_name', _args.name or '')
	Variables.varDefine('tournament_short_name', _args.shortname or '')
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('special_ticker_name', _args.tickername_special or '')
	Variables.varDefine('tournament_icon', _args.icon or '')
	Variables.varDefine('tournament_type', _args.type or '')
	Variables.varDefine('tournament_series', _args.series or '')
	Variables.varDefine('tournament_riot_premier', _args.riotpremier or '')
	Variables.varDefine('tournament_riot_tier', _args.riotpremier or '')
	Variables.varDefine('tournament_mode', _args.individual or '')
	Variables.varDefine('patch', _args.patch or '')

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

function CustomLeague:getWikiCategories(args)
	local categories = {}
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype
	local female = args.female

	if String.isNotEmpty(tier) and String.isNotEmpty(Tier.text[tier]) then
		table.insert(categories, Tier.text[tier]  .. ' Tournaments')
	end

	if String.isNotEmpty(tierType) and String.isNotEmpty(Tier.text[tierType]) then
		table.insert(categories, Tier.text[tierType] .. ' Tournaments')
	end
	
	if String.isNotEmpty(female) then
		table.insert(categories, 'Female Tournaments')
	end
	return categories
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
