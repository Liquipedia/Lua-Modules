---
-- @Liquipedia
-- page=Module:Infobox/Manufacturer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Locale = Lua.import('Module:Locale')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class ManufacturerInfobox: BasicInfobox
local Manufacturer = Class.new(BasicInfobox)

---@return string
function Manufacturer:createInfobox()
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
				Center{children = {args.caption}},
			}
		},
		Title{children = (args.informationType or 'Manufacturer') .. ' Information'},
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
								Title{children = 'History'},
								Cell{name = 'Founded', content = {args.founded}},
								Cell{name = 'Dissolved', content = {args.dissolved}}
							}
						end
					end
				}
			}
		}
	}

	if Namespace.isMain() then
		self:setLpdbData(args)
		self:categories('Manufacturers')
		self:categories(unpack(self:getWikiCategories(args)))
	end

	return self:build(widgets)
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

	mw.ext.LiquipediaDB.lpdb_datapoint('manufacturer_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function Manufacturer:addToLpdb(lpdbData, args)
	return lpdbData
end

return Manufacturer
