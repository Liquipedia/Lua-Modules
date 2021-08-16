local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Localisation = require('Module:Localisation').getLocalisation
local Flags = require('Module:Flags')
--local GetBirthAndDeath = require('Module:???')._get

--the following 3 lines as a temp workaround until the Birth&Death stuff is implemented:
local function GetBirthAndDeath()
    return '', nil, nil, nil
end

local getArgs = require('Module:Arguments').getArgs

local Player = Class.new()
local Language = mw.language.new('en')
local _LINK_VARIANT = 'player'
local shouldStoreData

function Player.run(frame)
    return Player:createInfobox(frame)
end

function Player:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().text
    self.name = args.id or self.pagename

    shouldStoreData = Player:shouldStoreData(args)

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
    local nameDisplay = Player:nameDisplay(args)
    local role = Player:getRole(args)
    local birthDisplay, deathDisplay, birthday, deathday
        = GetBirthAndDeath(
            args.birth_date,
            args.birth_location,
            args.death_date,
            role.category,
            shouldStoreData
        )
    local status = Player:getStatus(args)

    infobox :name(nameDisplay)
            :image(args.image, args.defaultImage)
            :centeredCell(args.caption)
            :header('Player Information', true)
            :cell('Name', args.name)
            :cell('Romanized Name', args.romanized_name)
            :cell('Birth', birthDisplay)
            :cell('Died', deathDisplay)
            :cell('Status', status.display)
            :cell(role.title or 'Role', role.display)
            :fcell(Cell :new('Country')
                        :options({})
                        :content(
                            Player:_createLocation(args.country or args.nationality, args.location, role.category),
                            Player:_createLocation(args.country2 or args.nationality2, args.location2, role.category),
                            Player:_createLocation(args.country3 or args.nationality3, args.location3, role.category)
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
    local history = Player:getHistory(infobox, args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links, _LINK_VARIANT)
            :header('Achievements', achievements)
            :centeredCell(achievements)
            :header('History', history)
            :centeredCell(history)
            :centeredCell(args.footnotes)
    Player:addCustomContent(infobox, args)
    infobox:bottom(Player.createBottomContent(infobox))

    if shouldStoreData then
        infobox:categories(role.category)
        if not args.teamlink and not args.team then
            infobox:categories('Teamless ' .. role.category .. 's')
        end
        if args.death_date then
            infobox:categories('Deceased ' .. role.category .. 's')
        end
        if
            args.retired == 'yes' or args.retired == 'true'
            or string.lower(status.store or '') == 'retired'
            or string.match(args.retired or '', '%d%d%d%d%')--if retired has year set apply the retired category
        then
            infobox:categories('Retired ' .. role.category .. 's')
        else
            infobox:categories('Active ' .. role.category .. 's')
        end
        if not args.id then
            infobox:categories('InfoboxIncomplete.')
        end
        if not args.image then
            infobox:categories(role.category .. 's with no profile picture')
        end
        if not birthDisplay then
            infobox:categories(role.category .. 's with unknown birth date')
        end

        local extradata = Player:getExtradata(args, role, status)
        links = Player:_getLinksLPDB(links)

        mw.ext.LiquipediaDB.lpdb_player('player' .. self.name, {
            id = args.id or mw.title.getCurrentTitle().prefixedText,
            alternateid = args.ids,
            name = args.romanized_name or args.name,
            localizedname = args.name,
            nationality = args.country or args.nationality,
            nationality2 = args.country2 or args.nationality2,
            nationality3 = args.country3 or args.nationality3,
            birthdate = birthday,
            deathdate = deathday,
            image = args.image,
            region = args.region,
            team = args.teamlink or args.team,
            status = status.store,
            type = role.store,
            earnings = earnings,
            links = mw.ext.LiquipediaDB.lpdb_create_json(links),
            extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
        })
    end

    return infobox:build()
end

--- Allows for overriding this functionality
function Player:getRole(args)
    return { display = args.role, store = args.role, category = args.role or 'Player'}
end

--- Allows for overriding this functionality
function Player:getStatus(args)
    return { display = args.status, store = args.status }
end

--- Allows for overriding this functionality
function Player:getHistory(infobox, args)
    return args.history
end

--- Allows for overriding this functionality
function Player:getExtradata(args, role, status)
    return {}
end

--- Allows for overriding this functionality
--- Decides if we store in LPDB and Vars or not
function Player:shouldStoreData(args)
    return Namespace.isMain()
end

--- Allows for overriding this functionality
--- e.g. to add faction icons to the display for SC2, SC, WC
function Player:nameDisplay(args)
    local team = args.teamlink or args.team
    local icon = mw.ext.TeamTemplate.teamexists(team)
        and mw.ext.TeamTemplate.teamicon(team) or ''
    local name = args.id or mw.title.getCurrentTitle().text

    return icon .. '&nbsp;' .. name
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

function Player:_createLocation(country, location, role)
    if country == nil or country == '' then
        return nil
    end
    local countryDisplay = Flags._CountryName(country)
    local demonym = Localisation(countryDisplay)

    return Flags._Flag(country) .. '&nbsp;' ..
                '[[:Category:' .. demonym .. ' ' .. role .. '|' .. countryDisplay .. ']]'
                .. '[[Category:' .. demonym .. ' ' .. role .. ']]'
                .. (location ~= nil and (',&nbsp;' .. location) or '')
end

function Player:_createTeam(team, link)
    if team == nil or team == '' then
        return ''
    end
    link = link or team

    return '[[' .. link .. '|' .. team .. ']]'
end

function Player:_getLinksLPDB(links)
    for key, item in pairs(links) do
        links[key] = Links.makeFullLink(key, item, _LINK_VARIANT)
    end
    return links
end

return Player
