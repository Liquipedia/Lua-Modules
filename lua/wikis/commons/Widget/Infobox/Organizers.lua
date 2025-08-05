---
-- @Liquipedia
-- page=Module:Widget/Infobox/Organizers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')

local Cell = Lua.import('Module:Widget/Infobox/Cell')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class InfoboxOrganizersWidget: Widget
---@operator call(table):InfoboxOrganizersWidget
---@field args table<string, string>
local Organizers = Class.new(Widget)
Organizers.defaultProps = {
	args = {},
}

---@return Widget?
function Organizers:render()
	local args = self.props.args
	local organizers = self:_createOrganizers(args)
	local title = Table.size(organizers) == 1 and 'Organizer' or 'Organizers'

	return {Cell{name = title, children = organizers}}
end

---@param args table
---@return string[]
function Organizers:_createOrganizers(args)
	local organizers = {}

	for prefix, organizer in Table.iter.pairsByPrefix(args, 'organizer', {requireIndex = false}) do
		table.insert(organizers, Organizers._createLink(organizer, args[prefix .. '-name'], args[prefix .. '-link']))
	end

	return organizers
end

---@param id string?
---@param name string?
---@param link string?
---@return Widget|string?
function Organizers._createLink(id, name, link)
	if Logic.isEmpty(id) then return nil end
	---@cast id -nil

	local display = Logic.nilIfEmpty(name) or id

	if Page.exists(id) or id:find('^[Ww]ikipedia:') then
		return Link{link = id, children = {display}}
	elseif not Logic.isEmpty(link) then
		return Link{linktype = 'external', link = link, children = {display}}
	end

	return display
end

return Organizers
