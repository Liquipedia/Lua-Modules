---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Unit
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local Hotkey = require('Module:Hotkey')
local String = require('Module:StringUtils')
local BasicInfobox = require('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Unit = Class.new(BasicInfobox)

function Unit.run(frame)
	local unit = Unit(frame)
	return unit:createInfobox()
end

function Unit:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Customizable{
			id = 'header',
			children = {
				Header{
					name = self:nameDisplay(args),
					image = args.image,
					imageDefault = args.default,
					imageDark = args.imagedark or args.imagedarkmode,
					imageDefaultDark = args.defaultdark or args.defaultdarkmode,
					subHeader = self:subHeaderDisplay(args),
					size = args.imagesize,
				},
			}
		},
		Customizable{
			id = 'caption',
			children = {
				Center{content = {args.caption}},
			}
		},
		Title{name = (args.informationType or 'Unit') .. ' Information'},
		Customizable{
			id = 'type',
			children = {
				Cell{name = 'Type', content = {args.type}},
			}
		},
		Cell{name = 'Description', content = {args.description}},
		Cell{name = 'Built From', content = {args.builtfrom}},
		Customizable{
			id = 'requirements',
			children = {
				Cell{name = 'Requirements', content = {args.requires}},
			}
		},
		Customizable{
			id = 'cost',
			children = {
				Cell{name = 'Cost', content = {args.cost}},
			}
		},
		Customizable{
			id = 'hotkey',
			children = {
				Cell{name = 'Hotkey', content = {self:_getHotkeys(args)}},
			}
		},
		Customizable{
			id = 'attack',
			children = {
				Cell{name = 'Attack', content = {args.attack}},
			}
		},
		Customizable{
			id = 'defense',
			children = {
				Cell{name = 'Defense', content = {args.defense}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	infobox:categories('Units')
	infobox:categories(unpack(self:getWikiCategories(args)))

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return builtInfobox
end

function Unit:getWikiCategories(args)
	return {}
end

function Unit:_getHotkeys(args)
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey2(args.hotkey, args.hotkey2, 'slash')
		else
			display = Hotkey.hotkey(args.hotkey)
		end
	end

	return display
end

function Unit:nameDisplay(args)
	return args.name
end

function Unit:setLpdbData(args)
end

--- Allows for overriding this functionality
function Unit:subHeaderDisplay(args)
	return args.title
end

return Unit
