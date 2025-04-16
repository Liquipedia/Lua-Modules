---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Unit
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Hotkey = require('Module:Hotkey')
local String = require('Module:StringUtils')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class UnitInfobox: BasicInfobox
local Unit = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Unit.run(frame)
	local unit = Unit(frame)
	return unit:createInfobox()
end

---@return string
function Unit:createInfobox()
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
				Center{children = {args.caption}},
			}
		},
		Title{children = (args.informationType or 'Unit') .. ' Information'},
		Customizable{
			id = 'type',
			children = {
				Cell{name = 'Type', content = {args.type}},
			}
		},
		Cell{name = 'Description', content = {args.description}},
		Customizable{
			id = 'builtfrom',
			children = {
				Cell{name = 'Built From', content = {args.builtfrom}},
			}
		},
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
		Center{children = {args.footnotes}},
		Customizable{id = 'customcontent', children = {}},
	}

	self:categories('Units')
	self:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string[]
function Unit:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Unit:_getHotkeys(args)
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey2{hotkey1 = args.hotkey, hotkey2 = args.hotkey2, seperator = 'slash'}
		else
			display = Hotkey.hotkey{hotkey = args.hotkey}
		end
	end

	return display
end

---@param args table
---@return string?
function Unit:nameDisplay(args)
	return args.name
end

---@param args table
function Unit:setLpdbData(args)
end

--- Allows for overriding this functionality
---@param args table
---@return string?
function Unit:subHeaderDisplay(args)
	return args.title
end

return Unit
