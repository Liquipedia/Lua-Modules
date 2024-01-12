---
-- @Liquipedia
-- wiki=zula
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Title = Widgets.Title
local Center = Widgets.Center

---@class ZulaInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true
	player.role = Role.run({role = player.args.role})
	player.role2 = Role.run({role = player.args.role2})

	return player:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'history' then
		local manualHistory = args.history
		local automatedHistory = TeamHistoryAuto._results{
			convertrole = 'true',
			player = self.caller.pagename
		}

		if String.isNotEmpty(manualHistory) or automatedHistory then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
			end
		end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.extradata.role = self.role.role
	lpdbData.extradata.role2 = self.role2.role
	return lpdbData
end

return CustomPlayer
