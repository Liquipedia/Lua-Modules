---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Manufacturer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class ManufacturerInfobox: BasicInfobox
local Manufacturer = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Manufacturer.run(frame)
	local manufacturer = Manufacturer(frame)
	return manufacturer:createInfobox()
end

---@return Html
function Manufacturer:createInfobox()
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
		Title{name = (args.informationType or 'Manufacturer') .. ' Information'},
		Cell{name = 'Former Name(s)', content = {args.formernames}},
		Cell{name = 'Description', content = {args.description}},
		Cell{name = 'Season(s)', content = {args.seasons}},
		Cell{name = 'Engine Total', content = {args.enginetotal}},
		Cell{name = 'Status', content = {args.status}},
		Customizable{
			id = 'history',
			children = {
				Builder{
					builder = function()
						if args.founded or args.dissolved then
							return {
								Title{name = 'History'},
								Cell{name = 'Founded', content = {args.founded}},
								Cell{name = 'Dissolved', content = {args.dissolved}}
							}
						end
					end
				}
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
		Customizable{id = 'customcontent', children = {}},
	}

	infobox:categories('Manufacturers')
	infobox:categories(unpack(self:getWikiCategories(args)))

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return builtInfobox
end

---@param args table
---@return string[]
function Manufacturer:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Manufacturer:nameDisplay(args)
	return args.name
end

---@param args table
function Manufacturer:setLpdbData(args)
	local name = self.name

	local lpdbData = {
		name = name,
		region = args.region,
		image = args.image,
		extradata = { 
			imagedark = args.imagedark,
			status = args.status,
			locations = Locale.formatLocations(args),
		}
	}
		
	lpdbData = self:addToLpdb(lpdbData, args)
end

function Manufacturer:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
---@return string?
function Manufacturer:subHeaderDisplay(args)
	return args.title
end

return Manufacturer
