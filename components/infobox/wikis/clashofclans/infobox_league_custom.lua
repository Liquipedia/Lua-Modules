---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local SUPERCELL_SPONSORED_ICON = '[[File:Supercell lightmode.png|x18px|link=Supercell'
	.. '|Tournament sponsored by Supercell.|class=show-when-light-mode]][[File:Supercell darkmode.png'
	.. '|x18px|link=Supercell|Tournament sponsored by Supercell.|class=show-when-dark-mode]]'

local _args

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {_args.team_number}
	})

	return widgets
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['supercell-sponsored'])
end

function CustomLeague:appendLiquipediatierDisplay(args)
	return Logic.readBool(args['supercell-sponsored']) and ('&nbsp;' .. SUPERCELL_SPONSORED_ICON) or ''
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_publishertier', Logic.readBool(args['supercell-sponsored']) and 'true' or nil)
end

return CustomLeague
