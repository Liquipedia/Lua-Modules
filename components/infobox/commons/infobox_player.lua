local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Flags = require('Module:Flags')
--local Lua = require('Module:Lua')--needed for the next line only
--local AgeCalculation = (Lua.requireIfExists('Module:Infobox/Player/Age') or require('Module:Infobox player/age')).get

local getArgs = require('Module:Arguments').getArgs

local Player = Class.new()
local Language = mw.language.new('en')
local _LINK_VARIANT = 'player'

function Player.run(frame)
    return Player:createInfobox(frame)
end

function Player:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().text
    self.name = args.id or self.pagename

    if args.game == nil then
        return error('Please provide a game!')
    end

    local infobox = Infobox:create(frame, args.game)

    local earnings = Player:calculateEarnings(args)
    Variables.varDefine('earnings', earnings)
    if earnings == 0 then
        earnings = nil
    else
        earnings = '$' .. Language:formatNum(earnings)
    end
    local birthDisplay, deathDisplay, _BIRTHDAY, _DEATHDAY = Player:birthAndDeath(args)
    local status = Player:getStatus(args)

    infobox :name(Player:name(args))
            :image(args.image, args.default)
            :centeredCell(args.caption)
            :header('Player Information', true)
            :cell('Name', args.name)
            :cell('Romanized Name', args.romanized_name)
            :cell('Birth', birthDisplay)
            :cell('Died', deathDisplay)
            :cell('Status', status)
            :fcell(Cell :new('Location')
                        :options({})
                        :content(
                            Player:_createLocation(args.country or args.nationality, args.location),
                            Player:_createLocation(args.country2 or args.nationality2, args.location2),
                            Player:_createLocation(args.country3 or args.nationality3, args.location3)
                        )
                        :make()
            )
            :cell('Region', Player:_createRegion(args.region))
            :fcell(Cell :new('Team')
                        :options({})
                        :content(
                            Player:_createTeam(args.team, args.teamlink),
                            Player:_createTeam(args.team2, args.teamlink2)
                        )
                        :make()
            )
            :fcell(Cell :new('Clan')
                        :options({})
                        :content(
                            Player:_createTeam(args.clan, args.clanlink),
                            Player:_createTeam(args.clan2, args.clanlink2)
                        )
                        :make()
            )
            :cell('Alternate IDs', args.ids or args.alternateids)
            :cell('Nicknames', args.nicknames)
            :cell('Total Earnings', earnings)
    Player:addCustomCells(infobox, args)

    local links = Links.transform(args)
    local achievements = Player:getAchievements(infobox, args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links, _LINK_VARIANT)
            :header('Achievements', achievements)
            :centeredCell(achievements)
            :header('History', args.history)
            :centeredCell(args.history)
            :centeredCell(args.footnotes)
    Player:addCustomContent(infobox, args)
            :bottom(Player.createBottomContent(infobox))

    if Player:storeInLPDBandVars(args) then
        local playerType = Player:getType(args)
        infobox:categories('Players')

        local extradata = Player:getExtradata(args)
        local links = Player:getLinksLPDB(args)

        mw.ext.LiquipediaDB.lpdb_player('player' .. self.name, {
            id = id,
            alternateid = args.ids,
            name = args.romanized_name or args.name,
            localizedname = name,
            nationality = args.country or args.nationality,
            nationality2 = args.country2 or args.nationality2,
            nationality3 = args.country3 or args.nationality3,
            birthdate = birthday,
            deathdate = deathday,
            image = args.image,
            region = args.region,
            team = args.teamlink or args.team,
            status = status,
            type = playerType,
            earnings = earnings,
            links = mw.ext.LiquipediaDB.lpdb_create_json(links),
            extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
        })
    end

    return infobox:build()
end

--- Allows for overriding this functionality
function Player:getType(args)
    return args.role
end

--- Allows for overriding this functionality
function Player:getStatus(args)
    return args.status
end

--- Allows for overriding this functionality
function Player:getExtradata(args)
    return {}
end

--- Allows for overriding this functionality
function Player:getLinksLPDB(args)
    return {}
end

--- Allows for overriding this functionality
--- Decides if we store in LPDB and Vars or not
function Player:storeInLPDBandVars(args)
    return Namespace.isMain()
end

--- Allows for overriding this functionality
--- e.g. to add faction icons to the display for SC2, SC, WC
function Player:name(args)
    return args.id
end

--- Allows for overriding this functionality
function Player:addCustomContent(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Player:addCustomContent(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Player:getAchievements(infobox, args)
    return args.achievements
end

--- Allows for overriding this functionality
function Player:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function Player:calculateEarnings(args)
    return error('You have not implemented a custom earnings function for your wiki')
end

--- Allows for overriding this functionality
function Player:createBottomContent(infobox)
    return infobox
end

function Player:_createRegion(region)
    if region == nil or region == '' then
        return ''
    end

    return Template.safeExpand(self.frame, 'Region', {region})
end

function Player:_createLocation(country, location)
    if country == nil or country == '' then
        return ''
    end
	local countryDisplay = Flags._CountryName(country)

    return Flags._Flag(country) .. '&nbsp;' ..
                '[[:Category:' .. countryDisplay .. ' Players|' .. countryDisplay .. ']]'
                .. (location ~= nil and (',&nbsp;' .. location) or '')
end

function Player:_createTeam(team, link)
    if team == nil or team == '' then
        return ''
    end
	link = link or team

    return '[[' .. link .. '|' .. team .. ']]'
end

--- here todo
function Player:_birthAndDeath(args)
    return '', nil, nil, nil
end

return Player
