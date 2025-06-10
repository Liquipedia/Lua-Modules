---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local VALID_PUBLISHERTIERS = {'sponsored'}

local SUPERCELL_SPONSORED_ICON = '[[File:Supercell lightmode.png|x18px|link=Supercell'
	.. '|Tournament sponsored by Supercell.|class=show-when-light-mode]][[File:Supercell darkmode.png'
	.. '|x18px|link=Supercell|Tournament sponsored by Supercell.|class=show-when-dark-mode]]'

---@class ClashofclansLeagueInfobox: InfoboxLeague
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
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	return self.data.publishertier and ('&nbsp;' .. SUPERCELL_SPONSORED_ICON) or ''
end

---@param args table
function CustomLeague:customParseArguments(args)
	local publisherTier = (args.publishertier or ''):lower()
	self.data.publishertier = Table.includes(VALID_PUBLISHERTIERS, publisherTier) and publisherTier
end

return CustomLeague
