---
-- @Liquipedia
-- wiki=tft
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Class = require('Module:Class')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local _args

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local GAME_MODE = mw.loadData('Module:GameMode')
local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Tournament supported by Riot Games]]'

function CustomLeague.run(frame)
	local league = League(frame)
	
	_args = league.args
	
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay
	
	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.participants_number}
	})
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Patch',
			content = {CustomLeague:_createPatchCell(_args)}
		})
		table.insert(widgets, Cell{
			name = 'Game mode',
			content = {CustomLeague._getGameMode()}
		})
	end

	return widgets
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['riot-sponsored'])
end

function CustomLeague:appendLiquipediatierDisplay()
	if Logic.readBool(_args['riot-sponsored']) then
		return ' ' .. RIOT_ICON
	end
	return ''
end

function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	local content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]'

	if String.isEmpty(args.epatch) then
		return content
	end

	return content .. ' &ndash; [[Patch ' .. args.epatch .. '|'.. args.epatch .. ']]'
end

function CustomLeague._getGameMode()
	if String.isEmpty(_args.mode) then
		return nil
	end
	return GAME_MODE[string.lower(_args.mode)] or GAME_MODE['default']
end

return CustomLeague
