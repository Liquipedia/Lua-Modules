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

local Player = Lua.import('Module:Infobox/Person')

---@class ZulaInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player.role = Role.run({role = player.args.role})
	player.role2 = Role.run({role = player.args.role2})

	return player:createInfobox(frame)
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = self.role.role
	lpdbData.extradata.role2 = self.role2.role
	return lpdbData
end

return CustomPlayer
