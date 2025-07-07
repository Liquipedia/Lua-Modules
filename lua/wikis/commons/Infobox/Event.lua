---
-- @Liquipedia
-- page=Module:Infobox/Event
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local TextSanitizer = Lua.import('Module:TextSanitizer')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology
local Organizers = Widgets.Organizers
local Accommodation = Widgets.Accommodation
local Venue = Widgets.Venue
local Location = Widgets.Location
local Link = Lua.import('Module:Widget/Basic/Link')

---@class InfoboxEvent: BasicInfobox
local Event = Class.new(BasicInfobox)

---@return Html
function Event:createInfobox()
	local args = self.args
	self:_parseArgs()

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Event Information'},
		Cell{
			name = 'Series',
			content = {
				self:createSeriesDisplay({
					displayManualIcons = Logic.readBool(args.display_series_icon_from_manual_input),
					series = args.series,
					abbreviation = args.abbreviation,
					icon = args.icon,
					iconDark = args.icondark or args.icondarkmode,
				}, self.iconDisplay),
				self:createSeriesDisplay{
					series = args.series2,
					abbreviation = args.abbreviation2,
				},
			}
		},
		Customizable{
			id = 'organizers',
			children = {Organizers{args = args}},
		},
		Customizable{
			id = 'sponsors',
			children = {
				Cell{name = 'Sponsor(s)', content = self:getAllArgsForBase(args, 'sponsor')},
			}
		},
		Customizable{
			id = 'gamesettings',
			children = {
				Cell{name = 'Game', content = {Link{
					link = Game.link{game = self.data.game, useDefault = false},
					children = {Game.name{game = self.data.game, useDefault = false}}
				}}},
			}
		},
		Location{
			args = args,
			infoboxType = 'Events',
			shouldSetCategory = self:shouldStore(args),
		},
		Venue{args = args},
		Cell{name = 'Format', content = {args.format}},
		Customizable{id = 'dates', children = {
				Cell{name = 'Date', content = {args.date}},
				Cell{name = 'Start Date', content = {args.sdate}},
				Cell{name = 'End Date', content = {args.edate}},
			},
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if Table.isNotEmpty(self.links) then
					return {
						Title{children = 'Links'},
						Widgets.Links{links = self.links}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
		Customizable{id = 'chronology', children = {
				Builder{
					builder = function()
						if self:_isChronologySet(args.previous, args.next) then
							return {
								Title{children = 'Chronology'},
								Chronology{
									links = Table.filterByKey(args, function(key)
										return type(key) == 'string' and (key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
									end)
								}
							}
						end
					end
				}
			}
		},
		Accommodation{
			args = args,
			startDate = self.data.startDate,
			endDate = self.data.endDate,
			name = self.data.name,
		},
	}

	self.name = TextSanitizer.stripHTML(self.name)

	self:bottom(self:createBottomContent())

	if self:shouldStore(args) then
		self:categories(unpack(self:_getCategories(args)))
		self:_setLpdbData(args, self.links)
	end

	return mw.html.create()
		:node(self:build(widgets))
end

function Event:_parseArgs()
	local args = self.args

	args.abbreviation = self:_fetchAbbreviation()

	-- Split venue from legacy format to new format.
	-- Legacy format is a wiki-code string that can include an external link
	-- New format has |venue=, |venuename= and |venuelink= as different parameters.
	-- This should be removed once there's been a bot run to change this.
	if not args.venuename and args.venue and args.venue:sub(1, 2) == '[[' then
		-- Remove [[]] and split on `|`
		local splitVenue = mw.text.split(args.venue:gsub('%[%[', ''):gsub('%]%]', ''), '|')
		args.venue = splitVenue[1]
		args.venuename = splitVenue[2]
	elseif not args.venuelink and args.venue and args.venue:sub(1, 1) == '[' then
		-- Remove [] and split on space
		local splitVenue = mw.text.split(args.venue:gsub('%[', ''):gsub('%]', ''), ' ')
		args.venuelink = splitVenue[1]
		table.remove(splitVenue, 1)
		args.venue = table.concat(splitVenue, ' ')
	end

	local data = {
		name = TextSanitizer.stripHTML(args.name),
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
		--might be set before infobox
		status = args.status or Variables.varDefault('tournament_status'),
		game = Game.toIdentifier{game = args.game, useDefault = false},
		startDate = self:_cleanDate(args.sdate) or self:_cleanDate(args.date),
		endDate = self:_cleanDate(args.edate) or self:_cleanDate(args.date),
	}

	self.data = data

	data.icon, data.iconDark, self.iconDisplay = self:getIcons{
		displayManualIcons = Logic.readBool(args.display_series_icon_from_manual_input),
		series = args.series,
		abbreviation = args.abbreviation,
		icon = args.icon,
		iconDark = args.icondark or args.icondarkmode,
	}

	self.links = Links.transform(args)

	self:customParseArguments(args)
end

---@param args table
function Event:customParseArguments(args)
end

---@param args table
---@return string[]
function Event:_getCategories(args)
	local categories = {'Events'}
	if String.isEmpty(args.country) then
		table.insert(categories, 'Events without location')
	end

	return Array.extend(categories, self:getWikiCategories(args))
end

--- Allows for overriding this functionality
---@param args table
---@return boolean
function Event:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@return table
function Event:addToLpdb(lpdbData, args)
	return lpdbData
end

---@param args table
---@param links table
function Event:_setLpdbData(args, links)
	local lpdbData = {
		type = 'event',
		name = self.name,
		image = self.data.icon,
		imagedark = self.data.iconDark,
		date = self.data.endDate or DateExt.defaultDate,
		extradata = {
			series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
			series2 = args.series2 and mw.ext.TeamLiquidIntegration.resolve_redirect(args.series2) or nil,
			seriespage = Page.pageifyLink(args.series),
			serieslist = {
				Page.pageifyLink(args.series),
				Page.pageifyLink(args.series2),
			},
			previous = self:_getPageNameFromChronology(args.previous),
			previous2 = self:_getPageNameFromChronology(args.previous2),
			next = self:_getPageNameFromChronology(args.next),
			next2 = self:_getPageNameFromChronology(args.next2),
			game = self.data.game,
			organizers = Table.mapValues(
				Event:_getNamedTableofAllArgsForBase(args, 'organizer'),
				mw.ext.TeamLiquidIntegration.resolve_redirect
			),
			startdate = self.data.startDate or self.data.endDate or DateExt.defaultDate,
			enddate = self.data.endDate or DateExt.defaultDate,
			sortdate = self.data.endDate or DateExt.defaultDate,
			location = mw.text.decode(Locale.formatLocation({city = args.city or args.location, country = args.country})),
			location2 = mw.text.decode(Locale.formatLocation({city = args.city2 or args.location2, country = args.country2})),
			venue = args.venue,
			locations = Locale.formatLocations(args),
			status = self.data.status,
			format = TextSanitizer.stripHTML(args.format),
			links = Links.makeFullLinksForTableItems(links or {}),
		}
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_datapoint('event_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@param args table
---@param base string
---@return table
function Event:_getNamedTableofAllArgsForBase(args, base)
	local basedArgs = self:getAllArgsForBase(args, base)
	local namedArgs = {}
	for key, item in pairs(basedArgs) do
		namedArgs[base .. key] = item
	end
	return namedArgs
end

---@param seriesArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@param iconDisplay string?
---@return string?
function Event:createSeriesDisplay(seriesArgs, iconDisplay)
	if String.isEmpty(seriesArgs.series) then
		return nil
	end

	iconDisplay = iconDisplay or self:_createSeriesIcon(seriesArgs)

	if String.isNotEmpty(iconDisplay) then
		iconDisplay = iconDisplay .. ' '
	end

	local abbreviation = Logic.emptyOr(seriesArgs.abbreviation, seriesArgs.series)
	local pageDisplay = Page.makeInternalLink({onlyIfExists = true}, abbreviation, seriesArgs.series)
		or abbreviation

	return iconDisplay .. pageDisplay
end

---@param iconArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@return string?
---@return string?
---@return string?
function Event:getIcons(iconArgs)
	local display = self:_createSeriesIcon(iconArgs)

	if not display then
		return iconArgs.icon, iconArgs.iconDark, nil
	end

	local icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate{
		icon = iconArgs.icon,
		iconDark = iconArgs.iconDark,
		stringOfExpandedTemplate = display
	}

	if String.isNotEmpty(trackingCategory) then
		table.insert(self.warnings, 'Missing icon while icondark is set.')
	end

	return icon, iconDark, display
end

---@param iconArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@return string?
function Event:_createSeriesIcon(iconArgs)
	if String.isEmpty(iconArgs.series) then
		return ''
	end
	local series = iconArgs.series
	---@cast series -nil

	local output = LeagueIcon.display{
		icon = iconArgs.displayManualIcons and iconArgs.icon or nil,
		iconDark = iconArgs.displayManualIcons and iconArgs.iconDark or nil,
		series = series,
		abbreviation = iconArgs.abbreviation,
		date = self.data.endDate,
		options = {noLink = not Page.exists(series)}
	}

	return output == LeagueIcon.display{} and '' or output
end

---@param date string?
---@return string?
function Event:_cleanDate(date)
	if self:_isUnknownDate(date) then
		return nil
	end
	return ReferenceCleaner.clean{input = date}
end

---@param date string?
---@return boolean
function Event:_isUnknownDate(date)
	return date == nil or string.lower(date) == 'tba' or string.lower(date) == 'tbd'
end

---@param previous string?
---@param next string?
---@return boolean
function Event:_isChronologySet(previous, next)
	-- We only need to check the first of these params, since it makes no sense
	-- to set next2 and not next, etc.
	return not (String.isEmpty(previous) and String.isEmpty(next))
end

-- Given the format `pagename|displayname`, returns pagename or the parameter, otherwise
---@param item string?
---@return string?
function Event:_getPageNameFromChronology(item)
	if item == nil then return end

	return mw.ext.TeamLiquidIntegration.resolve_redirect(mw.text.split(item, '|')[1])
end

-- Given a series, query its abbreviation if abbreviation is not set manually
---@return string?
function Event:_fetchAbbreviation()
	if not String.isEmpty(self.args.abbreviation) then
		return self.args.abbreviation
	elseif String.isEmpty(self.args.series) then
		return nil
	end

	local series = string.gsub(mw.ext.TeamLiquidIntegration.resolve_redirect(self.args.series), ' ', '_')
	local seriesData = mw.ext.LiquipediaDB.lpdb('series', {
			conditions = '[[pagename::' .. series .. ']] AND [[abbreviation::!]]',
			query = 'abbreviation',
			limit = 1
		})
	if type(seriesData) == 'table' and seriesData[1] then
		return seriesData[1].abbreviation
	end
end

return Event
