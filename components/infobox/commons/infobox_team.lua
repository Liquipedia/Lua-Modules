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
local Flags = require('Module:Flags')._Flag
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

function Team.run(frame)
	local team = Team(frame)
	return team:createInfobox(frame)
end

function Team:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{name = args.name, image = args.image},
		Center{content = {args.caption}},
		Title{name = 'Team Information'},
		Cell{
			name = 'Location',
			content = {
				self:_createLocation(args.location),
				self:_createLocation(args.location2)
			}
		},
		Cell{
			name = 'Region',
			content = {
				self:_createRegion(args.region)
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
				links = Links.transform(args)
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

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
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

	return Flags(location) ..
		'&nbsp;' ..
		'[[:Category:' .. location .. '|' .. location .. ']]'
end

return Team
