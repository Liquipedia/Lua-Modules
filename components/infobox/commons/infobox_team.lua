---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Template = require('Module:Template')
local String = require('Module:StringUtils')
local WarningBox = require('Module:WarningBox')
local Variables = require('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})
local Earnings = Lua.import('Module:Earnings', {requireDevIfEnabled = true})
local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})
local Links = Lua.import('Module:Links', {requireDevIfEnabled = true})
local Locale = Lua.import('Module:Locale', {requireDevIfEnabled = true})
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

local Team = Class.new(BasicInfobox)

local _LINK_VARIANT = 'team'

local Language = mw.language.new('en')

local _warnings = {}

function Team.run(frame)
	local team = Team(frame)
	return team:createInfobox()
end

function Team:createInfobox()
	local infobox = self.infobox
	local args = self.args
	-- Need links in LPDB, so declare them outside of display code
	local links = Links.transform(args)

	self.totalEarnings, self.yearlyEarnings = self:calculateEarnings(args)

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDefault = args.default,
			imageDark = args.imagedark or args.imagedarkmode,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Team Information'},
		Cell{
			name = 'Location',
			content = {
				self:_createLocation(args.location),
				self:_createLocation(args.location2)
			}
		},
		Customizable{
			id = 'region',
			children = {
				Cell{
					name = 'Region',
					content = {
						self:_createRegion(args.region)
					}
				},
			}
		},
		Customizable{
			id = 'staff',
			children = {
				Cell{name = 'Coaches', content = {args.coaches}},
				Cell{name = 'Coach', content = {args.coach}},
				Cell{name = 'Director', content = {args.director}},
				Cell{name = 'Manager', content = {args.manager}},
				Cell{name = 'Team Captain', content = {args.captain}},
			}
		},
		Customizable{
			id = 'earnings',
			children = {
				Customizable{id = 'earningscell',
					children = {
						Cell{name = Abbreviation.make(
							'Approx. Total Winnings',
							'Includes individual player earnings won&#10;while representing this team'
						),
						content = {self.totalEarnings > 0 and '$' .. Language:formatNum(self.totalEarnings) or nil}}
					}
				}
			}
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links, variant = _LINK_VARIANT}
					}
				end
			end
		},
		Customizable{
			id = 'achievements',
			children = {
				Builder{
					builder = function()
						if String.isNotEmpty(args.achievements) then
							return {
								Title{name = 'Achievements'},
								Center{content = {args.achievements}}
							}
						end
					end
				}
			}
		},
		Customizable{
			id = 'history',
			children = {
				Builder{
					builder = function()
						if args.created or args.disbanded then
							return {
								Title{name = 'History'},
								Cell{name = 'Created', content = {args.created}},
								Cell{name = 'Disbanded', content = {args.disbanded}}
							}
						end
					end
				}
			}
		},
		Builder{
			builder = function()
				if args.trades then
					return {
						Center{content = {args.trades}}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{content = {args.footnotes}},
	}
	infobox:bottom(self:createBottomContent())

	if self:shouldStore(args) then
		infobox:categories('Teams')
		infobox:categories(unpack(self:getWikiCategories(args)))
	end

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if self:shouldStore(args) then
		self:_setLpdbData(args, links)
		self:defineCustomPageVariables(args)
	end

	return tostring(builtInfobox) .. WarningBox.displayAll(_warnings)
end

function Team:_createRegion(region)
	if region == nil or region == '' then
		return ''
	end

	return Template.safeExpand(self.infobox.frame, 'Region', {region})
end

function Team:_createLocation(location)
	if location == nil or location == '' then
		return ''
	end

	local locationDisplay = self:getStandardLocationValue(location)
	local demonym
	if String.isNotEmpty(locationDisplay) then
		demonym = Flags.getLocalisation(locationDisplay)
		locationDisplay = '[[:Category:' .. locationDisplay
			.. '|' .. locationDisplay .. ']]'
	end

	local category
	if String.isNotEmpty(demonym) and self:shouldStore(self.args) then
		category = '[[Category:' .. demonym .. ' Teams]]'
	end

	return Flags.Icon({flag = location, shouldLink = true}) ..
			'&nbsp;' ..
			(category or '') ..
			(locationDisplay or '')
end

function Team:getStandardLocationValue(location)
	if String.isEmpty(location) then
		return nil
	end

	local locationToStore = Flags.CountryName(location)

	if String.isEmpty(locationToStore) then
		table.insert(
			_warnings,
			'"' .. location .. '" is not supported as a value for locations'
		)
		locationToStore = nil
	end

	return locationToStore
end

function Team:_setLpdbData(args, links)
	local name = args.romanized_name or self.name
	local earnings = self.totalEarnings

	local team = args.teamtemplate or self.pagename
	local teamTemplate
	local textlessImage, textlessImageDark
	if team and mw.ext.TeamTemplate.teamexists(team) then
		local teamRaw = mw.ext.TeamTemplate.raw(team)
		teamTemplate = teamRaw.historicaltemplate or teamRaw.templatename
		textlessImage, textlessImageDark = teamRaw.image, teamRaw.imagedark
	end

	local lpdbData = {
		name = name,
		location = self:getStandardLocationValue(args.location),
		location2 = self:getStandardLocationValue(args.location2),
		region = args.region,
		locations = Locale.formatLocations(args),
		logo = args.image or textlessImage,
		logodark = args.imagedark or args.imagedarkmode or args.image or textlessImageDark,
		textlesslogo = textlessImage or args.teamcardimage,
		textlesslogodark = textlessImageDark or args.teamcardimagedark or args.teamcardimage,
		earnings = earnings,
		createdate = args.created,
		disbanddate = ReferenceCleaner.clean(args.disbanded),
		coach = args.coaches or args.coach,
		manager = args.manager,
		template = teamTemplate,
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {}, 'team')
		),
		extradata = {}
	}

	Variables.varDefine('earnings', self.totalEarnings or 0) -- needed for SMW
	for year, earningsOfYear in pairs(self.yearlyEarnings or {}) do
		lpdbData.extradata['earningsin' .. year] = earningsOfYear
		--make these values available for SMW storage
		Variables.varDefine('earningsin' .. year, earningsOfYear)
	end

	lpdbData = self:addToLpdb(lpdbData, args)

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_team('team_' .. self.name, lpdbData)
end

--- Allows for overriding this functionality
function Team:defineCustomPageVariables(args)
end

function Team:calculateEarnings(args)
	return Earnings.calculateForTeam{
		team = self.pagename or self.name,
		perYear = true,
		queryHistorical = args.queryEarningsHistorical
	}
end

function Team:addToLpdb(lpdbData, args)
	return lpdbData
end

function Team:shouldStore(args)
	return Namespace.isMain()
end

return Team
