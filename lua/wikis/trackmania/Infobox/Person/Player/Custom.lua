---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Logic = Lua.import('Module:Logic')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@type table<string, string>
local INPUTS = {
	gamepad = 'Gamepad',
	joystick = 'Joystick',
	kbm = 'Keyboard & Mouse',
	keyboard = 'Keyboard',
	wheel = 'Wheel',
}

---@type table<string, string>
local CAMERAS = {
	['1'] = '1',
	['2'] = '2',
	['3'] = '3',
	['alt1'] = '1 (Alternate)',
	['alt2'] = '2 (Alternate)',
	['alt3'] = '3 (Alternate)',
	['1alt'] = '1 (Alternate)',
	['2alt'] = '2 (Alternate)',
	['3alt'] = '3 (Alternate)',
}

---@class TrackmaniaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))
	player.args.achievements = Achievements.player{noTemplate = true}
	player.args['trackmania-io'] = player.args.trackmania_id

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Input Device', children = {caller:formatInput()}})
		table.insert(widgets, Cell{name = 'Main Camera', children = {caller:formatCamera()}})
	elseif id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', children = {args.years_active}})
	end

	return widgets
end

---@param lpdbData table
---@return table
function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.input = self:formatInput()
	lpdbData.extradata.camera = self:formatCamera()
	return lpdbData
end

---@return string?
function CustomPlayer:formatInput()
	local lowercaseInput = self.args.input and self.args.input:lower() or nil
	return Logic.nilIfEmpty(INPUTS[lowercaseInput])
end

---@return string?
function CustomPlayer:formatCamera()
	local lowercaseCamera = self.args.camera and self.args.camera:lower() or nil
	return Logic.nilIfEmpty(CAMERAS[lowercaseCamera])
end

return CustomPlayer
