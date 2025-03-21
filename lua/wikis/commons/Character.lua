---
-- @Liquipedia
-- wiki=commons
-- page=Module:Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Info = require('Module:Info')
local Lua = require('Module:Lua')

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

local function datapointType()
	if Info.wikiName == 'dota2' then
		return 'hero'
	end
	return 'character'
end

---@param name string
---@return StandardCharacter?
function Character.getCharacterByName(name)
	local record = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::' .. datapointType() .. ']] AND [[name::'.. name ..']]',
		limit = 1,
	})[1]
	if not record then
		return nil
	end
	return Character.characterFromRecord(record)
end

---@return StandardCharacter[]
function Character.getAllCharacters()
	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::' .. datapointType() .. ']]',
		limit = 5000,
	})
	return Array.map(records, Character.characterFromRecord)
end

---@param record datapoint
---@return StandardCharacter
function Character.characterFromRecord(record)
	local name = record.name
	local icon
	local iconData = CharacterIcon.raw(name)
	if iconData and iconData.file then
		icon = iconData.file
	else
		icon = record.extradata.icon
	end

	---@type StandardCharacter
	local character = {
		name = name,
		pageName = record.pagename,
		releaseDate = record.date,
		iconLight = icon or record.image,
		iconDark = icon or record.imagedark,
		imageLight = record.image,
		imageDark = record.imagedark,
	}

	return character
end

return Character
