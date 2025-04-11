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
local Page = require('Module:Page')

local Data = Lua.requireIfExists('Module:CharacterIcon/Data', {loadData = true})

---@class IconArguments
---@field character string?
---@field size string?
---@field class string?
---@field date string?
---@field addTextLink boolean?

---@class CharacterIconInfo
---@field file string
---@field link string?
---@field display string?
---@field startDate string?
---@field endDate string?

local CharacterIcon = {}

---@param icons CharacterIconInfo[]
---@param date string?
---@return CharacterIconInfo?
function CharacterIcon._getCharacterIconInfo(icons, date)
	date = date or DateExt.getContextualDateOrNow()
	local timeStamp = DateExt.readTimestamp(date)
	return Array.find(icons, function (icon)
		local startDate = DateExt.readTimestamp(icon.startDate) or DateExt.minTimestamp
		local endDate = DateExt.readTimestamp(icon.endDate) or DateExt.maxTimestamp
		return timeStamp >= startDate and timeStamp < endDate
	end)
end

---@param info CharacterIconInfo
---@param size string?
---@param class string?
---@return string
function CharacterIcon._makeImage(info, size, class)
	local imageOptions = Array.append({},
		info.file,
		info.display,
		size,
		info.link and ('link=' .. info.link) or nil,
		Logic.isNotEmpty(class) and 'class=' .. class or nil
	)

	return '[[File:' .. table.concat(imageOptions, '|') .. ']]'
end

---

---@param args IconArguments
---@return string?
function CharacterIcon.Icon(args)
	if Logic.isEmpty(args.character) then
		return nil
	end

	local characterIcons = Data[args.character:lower()]

	assert(characterIcons, 'Character:"' .. args.character .. '" was not found')

	local iconInfo = CharacterIcon._getCharacterIconInfo(characterIcons, args.date) or {}

	assert(iconInfo.file, 'Character:"' .. args.character .. '" has no file set')

	return CharacterIcon._makeImage(iconInfo, args.size, args.class)
		.. (Logic.readBool(args.addTextLink)
			and ('&nbsp;' .. Page.makeInternalLink(iconInfo.display or args.character, iconInfo.link or args.character))
			or '')
end

return Class.export(CharacterIcon)
