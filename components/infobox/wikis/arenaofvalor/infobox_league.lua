---
-- @Liquipedia
-- wiki=arenaofvalor
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
local PrizePoolCurrency = require('Module:Prize pool currency')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _game

local _TODAY = os.date('%Y-%m-%d', os.time())
local _GAME = mw.loadData('Module:GameVersion')

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					CustomLeague._getGameVersion()
				}},
			}
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()}
			},
		}
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {CustomLeague:_createTierDisplay()},
				classes = {_args['garena-sponsored'] == 'true' and 'valvepremier-highlighted' or ''},
			},
		}
	elseif id == 'customcontent' then
		if _args.player_number then
			table.insert(widgets, Title{name = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {_args.player_number}})
		end

		--teams section
		if _args.team_number then
			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = _game or args.game
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	Variables.varDefine('tournament_game', _game or _args.game)
	Variables.varDefine('tournament_publishertier', _args['garena-sponsored'])
	--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
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

function CustomLeague:_createTierDisplay()
	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or _args.tiertype or ''
	if String.isEmpty(tier) then
		return nil
	end

	local tierText = Tier['text'][tier]
	local hasInvalidTier = tierText == nil
	tierText = tierText or tier

	local hasInvalidTierType = false

	local output = '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		.. '[[Category:' .. tierText .. ' Tournaments]]'

	if not String.isEmpty(tierType) then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil
		tierType = '[[' .. tierType .. ' Tournaments|' .. tierType .. ']]'
			.. '[[Category:' .. tierType .. ' Tournaments]]'
		output = tierType .. '&nbsp;(' .. output .. ')'
	end

	output = output ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '')
	return output
end

return CustomLeague
