local Map = require('Module:Infobox/Map')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local StarCraft2Map = {}

function StarCraft2Map.run(frame)
    Map.getName = StarCraft2Map.getName
    Map.addCustomCells = StarCraft2Map.addCustomCells
    return Map:createInfobox(frame)
end

function StarCraft2Map:addCustomCells(infobox, args)
	local id = args.id
    infobox :cell('Tileset', args.tileset or StarCraft2Map:tlpdMap(id, 'tileset'))
    infobox :cell('Size', StarCraft2Map:getSize(args, id))
    infobox :cell('Spawn Positions', StarCraft2Map:getSpawn(args, id))
    infobox :cell('Versions', args.versions)
    infobox :cell('Competition Span', args.span)
    infobox :cell('Leagues Featured', args.leagues)
    infobox :cell('[[Rush distance]]', StarCraft2Map:getRushDistance(args))
    infobox :cell('1v1 Ladder', args['1v1history'])
    infobox :cell('2v2 Ladder', args['2v2history'])
    infobox :cell('3v3 Ladder', args['3v3history'])
    infobox :cell('4v4 Ladder', args['4v4history'])
    return infobox
end

function StarCraft2Map:getSize(args, id)
    local width = args.width
        or StarCraft2Map:tlpdMap(id, 'width')
    local height = args.height
        or StarCraft2Map:tlpdMap(id, 'height')
    return width .. 'x' .. height
end

function StarCraft2Map:getSpawn(args, id)
    local players = args.players
        or StarCraft2Map:tlpdMap(id, 'players')
    local positions = args.positions
        or StarCraft2Map:tlpdMap(id, 'positions')
    return players .. ' at ' .. positions
end

function StarCraft2Map:getRushDistance(args)
    local rushDistance = args['rush_distance']
    rushDistance = string.gsub(rushDistance, 's', '')
    rushDistance = string.gsub(rushDistance, 'seconds', '')
    rushDistance = string.gsub(rushDistance, ' ', '')
    Variables.varDefine('rush_distance', rushDistance)
    return rushDistance .. ' seconds'
end

function StarCraft2Map:getName(args)
    if not args.name then
        return StarCraft2Map:tlpdMap(args.id, 'name')
    end

    return args.name
end

function StarCraft2Map:tlpdMap(id, query)
	if not id then return nil end
    return Template.expandTemplate(mw.getCurrentFrame(), 'Tlpd map', { id, query })
end

return StarCraft2Map
