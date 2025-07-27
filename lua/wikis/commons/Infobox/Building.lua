---
-- @Liquipedia
-- page=Module:Infobox/Building
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local Hotkey = Lua.import('Module:Hotkey')
local String = Lua.import('Module:StringUtils')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
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
---@return string
function Building:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			image = args.image,
			imageDefault = args.default,
			imageDark = args.imagedark or args.imagedarkmode,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			subHeader = self:subHeaderDisplay(args),
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Building') .. ' Information'},
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
		Center{children = {args.footnotes}},
	}

	self:categories('Buildings')
	self:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return self:build(widgets)
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
			display = Hotkey.hotkey2{hotkey1 = args.hotkey, hotkey2 = args.hotkey2, seperator = 'slash'}
		else
			display = Hotkey.hotkey{hotkey = args.hotkey}
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

--- Allows for overriding this functionality
---@param args table
---@return string?
function Building:subHeaderDisplay(args)
	return args.title
end

return Building
