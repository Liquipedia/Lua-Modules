---
-- @Liquipedia
-- page=Module:Infobox/Event/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')

local Event = Lua.import('Module:Infobox/Event')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class FightersEventInfobox: InfoboxEvent
local CustomEvent = Class.new(Event)
---@class FightersEventInfoboxInjector
---@field caller FightersEventInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomEvent.run(frame)
	local event = CustomEvent(frame)
	event:setWidgetInjector(CustomInjector(event))

	return event:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'gamesettings' then
		return Array.append(widgets,
			Cell{name = 'Version', content = {args.version}},
			Cell{name = 'Edition', content = {args.edition}}
		)
	end

	return widgets
end

---@param args table
---@return table
function CustomEvent:getWikiCategories(args)
	local gameLink = Game.link{game = self.data.game, useDefault = false}
	return Array.append({'Tournament Overviews'},
		gameLink and (gameLink .. ' Competitions') or nil
	)
end

return CustomEvent
