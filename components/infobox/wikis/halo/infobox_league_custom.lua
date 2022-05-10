---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:String')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local PageLink = require('Module:Page')
local MapModes = require('Module:MapModes')
local Json = require('Module:Json')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _game

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

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Number of teams', content = {_args.team_number}},
		Cell{name = 'Number of players', content = {_args.player_number}},
	}
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					CustomLeague._getGameVersion()
				}},
			}
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {CustomLeague:_createTierDisplay()},
				classes = {_args['hcs-sponsored'] == 'true' and 'valvepremier-highlighted' or ''},
			},
		}
	elseif id == 'customcontent' then
		--maps
		if not String.isEmpty(_args.map1) then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeMapList()})
		end
	end
	return widgets
end

--store maps
function League:addToLpdb(lpdbData, args)
	local maps = {}
	local index = 1
	while not String.isEmpty(args['map' .. index]) do
		local modes = {}
		if not String.isEmpty(args['map' .. index .. 'modes']) then
			local tempModesList = mw.text.split(args['map' .. index .. 'modes'], ',')
			for _, item in ipairs(tempModesList) do
				local currentMode = MapModes.clean({mode = item or ''})
				if not String.isEmpty(currentMode) then
					table.insert(modes, currentMode)
				end
			end
		end
		table.insert(maps, {
			map = args['map' .. index],
			modes = modes
		})
		index = index + 1
	end

	lpdbData.maps = CustomLeague:_concatArgs('map')

	lpdbData.game = _game or args.game
	lpdbData.publishertier = args['hcs-sponsored']
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.extradata = {
		maps = Json.stringify(maps),
		individual = not String.isEmpty(args.player_number),
	}

	return lpdbData
end

function League:defineCustomPageVariables()
	if _args.player_number then
		Variables.varDefine('tournament_mode', 'solo')
	end
	Variables.varDefine('tournament_game', _game or _args.game)

	Variables.varDefine('tournament_publishertier', _args['hcs-sponsored'])

	--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague:_concatArgs(base)
	local firstArg = _args[base] or _args[base .. '1']
	if String.isEmpty(firstArg) then
		return nil
	end
	local foundArgs = {mw.ext.TeamLiquidIntegration.resolve_redirect(firstArg)}
	local index = 2
	while not String.isEmpty(_args[base .. index]) do
		table.insert(foundArgs,
			mw.ext.TeamLiquidIntegration.resolve_redirect(_args[base .. index])
		)
		index = index + 1
	end

	return table.concat(foundArgs, ';')
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

	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_tiertype', tierType)
	return output
end

function CustomLeague._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
end

function CustomLeague:_makeMapList()
	local date = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', os.date('%Y-%m-%d'))
	local map1 = PageLink.makeInternalLink({}, _args['map1'])
	local map1Modes = CustomLeague:_getMapModes(_args['map1modes'], date)

	local foundMaps = {
		tostring(CustomLeague:_createNoWrappingSpan(map1Modes .. map1))
	}
	local index = 2
	while not String.isEmpty(_args['map' .. index]) do
		local currentMap = PageLink.makeInternalLink({}, _args['map' .. index])
		local currentModes = CustomLeague:_getMapModes(_args['map' .. index .. 'modes'], date)

		table.insert(
			foundMaps,
			'&nbsp;• ' .. tostring(CustomLeague:_createNoWrappingSpan(currentModes .. currentMap))
		)
		index = index + 1
	end
	return foundMaps
end

function CustomLeague:_getMapModes(modesString, date)
	if String.isEmpty(modesString) then
		return ''
	end
	local display = ''
	local tempModesList = mw.text.split(modesString, ',')
	for _, item in ipairs(tempModesList) do
		local mode = MapModes.clean(item)
		if not String.isEmpty(mode) then
			if display ~= '' then
				display = display .. '&nbsp;'
			end
			display = display .. MapModes.get({mode = mode, date = date, size = 15})
		end
	end
	return display .. '&nbsp;'
end

function CustomLeague:_makeBasedListFromArgs(base)
	local firstArg = _args[base .. '1']
	local foundArgs = {PageLink.makeInternalLink({}, firstArg)}
	local index = 2

	while not String.isEmpty(_args[base .. index]) do
		local currentArg = _args[base .. index]
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, currentArg)
			))
		)
		index = index + 1
	end

	return foundArgs
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
