---
-- @Liquipedia
-- page=Module:Infobox/Game/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Game = Lua.import('Module:Infobox/Game')

local Injector = Lua.import('Module:Widget/Injector')

local Widgets = require('Module:Widget/All')
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology
local Title = Widgets.Title

---@class FightersGameInfobox: GameInfobox
local CustomGame = Class.new(Game)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomGame.run(frame)
	local game = CustomGame(frame)
	game:setWidgetInjector(CustomInjector(game))

	return game:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return {
			Builder { builder = function()
				if self:_isChronologySet(args.previous, args.next) then
					return {
						Title { children = 'Chronology' },
						Chronology {
							links = Table.filterByKey(args, function(key)
								return type(key) == 'string' and
									(key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
							end)
						}
					}
				end
			end}
		}
	end

	return widgets
end

---@param previous string?
---@param next string?
---@return boolean
function CustomInjector:_isChronologySet(previous, next)
	-- We only need to check the first of these params, since it makes no sense
	-- to set next2 and not next, etc.
	return not (String.isEmpty(previous) and String.isEmpty(next))
end

return CustomGame
