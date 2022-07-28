---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Namespace = require('Module:Namespace')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Game = Class.new(BasicInfobox)

function Game.run(frame)
	local game = Game(frame)
	return game:createInfobox()
end

function Game:createInfobox()
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
		Title{name = 'Game Information'},
		Cell{name = 'Developer', content = self:getAllArgsForBase(args, 'developer')},
		Cell{name = 'Release Date(s)', content = self:getAllArgsForBase(args, 'releasedate')},
		Cell{name = 'Platforms', content = self:getAllArgsForBase(args, 'platform')},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Games')
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

return Game
