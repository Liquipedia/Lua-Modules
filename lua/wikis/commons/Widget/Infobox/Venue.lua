---
-- @Liquipedia
-- page=Module:Widget/Infobox/Venue
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Cell = Lua.import('Module:Widget/Infobox/Cell')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Helpers = {}
local defaultProps = {
	args = {},
}

---@param props {args: table}
---@return Renderable?
local function Venue(props)
	local args = props.args

	local venues = Array.map(Helpers._parseVenues(args), Helpers._createLink)

	return Cell{name = 'Venue', options = {collapsible = #venues > 2}, children = venues}
end

---@private
---@param args table
---@return {id: string?, name: string?, link: string?, desc: string?}[]
function Helpers._parseVenues(args)
	local venues = {}
	for prefix, venueName in Table.iter.pairsByPrefix(args, 'venue', {requireIndex = false}) do
		table.insert(venues, {
			id = venueName,
			name = args[prefix .. 'name'],
			link = args[prefix .. 'link'],
			desc = args[prefix .. 'desc'],
		})
	end
	return venues
end

---@private
---@param props {id: string?, name: string?, link: string?, desc: string?}
---@return Renderable?
function Helpers._createLink(props)
	local id = props.id
	if Logic.isEmpty(id) then return nil end
	---@cast id -nil

	local description
	if Logic.isNotEmpty(props.desc) then
		description = {
			Html.Br{},
			Html.Small{
				children = {
					Html.Small{
						children = {'(', props.desc, ')'}
					}
				}
			}
		}
	end

	local displayName = Logic.nilIfEmpty(props.name) or id
	---@type Renderable
	local display = displayName

	if Page.exists(id) or id:find('^[Ww]ikipedia:') then
		display = Link{link = id, children = {displayName}}
	elseif not Logic.isEmpty(props.link) then
		display = Link{linktype = 'external', link = props.link, children = {displayName}}
	end

	return Html.Fragment{children = WidgetUtil.collect(
		display,
		description
	)}
end

return Component.component(Venue, defaultProps)
