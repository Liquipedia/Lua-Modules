---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local MapModes = require('Module:MapModes')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _game

local _GAME = mw.loadData('Module:GameVersion')

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
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
function CustomLeague:addToLpdb(lpdbData, args)
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

	lpdbData.extradata.maps = Json.stringify(maps)
	lpdbData.extradata.individual = not String.isEmpty(args.player_number)

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	if _args.player_number then
		Variables.varDefine('tournament_mode', 'solo')
	end
	Variables.varDefine('tournament_game', _game or _args.game)

	Variables.varDefine('tournament_publishertier', _args['hcs-sponsored'])

	--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_tier', _args.liquipediatier)
	Variables.varDefine('tournament_tiertype', _args.liquipediatiertype)
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

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(_args['hcs-sponsored'])
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
