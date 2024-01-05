---
-- @Liquipedia
-- wiki=commons
-- page=Module:Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Data = mw.loadData('Module:Faction/Data')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local IconData = Lua.requireIfExists('Module:Faction/IconData', {requireDevIfEnabled = true, loadData = true})
	or {byFaction = {}}

local Faction = {propTypes = {}, types = {}}

---@type string
Faction.defaultFaction = Data.defaultFaction
---@type table<string, table<string, string>>
Faction.factions = Data.factions
---@type table<string, string>?
Faction.knownFactions = Data.knownFactions
---@type table<string, string>?
Faction.coreFactions = Data.coreFactions
---@type table<string, table<string, string>>?
Faction.aliases = Data.aliases

Faction.types.Faction = TypeUtil.literalUnion(unpack(Faction.factions))

Faction.types.FactionProps = TypeUtil.struct{
	bgClass = 'string?',
	index = 'number',
	name = 'string',
	pageName = 'string?',
	faction = Faction.types.Faction,
}


local byName = Table.mapValues(Data.factionProps,
	function(factionProps)
		return Table.map(factionProps, function(faction, props) return props.name, faction end)
	end
)
local byLowerName = Table.mapValues(byName,
	function(byGame)
		return Table.map(byGame, function(name, faction) return name:lower(), faction end)
	end
)

---Returns a list of valid factions
---@param game string?
---@return string[]
function Faction.getFactions(game)
	game = game or Data.defaultGame
	return game and Data.factions[game] or {}
end

---Returns a list of valid faction aliases
---@param game string?
---@return string[]
function Faction.getAliases(game)
	game = game or Data.defaultGame
	return game and Data.aliases[game] or {}
end

--- Checks if a entered faction is valid
---@param faction string?
---@param game string?
---@return boolean
function Faction.isValid(faction, game)
	game = game or Data.defaultGame
	return game and (Data.factionProps[game] or {})[faction] ~= nil
end

--- Fetches the properties of an entered faction
---@param faction string?
---@param game string?
---@return table?
function Faction.getProps(faction, game)
	game = game or Data.defaultGame
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

	options = options or {}
	options.game = options.game or Data.defaultGame

	faction = faction:lower()
	return Faction.isValid(faction, options.game) and faction
		or (options.game and (byLowerName[options.game] or {})[faction])
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

	options = options or {}

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
---@param game string?
---@return string?
function Faction.toName(faction, game)
	local factionProps = Faction.getProps(faction, game)
	return factionProps and factionProps.name or nil
end

---@class FactionIconProps
---@field faction string
---@field showLink boolean?
---@field showTitle boolean?
---@field size string|number|nil
---@field title string?
---@field game string?
Faction.propTypes.Icon = TypeUtil.struct{
	faction = 'string',
	showLink = 'boolean?',
	showTitle = 'boolean?',
	size = TypeUtil.union('string', 'number', 'nil'),
	title = 'string?',
	game = 'string?',
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

	local factionProps = Faction.getProps(faction, props.game)
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
		.. '|link=' .. (props.showLink and factionProps.pageName or '')
		.. '|' .. size
		.. (props.showTitle ~= false and '|' .. (props.title or factionProps.name) or '')
		.. ']]'
end


--- Returns the background color class of a given faction
---@param faction string?
---@param game string?
---@return string?
function Faction.bgClass(faction, game)
	local factionProps = Faction.getProps(faction, game)
	return factionProps and factionProps.bgClass or nil
end

return Class.export(Faction)
