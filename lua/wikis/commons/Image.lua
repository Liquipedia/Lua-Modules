---
-- @Liquipedia
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
---@param imageLightMode string?
---@param imageDarkMode string?
---@param options ImageOptions?
---@return string?
function Image.display(imageLightMode, imageDarkMode, options)
	options = options or {}
	if Logic.isNumeric(options.size) then
		options.size = options.size .. 'px'
	end
	if String.isEmpty(imageLightMode) and String.isEmpty(imageDarkMode) then
		return
	elseif String.isEmpty(imageLightMode) or String.isEmpty(imageDarkMode) or imageLightMode == imageDarkMode then
		return Image._make(String.nilIfEmpty(imageLightMode) or imageDarkMode, options)
	end

	return Image._make(imageLightMode, options, 'show-when-light-mode')
		.. Image._make(imageDarkMode, options, 'show-when-dark-mode')
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
