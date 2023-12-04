---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
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
local _defaultEarningsFunctionUsed = false

---@enum statuses
local Status = {
	ACTIVE = 'active',
	DISBANDED = 'disbanded',
}

local _warnings = {}

function Team.run(frame)
	local team = Team(frame)
	return team:createInfobox()
end

function Team:createInfobox()
	local infobox = self.infobox
	local args = self.args

	--- Transform data
	-- Links
	local links = Links.transform(args)

	-- Team Information
	local team = args.teamtemplate or self.pagename
	self.teamTemplate = mw.ext.TeamTemplate.raw(team) or {}

	args.imagedark = args.imagedark or args.imagedarkmode or args.image or self.teamTemplate.imagedark
	args.image = args.image or self.teamTemplate.image
	args.teamcardimagedark = self.teamTemplate.imagedark or args.teamcardimagedark or args.teamcardimage
	args.teamcardimage = self.teamTemplate.image or args.teamcardimage

	-- Display
	local widgets = {
		Header{
			name = args.name,
			image = not Game.isDefaultTeamLogo{logo = args.image} and args.image or nil,
			imageDefault = args.default,
			imageDark = not Game.isDefaultTeamLogo{logo = args.imagedark} and args.imagedark or nil,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Team Information'},
		Customizable{id = 'topcustomcontent', children = {}},
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
				Builder{
					builder = function()
						_defaultEarningsFunctionUsed = true
						self.totalEarnings, self.earnings = Earnings.calculateForTeam{
							team = self.pagename or self.name,
							perYear = true,
							queryHistorical = args.queryEarningsHistorical,
							doNotIncludePlayerEarnings = args.doNotIncludePlayerEarnings,
						}
						local totalEarningsDisplay
						if self.totalEarnings > 0 then
							totalEarningsDisplay = '$' .. Language:formatNum(self.totalEarnings)
						end
						return {
							Customizable{id = 'earningscell',
								children = {
									Cell{name = Abbreviation.make(
										'Approx. Total Winnings',
										'Includes individual player earnings won&#10;while representing this team'
									),
									content = {totalEarningsDisplay}}
								}
							}
						}
					end
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

	-- Categories
	if self:shouldStore(args) then
		infobox:categories('Teams')
		infobox:categories(unpack(self:getWikiCategories(args)))
	end

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	-- Store LPDB data and Wiki-variables
	if self:shouldStore(args) then
		self:_setLpdbData(args, links)
		self:defineCustomPageVariables(args)
	end

	return tostring(builtInfobox) .. WarningBox.displayAll(_warnings)
end

function Team:_createRegion(region)
	if String.isEmpty(region) then
		return
	end

	return Template.safeExpand(self.infobox.frame, 'Region', {region})
end

function Team:_createLocation(location)
	if String.isEmpty(location)then
		return
	end

	local locationDisplay = self:getStandardLocationValue(location)
	local demonym
	if String.isNotEmpty(locationDisplay) then
		demonym = Flags.getLocalisation(locationDisplay)
		locationDisplay = '[[:Category:' .. locationDisplay
			.. '|' .. locationDisplay .. ']]'
	end

	if String.isNotEmpty(demonym) and self:shouldStore(self.args) then
		self.infobox:categories(demonym .. ' Teams')
	end

	return Flags.Icon({flag = location, shouldLink = true}) ..
			'&nbsp;' ..
			(locationDisplay or '')
end

function Team:getStandardLocationValue(location)
	if String.isEmpty(location) then
		return
	end

	local locationToStore = Flags.CountryName(location)

	if String.isEmpty(locationToStore) then
		table.insert(
			_warnings,
			'"' .. location .. '" is not supported as a value for locations'
		)
		return
	end

	return locationToStore
end

function Team:_setLpdbData(args, links)
	local name = args.romanized_name or self.name
	local earnings = self.totalEarnings

	local lpdbData = {
		name = name,
		location = self:getStandardLocationValue(args.location),
		location2 = self:getStandardLocationValue(args.location2),
		region = args.region,
		locations = Locale.formatLocations(args),
		logo = args.image,
		logodark = args.imagedark,
		textlesslogo = args.teamcardimage,
		textlesslogodark = args.teamcardimagedark,
		earnings = earnings,
		earningsbyyear = {},
		createdate = args.created,
		disbanddate = ReferenceCleaner.clean(args.disbanded),
		coach = args.coaches or args.coach,
		manager = args.manager,
		template = self.teamTemplate.historicaltemplate or self.teamTemplate.templatename,
		status = args.disbanded and Status.DISBANDED or Status.ACTIVE,
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {}, 'team')
		),
		extradata = {}
	}

	for year, earningsOfYear in pairs(self.earnings or {}) do
		lpdbData.extradata['earningsin' .. year] = earningsOfYear
		lpdbData.earningsbyyear[year] = earningsOfYear
	end

	lpdbData = self:addToLpdb(lpdbData, args)

	if String.isEmpty(lpdbData.earnings) and not _defaultEarningsFunctionUsed then
		error('Since your wiki uses a customized earnings function you ' ..
			'have to set the LPDB earnings storage in the custom module')
	end

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	lpdbData.earningsbyyear = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.earningsbyyear or {})
	mw.ext.LiquipediaDB.lpdb_team('team_' .. self.name, lpdbData)
end

--- Allows for overriding this functionality
function Team:defineCustomPageVariables(args)
end

function Team:addToLpdb(lpdbData, args)
	return lpdbData
end

function Team:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

return Team
