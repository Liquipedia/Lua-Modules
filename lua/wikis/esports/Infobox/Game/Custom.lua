
---
-- @Liquipedia
-- page=Module:Infobox/Game/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Game = Lua.import('Module:Infobox/Game')

local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class EsportsGameInfobox: GameInfobox
---@operator call(Frame): EsportsGameInfobox
local CustomGame = Class.new(Game)

---@class EsportsGameInfoboxWidgetInjector: WidgetInjector
---@operator call(EsportsGameInfobox): EsportsGameInfoboxWidgetInjector
---@field caller EsportsGameInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomGame.run(frame)
	local game = CustomGame(frame)
	game:setWidgetInjector(CustomInjector(game))

	return game:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Engine', children = {args.engine}},
			Cell{name = 'Genre(s)', children = {args.genre}},
			Cell{name = 'Mode(s)', children = {args.mode}}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomGame:addToLpdb(lpdbData, args)
	lpdbData.extradata.engine = args.engine
	lpdbData.extradata.genre = args.genre
	lpdbData.extradata.mode = args.mode

	return lpdbData
end

return CustomGame
