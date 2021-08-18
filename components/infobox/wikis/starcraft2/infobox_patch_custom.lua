local Patch = require('Module:Infobox/Patch')
local StarCraft2Patch = {}

function StarCraft2Patch.run(frame)
    Patch.addCustomCells = StarCraft2Patch.addCustomCells
    Patch.getChronologyData = StarCraft2Patch.getChronologyData
    return Patch:createInfobox(frame)
end

--- Allows for overriding this functionality
function StarCraft2Patch:addCustomCells(infobox, args)
    infobox :cell('SEA Release Date', args.searelease)
            :cell('NA Release Date', args.narelease)
            :cell('EU Release Date', args.eurelease)
            :cell('KR Release Date', args.korrelease)
    return infobox
end

--- Allows for overriding this functionality
function StarCraft2Patch:getChronologyData(args)
    local data = {}
    if args.previous == nil and args.next == nil then
        if args.previoushbu then
            data.previous = 'Balance Update ' .. args.previoushbu .. '|#' .. args.previoushbu
        end
        if args.nexthbu then
            data.next = 'Balance Update ' .. args.nexthbu .. '|#' .. args.nexthbu
        end
    else
        if args.previous then
            data.previous = 'Patch ' .. args.previous .. '|' .. args.previous
        end
        if args.next then
            data.next = 'Patch ' .. args.previous .. '|' .. args.next
        end
        if args.previoushbu then
            data.previous2 = 'Balance Update ' .. args.previoushbu .. '|#' .. args.previoushbu
        end
        if args.nexthbu then
            data.next2 = 'Balance Update ' .. args.nexthbu .. '|#' .. args.nexthbu
        end
    end

    return data
end

return StarCraft2Patch
