---
-- @Liquipedia
-- wiki=heroes
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local CharacterNames = mw.loadData('Module:HeroNames')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local SIZE_HERO = '28x28px'

---@class HeroesInfoboxPlayer: Person
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

	if id == 'custom' then
		local heroIcons = Array.map(self.caller:getAllArgsForBase(args, 'hero'), function(hero)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)
		table.insert(widgets, Cell{name = 'Signature Heroes', content = {table.concat(heroIcons, '&nbsp;')}})
	elseif id == 'history' and string.match(args.retired or '', '%d%d%d%d') then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

return CustomPlayer
