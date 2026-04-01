---
-- @Liquipedia
-- page=Module:Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TypeUtil = Lua.import('Module:TypeUtil')

local Data = Lua.import('Module:Faction/Data', {loadData = true})
local IconData = Lua.requireIfExists('Module:Faction/IconData', {loadData = true})
	or {byFaction = {}}

local Faction = {propTypes = {}, types = {}}

--[[
Generic data
]]--
---@type string
Faction.defaultFaction = Data.defaultFaction
---@type table<string, table<string, string>>
Faction.factions = Data.factions
---@type table<string, table<string, string>>?
Faction.aliases = Data.aliases

--[[
Wiki-specific data
]]--
---@type table<string, string>?
Faction.knownFactions = Data.knownFactions
---@type table<string, string>?
Faction.coreFactions = Data.coreFactions

Faction.types.Faction = TypeUtil.literalUnion(unpack(Array.flatten(Array.extractValues(Faction.factions))))

Faction.types.FactionProps = TypeUtil.struct{
	bgClass = 'string?',
	index = 'number',
	name = 'string',
	pageName = 'string?',
	faction = Faction.types.Faction,
}


local factionsByName = FnUtil.memoize(function ()
	return Table.mapValues(Data.factionProps, function(factionProps)
		return Table.map(factionProps, function(faction, props) return props.name:lower(), faction end)
	end)
end)

---Parses the option table, eventually adding defaults
---@param options table?
---@return table
function Faction._parseOptions(options)
	if type(options) ~= 'table' then
		options = {}
	end

	options.game = options.game or Data.defaultGame
	return options
end

---Returns a list of valid factions
---@param options {game: string?}?
---@return string[]
function Faction.getFactions(options)
	local game = Faction._parseOptions(options).game
	return game and Data.factions[game] or {}
end

---Returns a list of valid faction aliases
---@param options {game: string?}?
---@return string[]
function Faction.getAliases(options)
	local game = Faction._parseOptions(options).game
	return game and Data.aliases[game] or {}
end

--- Checks if a entered faction is valid
---@param faction string?
---@param options {game: string?}?
---@return boolean
function Faction.isValid(faction, options)
	local game = Faction._parseOptions(options).game
	return game and (Data.factionProps[game] or {})[faction] ~= nil
end

--- Fetches the properties of an entered faction
---@param faction string?
---@param options {game: string?}?
---@return table?
function Faction.getProps(faction, options)
	local game = Faction._parseOptions(options).game
	return game and (Data.factionProps[game] or {})[faction]
end

--- Parses a faction from input. Returns the factions short handle/identifier.
-- Returns nil if not a valid faction.
-- If `options.alias` is set to false the function will not look in the aliases provided via the data module.
---@param faction string?
---@param options {game: string?, alias: boolean?}?
---@return string?
function Faction.read(faction, options)
	if type(faction) ~= 'string' then
		return nil
	end

	options = Faction._parseOptions(options)

	faction = faction:lower()
	return Faction.isValid(faction, options) and faction
		or (options.game and (factionsByName()[options.game] or {})[faction])
		or (
			options.alias ~= false
			and options.game and (Faction.aliases[options.game] or {})[faction]
		) or nil
end

--- Parses multiple factions from input.
-- Returns an array of faction identifiers.
-- Returns an empty array for nil input. Throws upon invalid inputs.
---@param input string?
---@param options {game: string?, sep: string?, alias: boolean?}?
---@return table
function Faction.readMultiFaction(input, options)
	if String.isEmpty(input) then
		return {}
	end
	---@cast input -nil

	options = Faction._parseOptions(options)

	local singleFaction = Faction.read(input, options)
	if singleFaction then return {singleFaction} end

	local inputArray = Array.map(
		mw.text.split(input, options.sep or '', true),
		String.trim
	)

	local factions = Array.map(inputArray, function(faction) return Faction.read(faction, options) end)

	assert(#factions == #inputArray, 'Invalid multi-faction specifier ' .. input)

	return factions
end

--- Returns the name of an entered faction identifier
---@param faction string?
---@param options {game: string?}?
---@return string?
function Faction.toName(faction, options)
	local factionProps = Faction.getProps(faction, options)
	return factionProps and factionProps.name or nil
end

---@class FactionIconProps
---@field faction string?
---@field showLink boolean?
---@field showTitle boolean?
---@field size string|number|nil
---@field title string?
---@field game string?
---@field showName boolean?
Faction.propTypes.Icon = TypeUtil.struct{
	faction = 'string',
	showLink = 'boolean?',
	showTitle = 'boolean?',
	size = TypeUtil.union('string', 'number', 'nil'),
	title = 'string?',
	game = 'string?',
	showName = 'boolean?',
}

local namedSizes = {
	large = '30px',
	medium = '24px',
	small = '17px',
	tiny = '10px',
}

--- Returns the icon of an entered faction identifier
---@param props FactionIconProps
---@return string?
function Faction.Icon(props)
	local faction = Faction.read(props.faction, {game=props.game})
	if not faction then return end

	local factionProps = Faction.getProps(faction, {game=props.game})
	assert(factionProps, 'Faction.Icon: Invalid faction=' .. tostring(props.faction))

	local size = namedSizes[props.size or 'small'] or props.size
	if type(size) == 'number' then
		size = size .. 'px'
	end

	props.game = props.game or Data.defaultGame
	local iconData = props.game and (IconData.byFaction[props.game] or {})[faction]
		or {}
	local iconName = iconData.icon
	if not iconName then return end

	return '[['
		.. iconName
		.. '|link=' .. (props.showLink and (factionProps.pageName or factionProps.name) or '')
		.. '|' .. size
		.. (props.showTitle ~= false and '|' .. (props.title or factionProps.name) or '')
		.. ']]'
		.. (props.showName and ('&nbsp;' .. (props.title or factionProps.name)) or '')
end


--- Returns the background color class of a given faction
---@param faction string?
---@param options {game: string?}?
---@return string?
function Faction.bgClass(faction, options)
	local factionProps = Faction.getProps(faction, options)
	return factionProps and factionProps.bgClass or nil
end

return Class.export(Faction, {exports = {'Icon'}})
