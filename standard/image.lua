---
-- @Liquipedia
-- wiki=commons
-- page=Module:Image
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local Image = {}

---@class ImageOptions
---@field size string|number?
---@field class string?
---@field link string?
---@field alt string?
---@field type string?
---@field border string?
---@field caption string?
---@field alignment string?
---@field location string?

---generates an image display for a given lightmode and darkmode file
---@param image string?
---@param imageDark string?
---@param options ImageOptions?
---@return string?
function Image.display(image, imageDark, options)
	options = options or {}
	if Logic.isNumeric(options.size) then
		options.size = options.size .. 'px'
	end
	if String.isEmpty(image) and String.isEmpty(imageDark) then
		return
	elseif String.isEmpty(image) or String.isEmpty(imageDark) or image == imageDark then
		return Image._make(String.nilIfEmpty(image) or imageDark, options)
	end

	return Image._make(image, options, 'show-when-light-mode')
		.. Image._make(imageDark, options, 'show-when-dark-mode')
end

---@param image string?
---@param options ImageOptions
---@param themeClass string?
---@return string
function Image._make(image, options, themeClass)
	local class = table.concat(Array.append({String.nilIfEmpty(options.class)}, themeClass), ' ')
	local parts = Array.append({'File:' .. image},
		String.nilIfEmpty(options.type),
		String.nilIfEmpty(options.border),
		String.nilIfEmpty(options.location),
		String.nilIfEmpty(options.alignment),
		Logic.isNotEmpty(options.size) and options.size or nil,
		options.link and ('link=' .. options.link) or nil,--specifically allow empty string for unlinking
		Logic.isNotEmpty(options.alt) and ('alt=' .. options.alt) or nil,
		Logic.isNotEmpty(class) and ('class=' .. class) or nil,
		String.nilIfEmpty(options.caption)
	)

	return '[[' .. table.concat(parts, '|') .. ']]'
end

return Image
