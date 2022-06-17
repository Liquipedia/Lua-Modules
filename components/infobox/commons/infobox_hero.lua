---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Hero
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local BasicInfobox = require('Module:Infobox/Basic')
local Flags = require('Module:Flags')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

local Hero = Class.new(BasicInfobox)

function Hero.run(frame)
	local hero = Hero(frame)
	return hero:createInfobox()
end

function Hero:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			subHeader = self:subHeader(args),
			image = args.image,
			imageDefault = args.default,
			imageDark = args.imagedark or args.imagedarkmode,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = (args.informationType or 'Hero') .. ' Information'},
		Cell{name = 'Real Name', content = {args.realname}},
		Customizable{
			id = 'country',
			children = {
				Cell{
					name = 'Country',
					content = {
						self:_createLocation(args.country)
					}
				},
			}
		},
		Customizable{
			id = 'role',
			children = {
				Cell{
					name = 'Role',
					content = {args.role}
				},
			}
		},
		Customizable{
			id = 'class',
			children = {
				Cell{
					name = 'Class',
					content = {args.class}
				},
			}
		},
		Customizable{
			id = 'release',
			children = {
				Cell{
					name = 'Release Date',
					content = {args.releasedate}
				},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	infobox:categories('Heroes')
	infobox:categories(unpack(self:getWikiCategories(args)))

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return builtInfobox
end

function Hero:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon({flag = location, shouldLink = true}) .. '&nbsp;' ..
		'[[:Category:' .. location .. '|' .. location .. ']]'
end

function Hero:subHeader(args)
	return args.title
end

function Hero:getWikiCategories(args)
	return {}
end

function Hero:nameDisplay(args)
	return args.name
end

function Hero:setLpdbData(args)
end

return Hero
