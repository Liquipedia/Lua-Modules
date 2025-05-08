---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameAppearances = require('Module:GetGameAppearances')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local Role = require('Module:Role')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class HaloInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)


---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = Role.run{role = player.args.role}
	player.role2 = Role.run{role = player.args.role2}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller

	if id == 'custom' then
		return {
			Cell{name = 'Game Appearances', content = GameAppearances.player({player = caller.pagename})},
		}
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {caller.role.display, caller.role2.display}}
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.isplayer = self.role.isPlayer or 'true'
	lpdbData.extradata.role = self.role.role
	lpdbData.extradata.role2 = self.role2.role

	lpdbData.region = String.nilIfEmpty(Region.name({region = args.region, country = args.country}))

	return lpdbData
end

return CustomPlayer
