---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Item
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class ItemInfobox: BasicInfobox
local Item = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Item.run(frame)
	local item = Item(frame)
	return item:createInfobox()
end

---@return string
function Item:createInfobox()
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
					size = args.imagesize
				},
			}
		},
		Customizable{
			id = 'caption',
			children = {
				Center{content = {args.caption}},
			}
		},
		Customizable{
			id = 'info',
			children = {
				Title{name = 'Item Information'},
				Cell{name = 'Type', content = {args.type}},
				Cell{name = 'Rarity', content = {args.rarity}},
				Cell{name = 'Level', content = {args.level}},
				Cell{name = 'Class', content = {args.class}},
				Cell{name = 'Cost', content = {args.cost}},
				Cell{name = 'Released', content = {args.release}},
			}
		},
		Customizable{
			id = 'attributes',
			children = {
				Title{name = 'Attributes'},
			}
		},
		Customizable{
			id = 'ability',
			children = {
				Title{name = 'Ability'},
			}
		},
		Customizable{
			id = 'availability',
			children = {
				Title{name = 'Availability'},
			}
		},
		Customizable{
			id = 'maps',
			children = {
				Title{name = 'Maps'},
			}
		},
		Customizable{
			id = 'recipe',
			children = {
				Title{name = 'Recipe'},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	self:categories('Items')
	self:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string[]
function Item:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Item:nameDisplay(args)
	return args.name
end

---@param args table
function Item:setLpdbData(args)
end

return Item
