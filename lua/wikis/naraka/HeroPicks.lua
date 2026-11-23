---
-- @Liquipedia
-- page=Module:HeroPicks
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local HEROES = Lua.import('Module:CharacterIcon/Data', {loadData = true})

local HeroPicks = {}

---@param value any
---@return string?
local function normalize(value)
	if type(value) ~= 'string' then
		return nil
	end

	local id = String.trim(value):lower():gsub('[%s_%-]+', '')
	return Logic.nilIfEmpty(id)
end

local HERO_NAMES = {}
for name in pairs(HEROES) do
	HERO_NAMES[normalize(name)] = name
end

---@param value any
---@return {page: string, file: string}?
function HeroPicks.lookup(value)
	local name = HERO_NAMES[normalize(value)]
	if not name then
		return nil
	end

	local heroIcon = CharacterIcon.raw(name) or {}
	if Logic.isEmpty(heroIcon.file) then
		return nil
	end

	return {
		page = heroIcon.link or heroIcon.display or name,
		file = heroIcon.file,
	}
end

---@param map table
---@param opponentIndex integer
---@param slotCount integer
---@return table<integer, string>?
function HeroPicks.readMapOpponent(map, opponentIndex, slotCount)
	return Logic.nilIfEmpty(Table.map(Array.range(1, slotCount), function(_, heroIndex)
		return heroIndex, normalize(map['t' .. opponentIndex .. 'h' .. heroIndex])
	end))
end

return HeroPicks
