local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
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
	return team:createInfobox()
end

function Team:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args

    local earnings = Team:calculateEarnings(args)
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
                            Team:_createLocation(args.location),
                            Team:_createLocation(args.location2)
                        )
                        :make()
            )
            :cell('Region', Team:_createRegion(args.region))
            :cell('Coaches', args.coaches)
            :cell('Coach', args.coach)
            :cell('Director', args.director)
            :cell('Manager', args.manager)
            :cell('Team Captain', args.captain)
            :cell('Earnings', earnings)
    Team:addCustomCells(infobox, args)

    local links = Links.transform(args)
    local achievements = Team:getAchievements(infobox, args)
    local history = Team:getHistory(infobox, args)

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
    Team:addCustomContent(infobox, args)
            :bottom(Team.createBottomContent(infobox))

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
function Team:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Team:calculateEarnings(args)
    return error('You have not implemented a custom earnings function for your wiki')
end

function Team:_createRegion(region)
    if region == nil or region == '' then
        return ''
    end

    return Template.safeExpand(self.frame, 'Region', {region})
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
