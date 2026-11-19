---
-- @Liquipedia
-- page=Module:Widget/Infobox/Links
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')
local UtilLinks = Lua.import('Module:Links')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local Title = Lua.import('Module:Widget/Infobox/Title')

local PRIORITY_GROUPS = Lua.import('Module:Links/PriorityGroups', {loadData = true})

local Helpers = {}

---@param props {links: table<string, string>, variant: string?}
---@return Renderable[]?
local function Links(props)
	if Table.isEmpty(props.links) then
		return nil
	end
	local linkInputs = Table.copy(props.links)

	local links = {}

	for _, group in Table.iter.spairs(PRIORITY_GROUPS) do
		Array.forEach(group, function(key)
			if not linkInputs[key] then
				return
			end

			table.insert(links, Helpers._makeLink(props, key, linkInputs[key]))
			-- Remove link from the collection
			linkInputs[key] = nil

			local index = 2
			while linkInputs[key .. index] ~= nil do
				table.insert(links, Helpers._makeLink(props, key, linkInputs[key .. index]))
				-- Remove link from the collection
				linkInputs[key .. index] = nil
				index = index + 1
			end
		end)
	end

	for key, value in Table.iter.spairs(linkInputs) do
		table.insert(links, Helpers._makeLink(props, key, value))
	end

	return {
		Title{children = 'Links'},
		Html.Div{
			children = {
				Html.Div{
					classes = {'infobox-center', 'infobox-icons'},
					children = Array.interleave(links, ' '),
				}
			}
		},
	}
end

---@private
---@param props {variant: string?}
---@param key string
---@param value string?
---@return VNode
function Helpers._makeLink(props, key, value)
	key = UtilLinks.removeAppendedNumber(key)
	return Link{
		linktype = 'external',
		link = UtilLinks.makeFullLink{
			platform = key,
			id = value,
			variant = props.variant,
		},
		children = {UtilLinks.makeIcon(key)},
	}
end

return Component.component(Links)
