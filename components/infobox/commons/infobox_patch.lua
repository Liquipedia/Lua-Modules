local Class = require('Module:Class')
local Infobox = require('Module:Infobox')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')

local getArgs = require('Module:Arguments').getArgs

local Patch = Class.new()

function Patch.run(frame)
    return Patch:createInfobox(frame)
end

function Patch:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().text
    self.name = args.name or self.pagename

    if args.game == nil then
        return error('Please provide a game!')
    end

    local infobox = Infobox:create(frame, args.game)

    infobox :name(args.name)
            :image(args.image, args.defaultImage)
            :centeredCell(args.caption)
            :header('Patch Information', true)
            :cell('Version', args.version)
            :cell('Release', args.release)
    Patch:addCustomCells(infobox, args)

    local chronologyData = Patch:getChronologyData(args)

    infobox :header('Highlights', args.highlight1)
            :fcell(Patch:_createHighlightsCell(args))
            :header('Chronology', not Table.isEmpty(chronologyData))
            :chronology(chronologyData)
            :centeredCell(args.footnotes)
    Patch:addCustomContent(infobox, args)
    infobox:bottom(Patch.createBottomContent(infobox))

    if Namespace.isMain() then
        infobox:categories('Patches')
    end

    return infobox:build()
end

--- Allows for overriding this functionality
function Patch:addCustomContent(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Patch:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Patch:createBottomContent(infobox)
    return infobox
end

--- Allows for overriding this functionality
function Patch:getChronologyData(args)
    return { previous = args.previous, next = args.next }
end

function Patch:_createHighlightsCell(args)
    local div = mw.html.create('div')
    local highlights = mw.html.create('ul')
    if not (args.highlight1 or args.highlight) then
        return nil
    else
        highlights:tag('li'):wikitext(args.highlight1 or args.highlight):done()
    end
    for index = 2, 99 do
        if args['highlight' .. index] then
            highlights:tag('li'):wikitext(args['highlight' .. index]):done()
        else
            break
        end
    end
    return div:node(highlights)
end

return Patch
