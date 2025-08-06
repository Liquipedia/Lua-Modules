---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local GamesPlayed = Lua.import('Module:GamesPlayed')
local YearsActive = Lua.import('Module:YearsActive') -- TODO Convert to use the commons YearsActive

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class FightersInfoboxPlayer: Person
---@field games string[]
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	local gamesText = GamesPlayed.get{game = player.args.game, player = mw.title.getCurrentTitle().baseText}
	player.games = mw.text.split(gamesText, '</br>', true)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'custom' then
		table.insert(widgets, Cell{name = 'Games', content = self.caller.games})
	elseif id == 'status' then
		table.insert(widgets,
			Cell{name = 'Years Active', content = {YearsActive.get{player = mw.title.getCurrentTitle().baseText}}}
		)
	end

	return widgets
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	return Array.extendWith(categories, Array.map(self.games, function(game)
		return game .. ' Players'
	end))
end

return CustomPlayer
