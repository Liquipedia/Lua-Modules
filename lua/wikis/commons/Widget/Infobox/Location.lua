---
-- @Liquipedia
-- page=Module:Widget/Infobox/Location
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Cell = Lua.import('Module:Widget/Infobox/Cell')
local Html = Lua.import('Module:Widget/Html')

---@class InfoboxLocationWidgetProps
---@field args table<string, string>
---@field showTbdOnEmpty boolean?

local Helpers = {}
local defaultProps = {
	args = {},
	showTbdOnEmpty = true,
}

-- Format:
-- {
--	region: Region or continent
--	country: the country
--	location: the city or place
-- }
---@param props InfoboxLocationWidgetProps
---@return Renderable?
local function Location(props)
	return Cell{name = 'Location', children = Helpers._getLocations(props)}
end

---@private
---@param props InfoboxLocationWidgetProps
---@return Renderable[]
function Helpers._getLocations(props)
	local args = props.args
	if Logic.isEmpty(args.country) and props.showTbdOnEmpty then
		return {Html.Abbr{title = 'To be determined (or to be decided)', children = {'TBD'}}}
	end

	local locations = {}

	args.city1 = args.city1 or args.location1 or args.city or args.location

	for _, country, index in Table.iter.pairsByPrefix(args, 'country', {requireIndex = false}) do
		local nationality = Flags.getLocalisation(country)

		if Logic.isNotEmpty(nationality) then
			local location = Logic.nilIfEmpty(args['city' .. index]) or Logic.nilIfEmpty(args['location' .. index])
			local displayText = Logic.nilIfEmpty(location or Flags.CountryName{flag = country}) or country

			table.insert(locations, Html.Fragment{children = {
				Flags.Icon{flag = country, shouldLink = true},
				'&nbsp;',
				displayText,
			}})
		end
	end

	return locations
end

return Component.component(Location, defaultProps)
