---
-- @Liquipedia
-- page=Module:HeroPicks
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local CharacterNames = Lua.requireIfExists('Module:CharacterNames', {loadData = true}) or {}
local HEROES = Lua.import('Module:CharacterIcon/Data', {loadData = true})

local HeroPicks = {}

---@class NarakaHeroPick
---@field page string

---@type table<string, string>?
local heroNames

---@type table<string, table<string, NarakaHeroPick|false>>
local lookupCache = {}

---@type table<string, boolean>
local warnedInputs = {}

---@param value any
---@return string?
local function normalize(value)
	if type(value) ~= 'string' then
		return nil
	end

	local id = String.trim(value):lower():gsub('[%s_%-]+', '')
	return Logic.nilIfEmpty(id)
end

---@return table<string, string>
local function getHeroNames()
	if heroNames then
		return heroNames
	end

	local names = Table.map(HEROES, function(name)
		return normalize(name), name
	end)

	-- Resolve aliases to existing CharacterIcon/Data keys.
	for alias, character in pairs(CharacterNames) do
		local aliasId = normalize(alias)
		local characterId = normalize(character)
		local name = characterId and names[characterId]

		if aliasId and name and not names[aliasId] then
			names[aliasId] = name
		end
	end

	heroNames = names
	return names
end

---@param value any
---@return string?
local function resolve(value)
	local id = normalize(value)
	if not id then
		return nil
	end

	return getHeroNames()[id]
end

---@param value any
---@param parameter string
local function warnUnknownHero(value, parameter)
	local message = 'Unknown Naraka hero "' .. tostring(value)
		.. '" in parameter "' .. parameter .. '".'

	if warnedInputs[message] then
		return
	end

	warnedInputs[message] = true
	mw.addWarning(mw.text.nowiki(message))
end

---@param value any
---@param date string?
---@return NarakaHeroPick?
function HeroPicks.lookup(value, date)
	local name = resolve(value)
	if not name then
		return nil
	end

	date = date or DateExt.getContextualDateOrNow()

	local cache = lookupCache[date]
	if not cache then
		cache = {}
		lookupCache[date] = cache
	end

	local cached = cache[name]
	if cached ~= nil then
		return cached or nil
	end

	local heroIcon = CharacterIcon.raw(name, date)
	if not heroIcon or Logic.isEmpty(heroIcon.file) then
		cache[name] = false
		return nil
	end

	local hero = {
		page = name,
	}

	cache[name] = hero
	return hero
end

---@param map table
---@param opponentIndex integer
---@param slotCount integer
---@param date string?
---@return table<string, string>?
function HeroPicks.readMapOpponent(map, opponentIndex, slotCount, date)
	---@type table<string, string>
	local picks = {}

	Array.forEach(Array.range(1, slotCount), function(heroIndex)
		local parameter = 't' .. opponentIndex .. 'h' .. heroIndex
		local value = map[parameter]

		if value == nil then
			return
		end

		if type(value) == 'string' and String.trim(value) == '' then
			return
		end

		local hero = HeroPicks.lookup(value, date)
		if not hero then
			warnUnknownHero(value, parameter)
			return
		end

		picks[tostring(heroIndex)] = hero.page
	end)

	return Logic.nilIfEmpty(picks)
end

return HeroPicks
