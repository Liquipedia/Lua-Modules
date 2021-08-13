local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Flags = require('Module:Flags')._Flag

local getArgs = require('Module:Arguments').getArgs

local Team = Class.new()
local Language = mw.language.new('en')

function Team.run(frame)
    return Team:createInfobox(frame)
end

function Team:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().text
    self.name = args.name or self.pagename

    if args.game == nil then
        return error('Please provide a game!')
    end

    local infobox = Infobox:create(frame, args.game)

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
            :cell('Sponsor(s)', args.sponsor)
            :cell('Earnings', earnings)
    Team:addCustomCells(infobox, args)

    local links = Links.transform(args)
    local achievements = Team:getAchievements(infobox, args)
	local history = Team:getHistory(infobox, args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links, 'team')
            :header('Achievements', achievements)
            :centeredCell(achievements)
            :header('History', history.created)
            :cell('Created', history.created)
            :cell('Disbanded', history.disbanded)
            :header('Recent Player Trades', args.trades)
            :centeredCell(args.trades)
            :centeredCell(args.footnotes)
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

--- Allows for overriding this functionality
function Team:createBottomContent(infobox)
    return infobox
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

    return Flags(country) ..
                '&nbsp;' ..
                '[[:Category:' .. location .. '|' .. location .. ']]'
end

return Team
