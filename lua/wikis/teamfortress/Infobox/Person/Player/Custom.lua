---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Template = Lua.import('Module:Template')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

---@class TeamfortressInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'role' then
		if not args.role then return widgets end
		return {
			Cell{name = 'Main', content = {Template.safeExpand(mw.getCurrentFrame(), 'Class/'.. args.role)}}
		}
	end
	return widgets
end

return CustomPlayer
