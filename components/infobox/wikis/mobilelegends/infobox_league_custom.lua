---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'sponsors' then
		table.insert(widgets, Cell{name = 'Official Device', content = {_args.device}})
	elseif id == 'gamesettings' then
		return {Cell{name = 'Patch', content = {CustomLeague._getPatchVersion()}}}
	elseif id == 'customcontent' then
		if _args.player_number then
			table.insert(widgets, Title{name = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {_args.player_number}})
		end

		--teams section
		if _args.team_number or (not String.isEmpty(_args.team1)) then
			Variables.varDefine('is_team_tournament', 1)
			table.insert(widgets, Title{name = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
	end
	return widgets
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_patch', args.patch)
	Variables.varDefine('tournament_endpatch', args.epatch)

	Variables.varDefine('tournament_publishertier', Logic.readBool(args['moonton-sponsored']) and 'true' or nil)
		--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['moonton-sponsored'])
end

function CustomLeague._getPatchVersion()
	if String.isEmpty(_args.patch) then return nil end
	local content = PageLink.makeInternalLink(_args.patch, 'Patch ' .. _args.patch)
	if not String.isEmpty(_args.epatch) then
		content = content .. '&nbsp;&ndash;&nbsp;'
		content = content .. PageLink.makeInternalLink(_args.epatch, 'Patch ' .. _args.epatch)
	end

	return content
end

return CustomLeague
