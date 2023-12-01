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
local Locale = Lua.import('Module:Locale', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class ManufacturerInfobox: BasicInfobox
local Manufacturer = Class.new(BasicInfobox)

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
					imageDark = args.imagedark or args.imagedarkmode,
					subHeader = args.title,
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
		}
	}

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		self:setLpdbData(args)
		infobox:categories('Manufacturers')
		infobox:categories(unpack(self:getWikiCategories(args)))
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
		type = 'manufacturer',
		image = args.image,
		imagedark = args.imagedark,
		extradata = {
			status = args.status,
			locations = Locale.formatLocations(args),
		}
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_datapoint('manufacturer_' .. self.name, lpdbData.extradata)
end

---@param lpdbData table
---@param args table
---@return table
function Manufacturer:addToLpdb(lpdbData, args)
	return lpdbData
end

return Manufacturer
