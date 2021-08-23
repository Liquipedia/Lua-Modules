---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Flags = require('Module:Flags')._Flag
local BasicInfobox = require('Module:Infobox/Basic')

local Team = Class.new(BasicInfobox)

local Language = mw.language.new('en')
local _LINK_VARIANT = 'team'

function Team.run(frame)
    local team = Team(frame)
    return team:createInfobox(frame)
end

function Team:createInfobox(frame)
    local infobox = self.infobox
    local args = self.args

    local earnings = self:calculateEarnings(args)
    Variables.varDefine('earnings', earnings)
    if earnings == 0 then
        earnings = nil
    else
        earnings = '$' .. Language:formatNum(earnings)
    end

    infobox :name(args.name)
            :image(args.image, args.default)
            :centeredCell(args.caption)
            :header('Team Information', true)
            :fcell(Cell :new('Location')
                        :options({})
                        :content(
                            self:_createLocation(args.location),
                            self:_createLocation(args.location2)
                        )
                        :make()
            )
            :cell('Region', self:_createRegion(args.region))
            :cell('Coaches', args.coaches)
            :cell('Coach', args.coach)
            :cell('Director', args.director)
            :cell('Manager', args.manager)
            :cell('Team Captain', args.captain)
            :cell('Earnings', earnings)
    self:addCustomCells(infobox, args)

    local links = Links.transform(args)
    local achievements = self:getAchievements(infobox, args)
    local history = self:getHistory(infobox, args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links, _LINK_VARIANT)
            :header('Achievements', achievements)
            :centeredCell(achievements)
            :header('History', history.created)
            :cell('Created', history.created)
            :cell('Disbanded', history.disbanded)
            :header('Recent Player Trades', args.trades)
            :centeredCell(args.trades)
            :centeredCell(args.footnotes)
    self:addCustomContent(infobox, args)
            :bottom(self:createBottomContent(infobox))

    if Namespace.isMain() then
        infobox:categories('Teams')
    end

    return infobox:build()
end

--- Allows for overriding this functionality
function Team:getAchievements(infobox, args)
    return args.achievements
end

--- Allows for overriding this functionality
function Team:getHistory(infobox, args)
    return {created = args.created, disbanded = args.disbanded}
end

--- Allows for overriding this functionality
function Team:calculateEarnings(args)
    return error('You have not implemented a custom earnings function for your wiki')
end

function Team:_createRegion(region)
    if region == nil or region == '' then
        return ''
    end

    return Template.safeExpand(self.infobox.frame, 'Region', {region})
end

function Team:_createLocation(location)
    if location == nil or location == '' then
        return ''
    end

    return Flags(location) ..
                '&nbsp;' ..
                '[[:Category:' .. location .. '|' .. location .. ']]'
end

return Team
