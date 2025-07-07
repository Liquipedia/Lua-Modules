---
-- @Liquipedia
-- page=Module:Widget/Infobox/Location
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')

local Cell = Lua.import('Module:Widget/Infobox/Cell')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class InfoboxLocationWidget: Widget
---@operator call(table):InfoboxLocationWidget
---@field args table<string, string>
---@field infoboxType string
---@field shouldSetCategory boolean
---@field showTbdOnEmpty boolean
local Location = Class.new(Widget)
Location.defaultProps = {
	args = {},
	infoboxType = 'Tournament',
	shouldSetCategory = true,
	showTbdOnEmpty = true,
}

-- Format:
-- {
--	region: Region or continent
--	country: the country
--	location: the city or place
-- }
---@return Widget?
function Location:render()
	return Cell{name = 'Location', children = self:_getLocations()}
end

---@return Widget[]
function Location:_getLocations()
	local props = self.props
	local args = props.args
	if Logic.isEmpty(args.country) and props.showTbdOnEmpty then
		return {HtmlWidgets.Abbr{title = 'To be determined (or to be decided)', children = {'TBD'}}}
	end

	local locations = {}

	args.city1 = args.city1 or args.location1 or args.city or args.location

	for _, country, index in Table.iter.pairsByPrefix(args, 'country', {requireIndex = false}) do
		local nationality = Flags.getLocalisation(country)

		if Logic.isEmpty(nationality) then
			mw.ext.TeamLiquidIntegration.add_category('Unrecognised Country')
		else
			local location = Logic.nilIfEmpty(args['city' .. index]) or Logic.nilIfEmpty(args['location' .. index])
			local countryName = Flags.CountryName{flag = country}
			local displayText = Logic.nilIfEmpty(location or countryName) or country

			if props.shouldSetCategory then
				mw.ext.TeamLiquidIntegration.add_category(nationality .. ' ' .. props.infoboxType)
			end
			table.insert(locations, HtmlWidgets.Fragment{children = {
				Flags.Icon{flag = country, shouldLink = true},
				'&nbsp;',
				displayText,
			}})
		end
	end

	return locations
end

return Location
