---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Map
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

local Map = Class.new(BasicInfobox)

function Map.run(frame)
	local map = Map(frame)
	return map:createInfobox(frame)
end

function Map:createInfobox(frame)
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
		Title{name = 'Map Information'},
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
		infobox:categories('Maps')
		self:_setLpdbData(args)
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

--- Allows for overriding this functionality
function Map:getNameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
function Map:addToLpdb(lpdbData, args)
	return lpdbData
end

function Map:_setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = 'map',
		image = args.image,
		date = args.releasedate,
		extradata = { creator = args.creator }
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. lpdbData.name, lpdbData)
end

return Map
