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

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _TODAY = os.date('%Y-%m-%d')

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

function CustomInjector:parse(id, widgets)
	local args = _league.args
	if id == 'customcontent' then
		if not String.isEmpty(args.player_number) or not String.isEmpty(args.doubles_number) then
			table.insert(widgets, Title{name = 'Player Breakdown'})
			table.insert(widgets, Cell{
				name = 'Number of Players',
				content = {args.player_number}
			})
			table.insert(widgets, Cell{
				name = 'Doubles Players',
				content = {args.doubles_number}
			})
		end
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

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	local sdate = Variables.varDefault('tournament_startdate', _TODAY)
	local edate = Variables.varDefault('tournament_enddate', _TODAY)
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)

	Variables.varDefine('tournament_ticker_name', args.tickername)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_link', mw.title.getCurrentTitle().prefixedText)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData['patch'] = args.patch
	lpdbData['participantsnumber'] = args.team_number or args.player_number
	lpdbData['extradata'] = {
		region = args.region,
		mode = args.mode,
	}

	return lpdbData
end

return CustomLeague
