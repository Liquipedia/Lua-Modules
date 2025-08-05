---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Title = Widgets.Title
local Center = Widgets.Center

---@class ZulaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true

	return player:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'history' then
		local manualHistory = args.history
		local automatedHistory = TeamHistoryAuto.results{
			convertrole = true,
			player = self.caller.pagename
		}

		if String.isNotEmpty(manualHistory) or automatedHistory then
			return {
				Title{children = 'History'},
				Center{children = {manualHistory}},
				Center{children = {automatedHistory}},
			}
			end
		end
	return widgets
end

return CustomPlayer
