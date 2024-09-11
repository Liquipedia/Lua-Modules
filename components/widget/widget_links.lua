---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local UtilLinks = Lua.import('Module:Links')
local Widget = Lua.import('Module:Widget')

---@class LinksWidget: Widget
---@operator call({content: table<string, string>, variant: string?}): LinksWidget
---@field links table<string, string>
---@field variant string?
local Links = Class.new(
	Widget,
	function(self, input)
		self.links = Table.copy(input.content)
		self.variant = input.variant
	end
)

local PRIORITY_GROUPS = Lua.import('Module:Links/PriorityGroups', {loadData = true})

---@param injector WidgetInjector?
---@return {[1]: Html}
function Links:make(injector)
	local infoboxLinks = mw.html.create('div')
	infoboxLinks	:addClass('infobox-center')
					:addClass('infobox-icons')

	for _, group in Table.iter.spairs(PRIORITY_GROUPS) do
		for _, key in ipairs(group) do
			if self.links[key] ~= nil then
				infoboxLinks:wikitext(' ' .. self:_makeLink(key, self.links[key]))
				-- Remove link from the collection
				self.links[key] = nil

				local index = 2
				while self.links[key .. index] ~= nil do
					infoboxLinks:wikitext(' ' .. self:_makeLink(key, self.links[key .. index]))
					-- Remove link from the collection
					self.links[key .. index] = nil
					index = index + 1
				end
			end
		end
	end

	for key, value in Table.iter.spairs(self.links) do
		infoboxLinks:wikitext(' ' .. self:_makeLink(key, value))
	end

	return {
		mw.html.create('div'):node(infoboxLinks)
	}
end

---@param key string
---@param value string?
---@return string
function Links:_makeLink(key, value)
	key = UtilLinks.removeAppendedNumber(key)
	return '[' .. UtilLinks.makeFullLink(key, value, self.variant) ..
		' ' .. UtilLinks.makeIcon(key) .. ']'
end

return Links
