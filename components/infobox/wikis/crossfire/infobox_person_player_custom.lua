---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Widgets = require('Module:Infobox/Widget/All')
local Title = Widgets.Title
local Center = Widgets.Center

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

---@class CrossfireInfoboxPlayer: Person
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

	if id == 'history' then
		local manualHistory = args.history
		local automatedHistory = TeamHistoryAuto.results{
			convertrole = true,
			player = self.caller.pagename
		}

		if String.isEmpty(manualHistory) and not automatedHistory then return {} end
		return {
			Title{name = 'History'},
			Center{content = {manualHistory}},
			Center{content = {automatedHistory}},
		}
	elseif id == 'region' then return {}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	local role = Role.run{role = self.args.role}
	lpdbData.extradata.isplayer = role.isPlayer or 'true'
	lpdbData.extradata.role = role.role

	return lpdbData
end

return CustomPlayer
