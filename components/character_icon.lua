---
-- @Liquipedia
-- wiki=commons
-- page=Module:CharacterIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Data = Lua.requireIfExists('Module:CharacterIcon/Data', {loadData = true})

---@class IconArguments
---@field character string
---@field size string?
---@field class string?
---@field date string?

local CharacterIcon = {}

---@param images table
---@param date string?
---@return string
function CharacterIcon._getImageFromTable(images, date)
	date = date or DateExt.getContextualDateOrNow()
	local timeStamp = DateExt.readTimestamp(date)
	local image = Array.find(images, function (c)
		local startDate = DateExt.readTimestamp(c[1]) or DateExt.minTimestamp
		local endDate = DateExt.readTimestamp(c[2]) or DateExt.maxTimestamp
		return timeStamp >= startDate and timeStamp < endDate
	end)
	return image and image[3] or ''
end

---@param args IconArguments
---@return string
function CharacterIcon.Icon(args)
	if args.character == nil then
		return ''
	end
	local characterData = Data[args.character:lower()]

	if Logic.isEmpty(characterData) then
		return ''
	end

	local image
	if type(characterData) == 'table' then
		image = CharacterIcon._getImageFromTable(characterData, args.date)
	else
		image = characterData
	end

	image = string.gsub(image, '|<SIZE>', Logic.isNotEmpty(args.size) and '|' .. args.size or '')
	image = string.gsub(image, '|<CLASS>', Logic.isNotEmpty(args.class) and '|class=' .. args.class or '')

	return image
end

return Class.export(CharacterIcon)
