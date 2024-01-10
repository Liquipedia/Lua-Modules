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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local SUPERCELL_SPONSORED_ICON = '[[File:Supercell lightmode.png|x18px|link=Supercell'
	.. '|Tournament sponsored by Supercell.|class=show-when-light-mode]][[File:Supercell darkmode.png'
	.. '|x18px|link=Supercell|Tournament sponsored by Supercell.|class=show-when-dark-mode]]'

---@class ClashofclansLeagueInfobox: InfoboxLeagueTemp
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

	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Teams', content = {args.team_number}})
	end

	return widgets
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['supercell-sponsored'])
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	return Logic.readBool(args['supercell-sponsored']) and ('&nbsp;' .. SUPERCELL_SPONSORED_ICON) or ''
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.publishertier = Logic.readBool(args['supercell-sponsored']) and 'true' or nil
end

return CustomLeague
