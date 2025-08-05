---
-- @Liquipedia
-- page=Module:Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Info = Lua.import('Module:Info')
local Table = Lua.import('Module:Table')

local CharacterIcon = Lua.import('Module:CharacterIcon')

local Character = {}

---@class StandardCharacter
---@field name string
---@field pageName string
---@field releaseDate string?
---@field iconLight string?
---@field iconDark string?
---@field imageLight string?
---@field imageDark string?
---@field roles string[]
---@field gameData table

local function datapointType()
	if Info.wikiName == 'dota2' then
		return 'hero'
	end
	return 'character'
end

---@param name string
---@return StandardCharacter?
function Character.getCharacterByName(name)
	return Character.getAllCharacters{'[[name::'.. name ..']]'}[1]
end

---@param additionalConditions string|string[]?
---@return StandardCharacter[]
function Character.getAllCharacters(additionalConditions)
	local conditions = Array.extend(
		'[[type::' .. datapointType() .. ']]',
		additionalConditions
	)
	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' AND '),
		limit = 5000,
	})
	return Array.map(records, Character.characterFromRecord)
end

---@param record datapoint
---@return StandardCharacter
function Character.characterFromRecord(record)
	local name = record.name
	local icon = Table.extract(record.extradata, 'icon')
	local iconData = CharacterIcon.raw(name)
	if iconData and iconData.file then
		icon = iconData.file
	end

	local extradata = record.extradata or {}

	---@type StandardCharacter
	local character = {
		name = name,
		pageName = record.pagename,
		releaseDate = record.date,
		iconLight = icon or record.image,
		iconDark = icon or record.imagedark,
		imageLight = record.image,
		imageDark = record.imagedark,
		roles = Table.extract(extradata, 'roles') or {},
		gameData = extradata,
	}

	return character
end

return Character
