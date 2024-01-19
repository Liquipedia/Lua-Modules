---
-- @Liquipedia
-- wiki=smite
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class ArenaofvalorLeagueInfobox: InfoboxLeagueTemp
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'sponsors' then
		table.insert(widgets, Cell{name = 'Official Device', content = {args.device}})
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {Game.name{game = args.game}}},
		}
	elseif id == 'customcontent' then
		Array.appendWith(widgets,
			args.player_number and Title{name = 'Players'} or nil,
			Cell{name = 'Number of players', content = {args.player_number}},
			args.team_number and Title{name = 'Teams'} or nil,
			Cell{name = 'Number of teams', content = {args.team_number}}
		)
	end
	return widgets
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publisherpremier)
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = tostring(Logic.readBool(args.publisherpremier))
end

return CustomLeague
