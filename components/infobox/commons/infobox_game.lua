---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})
local Links = Lua.import('Module:Links', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class GameInfobox: BasicInfobox
local Game = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Game.run(frame)
	local game = Game(frame)
	return game:createInfobox()
end

---@return Html
function Game:createInfobox()
	local infobox = self.infobox
	local args = self.args
	local links = Links.transform(args)

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
		Cell{name = 'Publisher', content = self:getAllArgsForBase(args, 'publisher')},
		Cell{name = 'Release Date(s)', content = self:getAllArgsForBase(args, 'releasedate')},
		Cell{name = 'Platforms', content = self:getAllArgsForBase(args, 'platform')},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Games')
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

return Game
