local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Namespace = require('Module:Namespace')

local Map = Class.new(BasicInfobox)

function Map.run(frame)
	local map = Map(frame)
	return map:createInfobox(frame)
end

function Map:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args
	infobox:name(self:getNameDisplay(args))
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Map Information', true)
	infobox:fcell(Cell:new('Creator'):options({makeLink = true}):content(
		args.creator or args['created-by']):make())
	self:addCustomCells(infobox, args)
	infobox:bottom(self:createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Maps')
		self:_setLpdbData(args)
	end

	return infobox:build()
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
		extradata = { creator = args.creator }
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. lpdbData.name, lpdbData)
end

return Map
