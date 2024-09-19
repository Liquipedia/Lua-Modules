---
-- @Liquipedia
-- wiki=commons
-- page=Module:InlineIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local InlineIconAndText = require('Module:Widget/InlineIconAndText')
local ManualData = Lua.requireIfExists('Module:InlineIcon/ManualData', {loadData = true})

local InlineIcon = {}

---@param type string
---@param lookup string
---@param extraInfo string?
---@return string
function InlineIcon.display(type, lookup, extraInfo)
	assert(type, 'Type parameter is required.')
	assert(lookup, 'Lookup parameter is required.')

	local data
	if type == 'H' then
		data = InlineIcon.queryHeroData(lookup)
	elseif type == 'A' then
		-- TODO: Query Ability Data
	elseif type == 'I' then
		data = InlineIcon.queryItemData(lookup)
	elseif type == 'M' then
		data = ManualData[lookup]
	else
		error('Invalid type parameter.')
	end
	assert(data, 'Data not found.')

	local icon
	if data.iconType == 'image' then
		local IconImage = require('Module:Widget/Icon/Image')
		icon = IconImage{
			imageLight = data.iconLight,
			imageDark = data.iconDark,
			link = data.link,
		}
	elseif data.iconType == 'fa' then
		local IconFa = require('Module:Widget/Icon/Fontawesome')
		icon = IconFa{
			iconName = data.icon,
			link = data.link,
		}
	end

	if not data.text then
		return tostring(icon)
	end

	return tostring(InlineIconAndText{
		icon = icon,
		text = data.text,
		link = data.link,
	})
end

---@param name string
---@return table
function InlineIcon.queryItemData(name)
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
function InlineIcon.queryHeroData(name)
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

return Class.export(InlineIcon)
