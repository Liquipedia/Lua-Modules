local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Links = require('Module:Links')
local Flags = require('Module:Flags')._Flag
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')
local Math = require('Module:Math')
local String = require('Module:String')
local getArgs = require('Module:Arguments').getArgs
local Language = mw.language.new('en')

local Company = Class.new()

local _COMPANY_TYPE_ORGANIZER = 'ORGANIZER'

function Company.run(frame)
    return Company:createInfobox(frame)
end

function Company:createInfobox(frame)
    local args = getArgs(frame)
    self.pagename = args.pagename or mw.title.getCurrentTitle().text
    self.name = args.name or self.pagename

    if args.game == nil then
        return error('Please provide a game!')
    end

    local infobox = Infobox:create(frame, args.game)

    infobox :name(args.name)
            :image(args.image)
            :centeredCell(args.caption)
            :header('Company Information', true)
            :fcell(Cell:new('Parent company'):options({makeLink = true}):content(args.parent, args.parent2):make())
            :cell('Founded', args.foundeddate)
            :cell('Defunct', args.defunctdate)
            :cell('Location', Company:_createLocation(frame, args.location))
            :cell('Headquarters', args.headquarters)
            :cell('Employees', args.employees)
            :cell('Traded as', args.tradedas)
    Company:addCustomCells(infobox, args)

    if not String.isEmpty(args.companytype) and args.companytype == _COMPANY_TYPE_ORGANIZER then
        infobox:cell('Total prize money', self:_getOrganizerPrizepools())
        infobox:categories('Tournament organizers')
    end

    local links = Links.transform(args)

    infobox :centeredCell(args.footnotes)
            :header('Links', not Table.isEmpty(links))
            :links(links)

    mw.ext.LiquipediaDB.lpdb_company('company_' .. self.name, {
        name = self.name,
        image = args.image,
        location = args.location,
        headquarterslocation = args.headquarters,
        parentcompany = args.parent,
        foundeddate = ReferenceCleaner.clean(args.foundeddate),
        defunctdate = ReferenceCleaner.clean(args.defunctdate),
        numberofemployees = ReferenceCleaner.cleanNumber(args.employees),
        links = mw.ext.LiquipediaDB.lpdb_create_json({
            discord = Links.makeFullLink('discord', args.discord),
            facebook = Links.makeFullLink('facebook', args.facebook),
            instagram = Links.makeFullLink('instagram', args.instagram),
            twitch = Links.makeFullLink('twitch', args.twitch),
            twitter = Links.makeFullLink('twitter', args.twitter),
            website = Links.makeFullLink('website', args.website),
            weibo = Links.makeFullLink('weibo', args.weibo),
            vk = Links.makeFullLink('vk', args.vk),
            youtube = Links.makeFullLink('youtube', args.youtube),
        })
    })

    infobox:categories('Companies')

    return infobox:build()
end

--- Allows for overriding this functionality
function Company:addCustomCells(infobox, args)
    return infobox
end

function Company:_createLocation(frame, location)
    if location == nil then
        return ''
    end

    return Flags(location) .. '&nbsp;' ..
                '[[:Category:' .. location .. '|' .. location .. ']]'
end

function Company:_getOrganizerPrizepools()
    local prizemoney = mw.ext.LiquipediaDB.lpdb('tournament', {
        conditions =
            '[[organizers_organizer1::' .. self.pagename .. ']] OR ' ..
            '[[organizers_organizer2::' .. self.pagename .. ']] OR ' ..
            '[[organizers_organizer3::' .. self.pagename .. ']] OR ' ..
            '[[organizers_organizer4::' .. self.pagename .. ']] OR ' ..
            '[[organizers_organizer5::' .. self.pagename .. ']]',
        query = 'sum::prizepool'
    })

    prizemoney = tonumber(prizemoney[1]['sum_prizepool'])

    if prizemoney == nil or prizemoney == 0 then
        return nil
    end

    return '$' .. Language:formatNum(Math._round(prizemoney))
end

return Company
