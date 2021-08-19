local Map = require('Module:Infobox/Map')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')

local StarCraft2Map = {}

function StarCraft2Map.run(frame)
	local map = Map(frame)
	Map.getNameDisplay = StarCraft2Map.getNameDisplay
	Map.addCustomCells = StarCraft2Map.addCustomCells
	Map.addToLpdb = StarCraft2Map.addToLpdb
	return map:createInfobox(frame)
end

function StarCraft2Map:addCustomCells(infobox, args)
	local id = args.id
	infobox:cell('Tileset', args.tileset or StarCraft2Map:_tlpdMap(id, 'tileset'))
	infobox:cell('Size', StarCraft2Map:_getSize(args, id))
	infobox:cell('Spawn Positions', StarCraft2Map:_getSpawn(args, id))
	infobox:cell('Versions', args.versions)
	infobox:cell('Competition Span', args.span)
	infobox:cell('Leagues Featured', args.leagues)
	infobox:cell('[[Rush distance]]', StarCraft2Map:_getRushDistance(args))
	infobox:cell('1v1 Ladder', args['1v1history'])
	infobox:cell('2v2 Ladder', args['2v2history'])
	infobox:cell('3v3 Ladder', args['3v3history'])
	infobox:cell('4v4 Ladder', args['4v4history'])
	return infobox
end

function StarCraft2Map:getNameDisplay(args)
	if String.isEmpty(args.name) then
		return StarCraft2Map:_tlpdMap(args.id, 'name')
	end

	return args.name
end

function StarCraft2Map:addToLpdb(lpdbData, args)
	lpdbData.name = StarCraft2Map:getNameDisplay(args)
	lpdbData.extradata = {
		creator = args.creator,
		spawns = args.players,
		height = args.height,
		width = args.width,
		rush = Variables.varDefault('rush_distance'),
	}
	return lpdbData
end

function StarCraft2Map:_getSize(args, id)
	local width = args.width
		or StarCraft2Map:_tlpdMap(id, 'width')
	local height = args.height
		or StarCraft2Map:_tlpdMap(id, 'height')
	return width .. 'x' .. height
end

function StarCraft2Map:_getSpawn(args, id)
	local players = args.players
		or StarCraft2Map:_tlpdMap(id, 'players')
	local positions = args.positions
		or StarCraft2Map:_tlpdMap(id, 'positions')
	return players .. ' at ' .. positions
end

function StarCraft2Map:_getRushDistance(args)
	local rushDistance = args['rush_distance']
	rushDistance = string.gsub(rushDistance, 's', '')
	rushDistance = string.gsub(rushDistance, 'seconds', '')
	rushDistance = string.gsub(rushDistance, ' ', '')
	Variables.varDefine('rush_distance', rushDistance)
	return rushDistance .. ' seconds'
end

function StarCraft2Map:_tlpdMap(id, query)
	if not id then return nil end
	return Template.safeExpand(mw.getCurrentFrame(), 'Tlpd map', { id, query })
end

return StarCraft2Map
