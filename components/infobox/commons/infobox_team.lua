---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Flags = require('Module:Flags')
local Region = require('Module:Region')
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
local _region
local _location = {}

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
					content = {self:_createRegion(args.region)}
				}
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
						return error('You have not implemented a custom earnings function for your wiki')
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
				Title{name = 'Achievements'},
				Center{content = {args.achievements}}
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
	end

	return builtInfobox
end

function Team:_createRegion(region)
	region = Region.run({region = region, country = _location[1]})
	if type(region) == 'table' then
		_region = region.region
		return region.display
	end
end

function Team:_createLocation(location)
	if location == nil or location == '' then
		return ''
	end

	location = Flags._CountryName(location) or location
	table.insert(_location, location)

	return Flags._Flag(location) ..
			'&nbsp;' ..
			'[[:Category:' .. location .. '|' .. location .. ']]'
end

function Team:_setLpdbData(args, links)
	local name = args.romanized_name or self.name

	local lpdbData = {
		name = name,
		location = _location[1],
		location2 = _location[2],
		logo = args.image,
		logodark = args.imagedark or args.imagedarkmode,
		createdate = args.created,
		disbanddate = args.disbanded,
		coach = args.coaches,
		manager = args.manager,
		region = _region,
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {}, 'team')
		),
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	if lpdbData['earnings'] == nil then
		return error('You need to set the LPDB earnings storage in the custom module')
	end

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_team('team_' .. self.name, lpdbData)
end

function Team:addToLpdb(lpdbData, args)
	return lpdbData
end

return Team
