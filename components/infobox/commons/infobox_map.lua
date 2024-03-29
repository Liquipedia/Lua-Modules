---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Map
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class MapInfobox:BasicInfobox
local Map = Class.new(BasicInfobox)

---Entry point of map infobox
---@param frame Frame
---@return Html
function Map.run(frame)
	local map = Map(frame)
	return map:createInfobox()
end

---@return Html
function Map:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = self:getNameDisplay(args),
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = (args.informationType or 'Map') .. ' Information'},
		Cell{name = 'Creator', content = {
				args.creator or args['created-by'], args.creator2 or args['created-by2']}, options = { makeLink = true }
		},
		Customizable{id = 'location', children = {
			Cell{name = 'Location', content = {args.location}}
		}},
		Cell{name = 'Release Date', content = {args.releasedate}},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Maps', unpack(self:getWikiCategories(args)))
		self:_setLpdbData(args)
	end

	return infobox:build(widgets)
end

--- Allows for overriding this functionality
---Builds the display Name for the header
---@param args table
---@return string
function Map:getNameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
---Add wikispecific categories
---@param args table
---@return table
function Map:getWikiCategories(args)
	return {}
end

--- Allows for overriding this functionality
---Adjust Lpdb data
---@param lpdbData table
---@param args table
---@return table
function Map:addToLpdb(lpdbData, args)
	return lpdbData
end

---Stores the lpdb data
---@param args table
function Map:_setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = 'map',
		image = args.image,
		date = args.releasedate,
		extradata = {creator = args.creator}
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. lpdbData.name, Json.stringifySubTables(lpdbData))
end

return Map
