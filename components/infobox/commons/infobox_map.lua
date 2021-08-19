local Class = require('Module:Class')
local Infobox = require('Module:Infobox')

local getArgs = require('Module:Arguments').getArgs

local Map = Class.new()

function Map.run(frame)
    return Map:createInfobox(frame)
end

function Map:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().text
	local name = Map:getName(args)
    self.name = name or self.pagename

    if args.game == nil then
        return error('Please provide a game!')
    end

    local infobox = Infobox:create(frame, args.game)

    infobox :name(name)
            :image(args.image, args.defaultImage)
            :centeredCell(args.caption)
            :header('Map Information', true)
            :fcell(Cell:new('Creator'):options({makeLink = true}):content(
                args.creator or args['vreated-by']):make())
    Map:addCustomCells(infobox, args)
    infobox:bottom(Map.createBottomContent(infobox))

    return infobox:build()
end

--- Allows for overriding this functionality
--- for e.g. #external_info:tlpd_map on sc/sc2
function Map:getName(args)
    return args.name
end

--- Allows for overriding this functionality
function Map:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Map:createBottomContent(infobox)
    return infobox
end

return Map
