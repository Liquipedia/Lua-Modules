---
-- @Liquipedia
-- page=Module:Widget/Infobox/Accommodation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Info = Lua.import('Module:Info', {loadData = true})
local Locale = Lua.import('Module:Locale')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')

local Button = Lua.import('Module:Widget/Basic/Button')
local Center = Lua.import('Module:Widget/Infobox/Center')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Title = Lua.import('Module:Widget/Infobox/Title')

local STAY22_LINK = 'https://www.stay22.com/allez/roam?aid=liquipedia&campaign=${wiki}_${page}'..
	'&address=${address}&checkin=${checkin}&checkout=${checkout}'

---@class InfoboxAccommodationWidget: Widget
---@operator call(table):InfoboxAccommodationWidget
---@field args table<string, string>
---@field startDate string?
---@field endDate string?
---@field name string?
local Accommodation = Class.new(Widget)
Accommodation.defaultProps = {
	args = {},
}

---@return Widget?
function Accommodation:render()
	local props = self.props
	local args = props.args

	local startDate, endDate = props.startDate, props.endDate
	if not startDate or not endDate then
		return
	end
	local onlineOrOffline = tostring(args.type or ''):lower()
	if not onlineOrOffline:match('offline') then
		return
	end
	local locations = Locale.formatLocations(args)
	-- If more than one city, don't show the accommodation section, as it is unclear which one the link is for
	if locations.city2 then
		return
	end
	-- Must have a venue or a city to show the accommodation section
	if not locations.venue1 and not locations.city1 then
		return
	end

	local function invalidLocation(location)
		-- Not allowed to contain HTML Tags
		return (location or ''):lower():match('<')
	end
	if invalidLocation(locations.venue1) or invalidLocation(locations.city1) then
		return
	end

	-- if the event is finished do not show the button
	local osdateCutoff = DateExt.parseIsoDate(endDate) --[[@as osdateparam]]
	osdateCutoff.day = osdateCutoff.day + 1
	if os.difftime(os.time(), os.time(osdateCutoff)) > 0 then
		return
	end

	local addressParts = {}
	-- Only add the venue if there is exactly one venue, otherwise we'll only use the city + country
	table.insert(addressParts, not locations.venue2 and locations.venue1 or nil)
	table.insert(addressParts, locations.city1)
	table.insert(addressParts, Flags.CountryName{flag = locations.country1 or locations.region1})

	-- Start date for the accommodation should be the day before the event, but at most 4 days before the event
	-- End date for the accommodation should be 1 day after the event
	local osdateEnd = DateExt.parseIsoDate(endDate) --[[@as osdateparam]]
	osdateEnd.day = osdateEnd.day + 1
	local osdateFictiveStart = DateExt.parseIsoDate(endDate) --[[@as osdateparam]]
	osdateFictiveStart.day = osdateFictiveStart.day - 4
	local osdateRealStart = DateExt.parseIsoDate(startDate) --[[@as osdateparam]]
	osdateRealStart.day = osdateRealStart.day - 1

	local osdateStart
	if os.difftime(os.time(osdateFictiveStart), os.time(osdateRealStart)) > 0 then
		osdateStart = osdateFictiveStart
	else
		osdateStart = osdateRealStart
	end

	local function buildStay22Link(address, checkin, checkout)
		return String.interpolate(STAY22_LINK, {
			wiki = Info.wikiName,
			page = props.name,
			address = address,
			checkin = checkin,
			checkout = checkout,
		})
	end

	return {
		Title{children = 'Accommodation'},
		Center{children = {
			Button{
				linktype = 'external',
				variant = 'themed',
				size = 'md',
				link = buildStay22Link(
					table.concat(addressParts, ', '),
					DateExt.toYmdInUtc(osdateStart),
					DateExt.toYmdInUtc(osdateEnd)
				),
				children = {
					IconFa{iconName = 'accommodation'},
					' ',
					'Find My Accommodation',
				}
			},
			Center{children = 'Bookings earn Liquipedia a small commission.'}
		}}
	}
end

return Accommodation
