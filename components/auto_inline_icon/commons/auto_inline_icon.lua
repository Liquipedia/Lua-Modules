---
-- @Liquipedia
-- wiki=commons
-- page=Module:AutoInlineIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local InlineIconAndText = require('Module:Widget/Misc/InlineIconAndText')
local ManualData = Lua.requireIfExists('Module:InlineIcon/ManualData', {loadData = true})

local AutoInlineIcon = {}

---@param options table
---@param category string
---@param lookup string
---@param extraInfo string?
---@return Widget
function AutoInlineIcon.display(options, category, lookup, extraInfo)
	assert(category, 'Category parameter is required.')
	assert(lookup, 'Lookup parameter is required.')

	local data = AutoInlineIcon._getDataRetrevalFunction(category)(lookup)
	assert(data, 'Data not found.')

	local icon = AutoInlineIcon._iconCreator(data)

	if not data.text or Logic.readBool(options.onlyicon) then
		return icon
	end

	return InlineIconAndText{
		icon = icon,
		text = data.text,
		link = data.link,
	}
end

---@param category string
---@return fun(name: string): table
function AutoInlineIcon._getDataRetrevalFunction(category)
	local categoryMapper = {
		H = AutoInlineIcon._queryHeroData,
		A = function(name)
			error('Abilities not yet implemented.')
		end,
		I = AutoInlineIcon._queryItemData,
		M = function(name)
			return ManualData[name]
		end,
	}
	assert(categoryMapper[category], 'Invalid category parameter.')
	return categoryMapper[category]
end

---@param data table
---@return IconWidget
function AutoInlineIcon._iconCreator(data)
	if data.iconType == 'image' then
		local IconImage = require('Module:Widget/Image/Icon/Image')
		return IconImage{
			imageLight = data.iconLight,
			imageDark = data.iconDark,
			link = data.link,
		}
	elseif data.iconType == 'fa' then
		local IconFa = require('Module:Widget/Image/Icon/Fontawesome')
		return IconFa{
			iconName = data.icon,
			link = data.link,
		}
	end
	error('Invalid iconType.')
end

---@param name string
---@return table
function AutoInlineIcon._queryItemData(name)
	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::item]] AND [[name::'.. name ..']]',
	})[1]
	assert(data, 'Item not found.')

	return {
		iconType = 'image',
		link = data.pagename,
		text = data.name,
		iconLight = data.image,
		iconDark = data.imagedark,
	}
end

---@param name string
---@return table
function AutoInlineIcon._queryHeroData(name)
	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::character]] AND [[name::'.. name ..']]',
	})[1]
	assert(data, 'Hero not found.')

	return {
		iconType = 'image',
		link = data.pagename,
		text = data.name,
		iconLight = data.extradata.icon or data.image,
		iconDark = data.extradata.icon or data.imagedark,
	}
end

return Class.export(AutoInlineIcon)
