---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameAppearances = require('Module:GetGameAppearances')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class PokemonInfoboxPlayer: Person
---@field roleData table
---@field roleData2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.roleData = Role.run{role = player.args.role}
	player.roleData2 = Role.run{role = player.args.role2}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Game Appearances', content = GameAppearances.player({player = caller.pagename})},
		}
	elseif id == 'history' then
		local manualHistory = args.history
		local automatedHistory = TeamHistoryAuto.results{
			convertrole = true,
			addlpdbdata = true,
			player = caller.pagename
		}

		if String.isNotEmpty(manualHistory) or automatedHistory then
			return {
				Title{children = 'History'},
				Center{children = {manualHistory}},
				Center{children = {automatedHistory}},
			}
		end
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {self.caller.roleData.display, self.caller.roleData2.display}}
		}
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.isplayer = self.roleData.isPlayer or 'true'
	lpdbData.extradata.role = self.roleData.role
	lpdbData.extradata.role2 = self.roleData2.role

	lpdbData.region = String.nilIfEmpty(Region.name({region = args.region, country = args.country}))

	return lpdbData
end

return CustomPlayer
