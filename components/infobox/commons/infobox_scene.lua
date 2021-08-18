local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Localisation = require('Module:Localisation')
local Flags = require('Module:Flags')
local Links = require('Module:Links')

local getArgs = require('Module:Arguments').getArgs

local Scene = Class.new()

function Scene.run(frame)
    return Scene:createInfobox(frame)
end

function Scene:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().text
    self.name = args.country or args.scene or self.pagename

    if args.game == nil then
        return error('Please provide a game!')
    end

    local infobox = Infobox:create(frame, args.game)
    local nameDisplay = Scene:createNameDisplay(args)

    infobox :name(nameDisplay)
            :image(args.image)
            :centeredCell(args.caption)
            :header('Scene Information', true)
            :cell('Region', Scene:createRegion(args))
            :fcell(Cell:new('National team'):options({makeLink = true}):content(args.nationalteam):make())
            :fcell(Cell:new('Events'):options({makeLink = true}):content(
                                                                                    args.event or args.event1,
                                                                                    args.event2,
                                                                                    args.event3,
                                                                                    args.event4,
                                                                                    args.event5
                                                                                ):make())
            :cell('Size', args.size)
    Scene:addCustomCells(infobox, args)

    local links = Links.transform(args)
    local achievements = Scene:getAchievements(infobox, args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links)
            :header('Achievements', achievements)
            :centeredCell(achievements)
            :centeredCell(args.footnotes)
    Scene:addCustomContent(infobox, args)
    infobox:bottom(Scene.createBottomContent(infobox))

    infobox:categories('Scene')

    return infobox:build()
end

--- Allows for overriding this functionality
function Scene:createNameDisplay(args)
    local name = args.name
    local country = Flags._CountryName(args.country or args.scene)
    if not name then
        local localised = Localisation.getLocalisation(country)
        local flag = Flags._Flag(country)
        name = flag .. '&nbsp;' .. localised .. ((' ' .. args.gamenamedisplay) or '') .. ' scene'
    end

    Variables.varDefine('country', country)

    return name
end

--- Allows for overriding this functionality
function Scene:addCustomContent(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Scene:getAchievements(infobox, args)
    return args.achievements
end

--- Allows for overriding this functionality
function Scene:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Scene:createBottomContent(infobox)
    return infobox
end

--- Allows for overriding this functionality
function Scene:createRegion(args)
    return args.region
end

return Scene
