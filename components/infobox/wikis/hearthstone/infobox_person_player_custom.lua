---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class HearthstoneInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

local GM_ICON = '[[File:HS grandmastersIconSmall.png|x15px|link=Grandmasters]]&nbsp;'

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

	if id == 'custom' then
		local grandMaster = args.grandmasters and (GM_ICON .. args.grandmasters) or nil
		table.insert(widgets, Cell{name = 'Grandmasters', content = {grandMaster}})
	end

	return widgets
end

return CustomPlayer
