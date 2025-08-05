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
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local SeriesAbbreviation = Lua.import('Module:Infobox/Extension/SeriesAbbreviation')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TextSanitizer = Lua.import('Module:TextSanitizer')
local Variables = Lua.import('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Accommodation = Widgets.Accommodation
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Center = Widgets.Center
local Chronology = Widgets.Chronology
local Customizable = Widgets.Customizable
local Header = Widgets.Header
local Location = Widgets.Location
local Organizers = Widgets.Organizers
local SeriesDisplay = Widgets.SeriesDisplay
local SeriesIcon = Widgets.SeriesIcon
local Title = Widgets.Title
local Venue = Widgets.Venue
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
				SeriesDisplay{
					displayManualIcons = Logic.readBool(args.display_series_icon_from_manual_input),
					series = args.series,
					abbreviation = args.abbreviation,
					icon = args.icon,
					iconDark = args.icondark or args.icondarkmode,
					iconDisplay = self.iconDisplay
				},
				SeriesDisplay{
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
			children = {Builder{
				builder = function()
					local games = Array.map(self.data.games, function(game)
						local gameLink = Game.link{game = game, useDefault = false}
						return Link{
							link = gameLink,
							children = {Game.name{game = game, useDefault = false}}
						}
					end)
					return Cell{name = 'Game' .. (#games > 1 and 's' or ''), content = games}
				end
			}}
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
		Widgets.Links{links = self.links},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
		Customizable{id = 'chronology', children = {
			Chronology{args = args, showTitle = true}
		}},
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

	args.abbreviation = SeriesAbbreviation.fetch{series = args.series, abbreviation = args.abbreviation}

	local data = {
		name = TextSanitizer.stripHTML(args.name),
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''),
		--might be set before infobox
		status = args.status or Variables.varDefault('tournament_status'),
		games = Array.map(self:getAllArgsForBase(args, 'game'),function(game)
			return Game.toIdentifier{game = args.game, useDefault = false}
		end),
		startDate = ReferenceCleaner.cleanDateIfKnown{date = args.sdate}
			or ReferenceCleaner.cleanDateIfKnown{date = args.date},
		endDate = ReferenceCleaner.cleanDateIfKnown{date = args.edate}
			or ReferenceCleaner.cleanDateIfKnown{date = args.date},
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
			games = self.data.games,
			organizers = Table.mapValues(
				self:getAllArgsForBase(args, 'organizer'),
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

---@param iconArgs {displayManualIcons:boolean, series:string?, abbreviation:string?, icon:string?, iconDark:string?}
---@return string?
---@return string?
---@return string?
function Event:getIcons(iconArgs)
	local display = tostring(SeriesIcon(iconArgs))

	if Logic.isEmpty(display) then
		return iconArgs.icon, iconArgs.iconDark, nil
	end

	local icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate{
		icon = iconArgs.icon,
		iconDark = iconArgs.iconDark,
		stringOfExpandedTemplate = display,
	}

	if String.isNotEmpty(trackingCategory) then
		table.insert(self.warnings, 'Missing icon while icondark is set.')
	end

	return icon, iconDark, display
end

return Event
