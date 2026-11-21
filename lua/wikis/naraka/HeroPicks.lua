---
-- @Liquipedia
-- page=Module:HeroPicks
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local CharacterIcon = Lua.import('Module:CharacterIcon')
local String = Lua.import('Module:StringUtils')

local HEROES = Lua.import('Module:CharacterIcon/Data', {loadData = true})

local HeroPicks = {}

---@param value any
---@return string?
local function normalize(value)
	if type(value) ~= 'string' then
		return nil
	end

	local id = String.trim(value):lower():gsub('[%s_%-]+', '')
	return id ~= '' and id or nil
end

local HERO_NAMES = {}
for name in pairs(HEROES) do
	HERO_NAMES[normalize(name)] = name
end

---@param value any
---@return {page: string, file: string}?
function HeroPicks.lookup(value)
	local id = normalize(value)
	local name = id and HERO_NAMES[id]
	if not name then
		return nil
	end

	local hero = CharacterIcon.raw(name)
	if not hero or not hero.file or hero.file == '' then
		return nil
	end

	return {
		page = hero.link or hero.display or name,
		file = hero.file,
	}
end

---@param map table
---@param opponentIndex integer
---@param slotCount integer
---@return table<string, string>?
function HeroPicks.readMapOpponent(map, opponentIndex, slotCount)
	local picks = {}

	for slot = 1, slotCount do
		local id = normalize(map['t' .. opponentIndex .. 'h' .. slot])
		if id then
			picks[tostring(slot)] = id
		end
	end

	return next(picks) and picks or nil
end

return HeroPicks
