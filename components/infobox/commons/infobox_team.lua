---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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
local _defaultEarningsFunctionUsed = false
local _earnings = {}
local _totalEarnings

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
				Builder{
					builder = function()
						_defaultEarningsFunctionUsed = true
						_totalEarnings, _earnings = Earnings.calculateForTeam{
							team = self.pagename or self.name,
							perYear = true,
							queryHistorical = args.queryEarningsHistorical
						}
						Variables.varDefine('earnings', _totalEarnings) -- needed for SMW
						local totalEarnings
						if _totalEarnings > 0 then
							totalEarnings = '$' .. Language:formatNum(_totalEarnings)
						end
						return {
							Cell{name = 'Approx. Total Winnings', content = {totalEarnings}}
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
	local earnings = _totalEarnings

	local team = args.teamtemplate or self.pagename
	local teamTemplate
	if team and mw.ext.TeamTemplate.teamexists(team) then
		local teamRaw = mw.ext.TeamTemplate.raw(team)
		teamTemplate = teamRaw.historicaltemplate or teamRaw.templatename
	end

	local lpdbData = {
		name = name,
		location = self:getStandardLocationValue(args.location),
		location2 = self:getStandardLocationValue(args.location2),
		region = args.region,
		locations = Locale.formatLocations(args),
		logo = args.image,
		logodark = args.imagedark or args.imagedarkmode,
		earnings = earnings,
		createdate = args.created,
		disbanddate = ReferenceCleaner.clean(args.disbanded),
		coach = args.coaches,
		manager = args.manager,
		template = teamTemplate,
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {}, 'team')
		),
		extradata = {}
	}

	for year, earningsOfYear in pairs(_earnings or {}) do
		lpdbData.extradata['earningsin' .. year] = earningsOfYear
		--make these values available for smw storage
		Variables.varDefine('earningsin' .. year, earningsOfYear)
	end

	lpdbData = self:addToLpdb(lpdbData, args)

	if String.isEmpty(lpdbData.earnings) and not _defaultEarningsFunctionUsed then
		error('Since your wiki uses a customized earnings function you ' ..
			'have to set the LPDB earnings storage in the custom module')
	end

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_team('team_' .. self.name, lpdbData)
end

--- Allows for overriding this functionality
function Team:defineCustomPageVariables(args)
end

function Team:addToLpdb(lpdbData, args)
	return lpdbData
end

function Team:shouldStore(args)
	return Namespace.isMain()
end

return Team
