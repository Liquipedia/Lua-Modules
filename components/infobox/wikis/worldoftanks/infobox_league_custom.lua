---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
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
local _league

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args
	_league = league

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

---@return WidgetInjector
function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Number of teams', content = {_args.team_number}},
		Cell{name = 'Number of players', content = {_args.player_number}},
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {Cell{name = 'Game', content = {Game.name{game = _args.game}}}}
	elseif id == 'customcontent' then
		if String.isNotEmpty(_args.map1) then
			local maps = Array.map(_league:getAllArgsForBase(_args, 'map'), function(map)
				return tostring(CustomLeague:_createNoWrappingSpan(PageLink.makeInternalLink(map)))
			end)
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')
	lpdbData.game = Game.name{game = args.game}
	return lpdbData
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_publishertier', args.publisherpremier)
	Variables.varDefine('tournament_game', Game.name{game = args.game})
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publisherpremier)
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague
