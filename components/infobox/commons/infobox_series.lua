---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Series
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')
local Locale = require('Module:Locale')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Localisation = require('Module:Localisation')
local Links = require('Module:Links')
local String = require('Module:String')
local Flags = require('Module:Flags')
local BasicInfobox = require('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

local Series = Class.new(BasicInfobox)

function Series.run(frame)
	local series = Series(frame)
	return series:createInfobox(frame)
end

function Series:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Series Information'},
		Customizable{
			id = 'liquipediatier',
			children = {
				Cell{
					name = 'Liquipedia Tier',
					content = {
						self:_createTier(args.liquipediatier, (args.liquipediatiertype or args.tiertype))
					}
				},
			}
		},
		Cell{
			name = 'Organizer',
			content = self:getAllArgsForBase(args, 'organizer'),
			options = {
				makeLink = true
			}
		},
		Cell{
			name = 'Location',
			content = {
				self:_createLocation(args.country, args.city)
			}
		},
		Cell{
			name = 'Date',
			content = {
				args.date
			}
		},
		Cell{
			name = 'Start Date',
			content = {
				args.sdate or args.launched
			}
		},
		Cell{
			name = 'End Date',
			content = {
				args.edate or args.defunct
			}
		},
		Cell{
			name = 'Sponsor(s)',
			content = self:getAllArgsForBase(args, 'sponsor')
		},
		Customizable{
			id = 'custom',
			children = {}
		},
		Builder{
			builder = function()
				local links = Links.transform(args)
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		}
	}

	if Namespace.isMain() then
		local lpdbData = {
			name = self.name,
			image = args.image,
			imagedark = args.imagedark or args.imagedarkmode,
			abbreviation = args.abbreviation or args.acronym,
			icon = args.icon,
			icondark = args.icondark or args.icondarkmode,
			game = args.game,
			type = args.type,
			location = Locale.formatLocation({city = args.city, country = args.country}),
			location2 = Locale.formatLocation({city = args.city2, country = args.country2}),
			previous = args.previous,
			previous2 = args.previous2,
			next = args.next,
			next2 = args.next2,
			prizepool = args.prizepool,
			liquipediatier = args.liquipediatier,
			publishertier = args.publishertier,
			launcheddate = ReferenceCleaner.clean(args.launcheddate or args.sdate),
			defunctdate = ReferenceCleaner.clean(args.defunctdate or args.edate),
			defunctfate = ReferenceCleaner.clean(args.defunctfate),
			organizers = mw.ext.LiquipediaDB.lpdb_create_json({
				organizer1 = args.organizer or args.organizer1,
				organizer2 = args.organizer2,
				organizer3 = args.organizer3,
				organizer4 = args.organizer4,
				organizer5 = args.organizer5,
			}),
			sponsors = mw.ext.LiquipediaDB.lpdb_create_json({
				sponsor1 = args.sponsor1,
				sponsor2 = args.sponsor2,
				sponsor3 = args.sponsor3,
				sponsor4 = args.sponsor4,
				sponsor5 = args.sponsor5,
			}),
			links = mw.ext.LiquipediaDB.lpdb_create_json({
				discord = Links.makeFullLink('discord', args.discord),
				facebook = Links.makeFullLink('facebook', args.facebook),
				instagram = Links.makeFullLink('instagram', args.instagram),
				twitch = Links.makeFullLink('twitch', args.twitch),
				twitter = Links.makeFullLink('twitter', args.twitter),
				website = Links.makeFullLink('website', args.website),
				weibo = Links.makeFullLink('weibo', args.weibo),
				vk = Links.makeFullLink('vk', args.vk),
				youtube = Links.makeFullLink('youtube', args.youtube),
			}),
		}
		lpdbData = self:_getIconFromLeagueIconSmall(frame, lpdbData)

		lpdbData = self:addToLpdb(lpdbData)
		mw.ext.LiquipediaDB.lpdb_series('series_' .. self.name, lpdbData)

		infobox:categories(
			'Tournament series',
			self:_setCountryCategories(args.country),
			self:_setCountryCategories(args.country2),
			self:_setCountryCategories(args.country3),
			self:_setCountryCategories(args.country4),
			self:_setCountryCategories(args.country5)
		)
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

--- Allows for overriding this functionality
function Series:addToLpdb(lpdbData)
	return lpdbData
end

function Series:_createTier(tier, tierType)
	if tier == nil or tier == '' then
		return ''
	end

	local output = ''

	local hasTierType = tierType ~= nil and tierType ~= ''

	if hasTierType then
		local tierTypeDisplay = Template.safeExpand(self.infobox.frame, 'TierDisplay/' .. tierType)
		output = output .. '[[' .. tierTypeDisplay .. '_Tournaments|' .. tierTypeDisplay .. ']]'
		output = output .. '&nbsp;('

	end

	local tierDisplay = Template.safeExpand(self.infobox.frame, 'TierDisplay/' .. tier)
	output = output .. '[[' .. tierDisplay .. '_Tournaments|' .. tierDisplay .. ']]'

	if hasTierType then
		output = output .. ')'
	end

	return output
end

function Series:_getIconFromLeagueIconSmall(frame, lpdbData)
	local icon = lpdbData.icon
	local iconDark = lpdbData.icondark

	if String.isEmpty(icon) then
		local series = lpdbData.name:lower()
		local iconSmallTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. series,
			{ date = lpdbData.defunctfate }
		)
		--extract series icon from template:LeagueIconSmall
		icon = mw.text.split(iconSmallTemplate, 'File:')
		icon = mw.text.split(icon[2] or '', '|')
		icon = icon[1]
	end
	--when Template:LeagueIconSmall has darkmodeicons retrieve that too

	lpdbData.icon = icon
	lpdbData.icondark = iconDark

	return lpdbData
end

function Series:_createLocation(country, city)
	if country == nil or country == '' then
		return ''
	end

	return Flags.Icon({flag = country, shouldLink = true}) .. '&nbsp;' .. (city or country)
end

function Series:_setCountryCategories(country)
	if country == nil or country == '' then
		return ''
	end

	local countryAdjective = Localisation.getLocalisation({ shouldReturnSimpleError = true }, country)
	if countryAdjective == 'error' then
		return 'Unrecognised Country||' .. country
	end

	return countryAdjective .. ' Tournaments'
end

return Series
