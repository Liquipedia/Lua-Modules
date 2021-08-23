---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Scene
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Localisation = require('Module:Localisation')
local Flags = require('Module:Flags')
local Links = require('Module:Links')
local BasicInfobox = require('Module:Infobox/Basic')

local Scene = Class.new(BasicInfobox)

function Scene.run(frame)
    local scene = Scene(frame)
    return scene:createInfobox()
end

function Scene:createInfobox(frame)
    local infobox = self.infobox
    local args = self.args

    local nameDisplay = self:createNameDisplay(args)

    infobox :name(nameDisplay)
            :image(args.image)
            :centeredCell(args.caption)
            :header('Scene Information', true)
            :cell('Region', self:createRegion(args))
            :fcell(Cell:new('National team'):options({makeLink = true}):content(args.nationalteam):make())
            :fcell(Cell :new('Events')
                        :options({makeLink = true})
                        :content(
                            args.event or args.event1,
                            args.event2,
                            args.event3,
                            args.event4,
                            args.event5
                        ):make()
            )
            :cell('Size', args.size)
    self:addCustomCells(infobox, args)

    local links = Links.transform(args)
    local achievements = self:getAchievements(infobox, args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links)
            :header('Achievements', achievements)
            :centeredCell(achievements)
            :centeredCell(args.footnotes)
    self:addCustomContent(infobox, args)
    infobox:bottom(self:createBottomContent(infobox))

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
function Scene:getAchievements(infobox, args)
    return args.achievements
end

--- Allows for overriding this functionality
function Scene:createRegion(args)
    return args.region
end

return Scene
