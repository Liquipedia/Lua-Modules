---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Flags = require('Module:Flags')
local Localisation = require('Module:Localisation')
local String = require('Module:StringUtils')
local WarningBox = require('Module:WarningBox')
local Variables = require('Module:Variables')
local Earnings = require('Module:Earnings')
local BasicInfobox = require('Module:Infobox/Basic')

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
		Cell{name = 'Coaches', content = {args.coaches}},
		Cell{name = 'Coach', content = {args.coach}},
		Cell{name = 'Director', content = {args.director}},
		Cell{name = 'Manager', content = {args.manager}},
		Cell{name = 'Team Captain', content = {args.captain}},
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

	if Namespace.isMain() then
		infobox:categories('Teams')
		infobox:categories(unpack(self:getWikiCategories(args)))
	end

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
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
		demonym = Localisation.getLocalisation(locationDisplay)
		locationDisplay = '[[:Category:' .. locationDisplay
			.. '|' .. locationDisplay .. ']]'
	end

	return Flags.Icon({flag = location, shouldLink = true}) ..
			'&nbsp;' ..
			(String.isNotEmpty(demonym) and '[[Category:' .. demonym .. ' Teams]]' or '') ..
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

	local lpdbData = {
		name = name,
		location = self:getStandardLocationValue(args.location),
		location2 = self:getStandardLocationValue(args.location2),
		logo = args.image,
		logodark = args.imagedark or args.imagedarkmode,
		earnings = earnings,
		createdate = args.created,
		disbanddate = args.disbanded,
		coach = args.coaches,
		manager = args.manager,
		region = args.region,
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

return Team
