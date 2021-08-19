local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Links = require('Module:Links')
local Flags = require('Module:Flags')._Flag
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')
local Math = require('Module:Math')
local String = require('Module:String')
local Language = mw.language.new('en')
local BasicInfobox = require('Module:Infobox/Basic')

local Company = Class.new(BasicInfobox)

local _COMPANY_TYPE_ORGANIZER = 'ORGANIZER'

function Company.run(frame)
    local company = Company(frame)
    return company:createInfobox()
end

function Company:createInfobox(frame)
    local infobox = self.infobox
    local args = self.args

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
