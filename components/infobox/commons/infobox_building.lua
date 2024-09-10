---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Building
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Hotkey = require('Module:Hotkey')
local String = require('Module:StringUtils')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class BuildingInfobox: BasicInfobox
local Building = Class.new(BasicInfobox)

---Entry point
---@param frame Frame
---@return Html
function Building.run(frame)
	local building = Building(frame)
	return building:createInfobox()
end

---creates the infobox
---@return Html
function Building:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			image = args.image,
			imageDefault = args.default,
			imageDark = args.imagedark or args.imagedarkmode,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = (args.informationType or 'Building') .. ' Information'},
		Cell{name = 'Built by', content = {args.builtby}},
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
			id = 'defense',
			children = {
				Cell{name = 'Defense', content = {args.defense}},
			}
		},
		Customizable{
			id = 'attack',
			children = {
				Cell{name = 'Attack', content = {args.attack}},
			}
		},
		Customizable{
			id = 'requirements',
			children = {
				Cell{name = 'Requirements', content = {args.requires}},
			}
		},
		Customizable{
			id = 'builds',
			children = {
				Cell{name = 'Builds', content = {args.builds}},
			}
		},
		Customizable{
			id = 'unlocks',
			children = {
				Cell{name = 'Unlocks', content = {args.unlocks}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	infobox:categories('Buildings')
	infobox:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return infobox:build(widgets)
end

---@param args table
---@return string[]
function Building:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Building:_getHotkeys(args)
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

---@param args table
---@return string
function Building:nameDisplay(args)
	return args.name
end

---@param args table
function Building:setLpdbData(args)
end

return Building
