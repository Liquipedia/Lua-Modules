---
-- @Liquipedia
-- wiki=commons
-- page=Module:Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Data = mw.loadData('Module:Faction/Data')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local IconData = Lua.loadDataIfExists('Module:Faction/IconData')
	or {byFaction = {}}

local Faction = {propTypes = {}, types = {}}

Faction.defaultFaction = Data.defaultFaction
Faction.factions = Data.factions
Faction.knownFactions = Data.knownFactions
Faction.coreFactions = Data.coreFactions
Faction.aliases = Data.aliases

Faction.types.Faction = TypeUtil.literalUnion(unpack(Faction.factions))

Faction.types.FactionProps = TypeUtil.struct{
	bgClass = 'string?',
	index = 'number',
	name = 'string',
	pageName = 'string?',
	faction = Faction.types.Faction,
}

local byName = Table.map(Data.factionProps, function(faction, props) return props.name, faction end)
local byLowerName = Table.map(byName, function(name, faction) return name:lower(), faction end)

--- Checks if a entered faction is valid
---@param faction string
---@return boolean
function Faction.isValid(faction)
	return Data.factionProps[faction] ~= nil
end

--- Fetches the properties of an entered faction
---@param faction string
---@return table?
function Faction.getProps(faction)
	return Data.factionProps[faction]
end

--- Parses a faction from input. Returns the factions short handle/identifier.
-- Returns nil if not a valid faction.
---@param faction string
---@return string?
function Faction.read(faction)
	if type(faction) ~= 'string' then
		return nil
	end

	faction = faction:lower()
	return Faction.isValid(faction) and faction
		or byLowerName[faction]
		or Faction.aliases[faction]
end

--- Returns the name of an entered faction identifier
---@param faction string
---@return string?
function Faction.toName(faction)
	local factionProps = Faction.getProps(faction)
	return factionProps and factionProps.name or nil
end

Faction.propTypes.Icon = TypeUtil.struct{
	faction = 'string',
	showLink = 'boolean?',
	showTitle = 'boolean?',
	size = TypeUtil.union('string', 'number', 'nil'),
	title = 'string?',
}

local namedSizes = {
	large = '30px',
	medium = '24px',
	small = '17px',
	tiny = '10px',
}

--- Returns the icon of an entered faction identifier
---@props props {faction: string, size: string|number|nil, showLink: boolean?, showTitle: boolean?, title: string?}
---@return string?
function Faction.Icon(props)
	local faction = Faction.read(props.faction)
	if not faction then return end

	local factionProps = Faction.getProps(faction)
	assert(factionProps, 'Faction.Icon: Invalid faction=' .. tostring(props.faction))

	local size = namedSizes[props.size or 'small'] or props.size
	if type(size) == 'number' then
		size = size .. 'px'
	end

	local iconData = IconData.byFaction[faction] or {}
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
---@param faction string
---@return string?
function Faction.bgClass(faction)
	local factionProps = Faction.getProps(faction)
	return factionProps and factionProps.bgClass or nil
end

return Faction
