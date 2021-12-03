-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon
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
local Customizable = Widgets.Customizable

local Weapon = Class.new(BasicInfobox)

function Weapon.run(frame)
	local weapon = Weapon(frame)
	return weapon:createInfobox()
end

function Weapon:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
	Header{
		name = self:nameDisplay(args),
		image = args.image,
		imageDefault = args.default,
		imageDark = args.imagedark or args.imagedarkmode,
		imageDefaultDark = args.defaultdark or args.defaultdarkmode,
	},
	Center{content = {args.caption}},
	Title{name = (args.informationType or 'Weapon') .. ' Information'},
	Cell{
		name = 'Class',
		content = self:getAllArgsForBase(args, 'class', {makeLink = true}),
	},
	Cell{
		name = 'Origin',
		content = {self:_createLocation(args.origin)},
	},
	Cell{name = 'Price', content = {args.price}},
	Cell{name = 'Kill Award', content = {args.killaward}},
	Cell{name = 'Base Damage', content = {args.damage}},
	Cell{name = 'Magazine Size', content = {args.magsize}},
	Cell{name = 'Ammo Capacity', content = {args.ammocap}},
	Cell{name = 'Reload Speed', content = {args.reloadspeed}},
	Cell{name = 'Rate of Fire', content = {args.rateoffire}},
	Cell{name = 'Firing Mode', content = {args.firemode}},
	Customizable{
		id = 'side',
		children = {
			Cell{name = 'Side', content = {args.side}},
		}
	},
	Customizable{
		id = 'user',
		children = {
			Cell{
				name = 'User(s)',
				content = self:getAllArgsForBase(args, 'user', {makeLink = true}),
			}
		}
	},
	Customizable{id = 'custom', children = {}},
	Center{content = {args.footnotes}},
	}

	infobox:categories('Weapons')
	infobox:categories(unpack(self:getWikiCategories(args)))

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return builtInfobox
end

function Weapon:_createLocation(location)
	if location == nil then
	return ''
end

return Flags.Icon({flag = location, shouldLink = true}) .. '&nbsp;' ..
	'[[:Category:' .. location .. '|' .. location .. ']]'
end

function Weapon:getWikiCategories(args)
	return {}
end

function Weapon:nameDisplay(args)
	return args.name
end

function Weapon:setLpdbData(args)
end

return Weapon
