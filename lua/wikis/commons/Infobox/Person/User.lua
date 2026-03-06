---
-- @Liquipedia
-- page=Module:Infobox/Person/User
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Person = Lua.import('Module:Infobox/Person')

---@class InfoboxUser: Person
---@operator call(Frame): InfoboxUser
local User = Class.new(Person)

---@return Widget[]
function User:_getFavouriteTeams()
	local foundArgs = self:getAllArgsForBase(self.args, 'fav-team-')

	return Array.map(foundArgs, function (favouriteTeam)
		return OpponentDisplay.InlineTeamContainer{template = favouriteTeam, style = 'icon'}
	end)
end

---@param base string
---@param default string|number
---@return string[]
function User:_getArgsfromBaseDefault(base, default)
	return Array.appendWith(self:getAllArgsForBase(self.args, base), self.args[default])
end

---@param args table
---@return boolean
function User:shouldStoreData(args) return false end

---@param args table
---@return string
function User:getStatusToStore(args) return '' end

---@param args table
---@param birthDisplay string
---@param personType string
---@param status PlayerStatus
---@return string[]
function User:getCategories(args, birthDisplay, personType, status) return {} end

---@param args table
---@return {store: string, category: string}
function User:getPersonType(args)
	return {store = 'User', category = 'User'}
end

return User
