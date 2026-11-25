---
-- @Liquipedia
-- page=Module:Widget/Infobox/Organizers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Cell = Lua.import('Module:Widget/Infobox/Cell')
local Link = Lua.import('Module:Widget/Basic/Link')

local Helpers = {}
local defaultProps = {
	args = {},
}

---@param props {args: table<string, string>}
---@return Renderable[]
local function Organizers(props)
	local args = props.args
	local organizers = Helpers._createOrganizers(args)
	local title = Table.size(organizers) == 1 and 'Organizer' or 'Organizers'

	return {Cell{name = title, children = organizers}}
end

---@private
---@param args table
---@return Renderable[]
function Helpers._createOrganizers(args)
	local organizers = {}

	for prefix, organizer in Table.iter.pairsByPrefix(args, 'organizer', {requireIndex = false}) do
		table.insert(organizers, Helpers._createLink(organizer, args[prefix .. '-name'], args[prefix .. '-link']))
	end

	return organizers
end

---@private
---@param id string?
---@param name string?
---@param link string?
---@return Renderable?
function Helpers._createLink(id, name, link)
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

return Component.component(Organizers, defaultProps)
