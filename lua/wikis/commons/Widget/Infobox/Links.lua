---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local UtilLinks = Lua.import('Module:Links')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class LinksWidget: Widget
---@operator call(table): LinksWidget
local Links = Class.new(Widget)

local PRIORITY_GROUPS = Lua.import('Module:Links/PriorityGroups', {loadData = true})

---@return Widget?
function Links:render()
	if Table.isEmpty(self.props.links) then
		return nil
	end
	local linkInputs = Table.copy(self.props.links)

	local links = {}

	for _, group in Table.iter.spairs(PRIORITY_GROUPS) do
		Array.forEach(group, function(key)
			if not linkInputs[key] then
				return
			end

			table.insert(links, self:_makeLink(key, linkInputs[key]))
			-- Remove link from the collection
			linkInputs[key] = nil

			local index = 2
			while linkInputs[key .. index] ~= nil do
				table.insert(links, self:_makeLink(key, linkInputs[key .. index]))
				-- Remove link from the collection
				linkInputs[key .. index] = nil
				index = index + 1
			end
		end)
	end

	for key, value in Table.iter.spairs(linkInputs) do
		table.insert(links, self:_makeLink(key, value))
	end

	return HtmlWidgets.Div{children = {HtmlWidgets.Div{
		classes = {'infobox-center', 'infobox-icons'},
		children = Array.interleave(links, ' ')
	}}}
end

---@param key string
---@param value string?
---@return string
function Links:_makeLink(key, value)
	key = UtilLinks.removeAppendedNumber(key)
	return Link{
		linktype = 'external',
		link = UtilLinks.makeFullLink(key, value, self.props.variant),
		children = {UtilLinks.makeIcon(key)},
	}
end

return Links
