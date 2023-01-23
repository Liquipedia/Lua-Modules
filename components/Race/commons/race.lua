---
-- @Liquipedia
-- wiki=commons
-- page=Module:Race
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Data = mw.loadData('Module:Race/Data')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local IconData = Lua.loadDataIfExists('Module:Race/IconData')
	or {byRace = {}}

local Race = {propTypes = {}, types = {}}

Race.defaultRace = Data.defaultRace
Race.races = Data.races
Race.knownRaces = Data.knownRaces
Race.coreRaces = Data.coreRaces
Race.aliases = Data.aliases

Race.types.Race = TypeUtil.literalUnion(unpack(Race.races))

Race.types.RaceProps = TypeUtil.struct{
	bgClass = 'string?',
	index = 'number',
	name = 'string',
	pageName = 'string?',
	race = Race.types.Race,
}

local byName = Table.map(Data.raceProps, function(race, props) return props.name, race end)
local byLowerName = Table.map(byName, function(name, race) return name:lower(), race end)

--- Checks if a entered race is valid
---@param race string
---@return boolean
function Race.isValid(race)
	return Data.raceProps[race] ~= nil
end

--- Fetches the properties of an entered race
---@param race string
---@return table|nil
function Race.getProps(race)
	return Data.raceProps[race]
end

--- Parses a race from input. Returns the races short handle/identifier.
-- Returns nil if not a valid race.
---@param race string
---@return string|nil
function Race.read(race)
	if type(race) ~= 'string' then
		return nil
	end

	race = race:lower()
	return Data.raceProps[race] and race
		or byLowerName[race]
		or Race.aliases[race]
end

--- Returns the name of an entered race identifier
---@param race string
---@return string|nil
function Race.toName(race)
	local raceProps = Race.getProps(race)
	return raceProps and raceProps.name or nil
end

Race.propTypes.Icon = TypeUtil.struct{
	race = 'string',
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

--- Returns the name of an entered race identifier
---@props props {race: string, size: string?, showLink: boolean?, showTitle: boolean?, title: string?}
---@return string|nil
function Race.Icon(props)
	local race = Race.read(props.race)
	if not race then return '' end

	local raceProps = Race.getProps(race)
	assert(raceProps, 'Race.Icon: Invalid race=' .. tostring(props.race))

	local size = namedSizes[props.size or 'small'] or props.size
	if type(size) == 'number' then
		size = size .. 'px'
	end

	local iconData = IconData.byRace[race] or {}
	local iconName = iconData.icon
	if not iconName then return end

	return '[['
		.. iconName
		.. '|link=' .. (props.showLink and raceProps.pageName or '')
		.. '|' .. size
		.. (props.showTitle ~= false and '|' .. (props.title or raceProps.name) or '')
		.. ']]'
end


--- Returns the name background color class of a given race
---@param race string
---@return string|nil
function Race.bgClass(race)
	local raceProps = Race.getProps(race)
	return raceProps and raceProps.bgClass or nil
end

return Race
