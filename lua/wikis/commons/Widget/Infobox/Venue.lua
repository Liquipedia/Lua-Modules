---
-- @Liquipedia
-- page=Module:Widget/Infobox/Venue
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')

local Cell = Lua.import('Module:Widget/Infobox/Cell')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class InfoboxVenueWidget: Widget
---@operator call(table):InfoboxVenueWidget
---@field args table<string, string>
local Venue = Class.new(Widget)
Venue.defaultProps = {
	args = {},
}

---@return Widget?
function Venue:render()
	local args = self.props.args

	local venues = Array.map(Venue._parseVenues(args), Venue._createLink)

	return {Cell{name = 'Venue', children = venues}}
end


---@param args table
---@return {id: string?, name: string?, link: string?, description: string?}[]
function Venue._parseVenues(args)
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

---@param props {id: string?, name: string, link: string, desc: string}
---@return Widget?
function Venue._createLink(props)
	local id = props.id
	if Logic.isEmpty(id) then return nil end
	---@cast id -nil

	local description
	if Logic.isNotEmpty(props.desc) then
		description = HtmlWidgets.Br{
			children = {
				HtmlWidgets.Span{
					children = {
						HtmlWidgets.Span{
							children = {
								props.desc
							}
						}
					}
				}
			}
		}
	end

	local displayName = Logic.nilIfEmpty(props.name) or id
	---@type string|Widget
	local display = displayName

	if Page.exists(id) or id:find('^[Ww]ikipedia:') then
		display = Link{link = id, children = {displayName}}
	elseif not Logic.isEmpty(props.link) then
		display = Link{linktype = 'external', link = props.link, children = {displayName}}
	end

	return HtmlWidgets.Fragment{children = {
		display,
		description
	}}
end

return Venue
