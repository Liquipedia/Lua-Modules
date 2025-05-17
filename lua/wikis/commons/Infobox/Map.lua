---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Map
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

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

---@return string
function Map:createInfobox()
	local args = self.args

	self:_readCreators()

	local widgets = {
		Header{
			name = self:getNameDisplay(args),
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Map') .. ' Information'},
		Cell{name = 'Creator', content = self.creators, options = {makeLink = true}},
		Customizable{id = 'location', children = {
			Cell{name = 'Location', content = {args.location}}
		}},
		Cell{name = 'Release Date', content = {args.releasedate}},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories('Maps', unpack(self:getWikiCategories(args)))
		self:_setLpdbData(args)
	end

	return self:build(widgets)
end

--- Allows for overriding this functionality
---Builds the display Name for the header
---@protected
---@param args table
---@return string
function Map:getNameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
---Add wikispecific categories
---@protected
---@param args table
---@return string[]
function Map:getWikiCategories(args)
	return {}
end

--- Allows for overriding this functionality
---Adjust Lpdb data
---@protected
---@param lpdbData table
---@param args table
---@return table
function Map:addToLpdb(lpdbData, args)
	return lpdbData
end

---@private
function Map:_readCreators()
	self.creators = {}
	for _, creator in Table.iter.pairsByPrefix(self.args, {'creator', 'created-by'}, {requireIndex = false}) do
		table.insert(self.creators, creator)
	end
end

---Stores the lpdb data
---@private
---@param args table
function Map:_setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = 'map',
		image = args.image,
		date = args.releasedate,
		extradata = Table.merge(Table.map(Array.sub(self.creators, 2, #self.creators), function(index, value)
			return 'creator' .. index, value
		end), {
			creator = self.creators[1],
		})
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. lpdbData.name, Json.stringifySubTables(lpdbData))
end

return Map
