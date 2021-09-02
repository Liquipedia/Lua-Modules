---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Company
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local InfoboxBasic = require('Module:Infobox/Basic/dev')
local Links = require('Module:Links')
local Flags = require('Module:Flags')._Flag
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')
local Math = require('Module:Math')
local String = require('Module:String')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Language = mw.language.new('en')

local Company = Class.new(InfoboxBasic)

local _COMPANY_TYPE_ORGANIZER = 'ORGANIZER'

function Company.run(frame)
	local company = Company(frame)
	return company:createInfobox(frame)
end

function Company:createInfobox()
    local infobox = self.infobox
    local args = self.args

	local widgets = ({
		Header{{name = args.name, image = args.image}},
		Center{content = {args.caption}},
		Title{name = 'League Information'},
		Cell{{
			name = 'Parent company',
			content = self:getAllArgsForBase(args, 'parent', {makeLink = true}),
		}},
		Cell{{name = 'Founded', content = {args.foundeddate},}},
		Cell{{name = 'Defunct', content = {args.defunctdate},}},
		Cell{{
			name = 'Location',
			content = {self:_createLocation(args.location)},
		}},
		Cell{{name = 'Headquarters', content = {args.headquarters}}},
		Cell{{name = 'Employees', content = {args.employees}}},
		Cell{{name = 'Traded as', content = {args.tradedas}}},
		Customizable{id = 'custom', children = {}},
	})

    if not String.isEmpty(args.companytype) and args.companytype == _COMPANY_TYPE_ORGANIZER then
		table.insert(widgets, Cell({
			name = 'Total prize money',
			content = {self:_getOrganizerPrizepools()}
		}))

        infobox:categories('Tournament organizers')
    end

    local links = Links.transform(args)
	table.insert(widgets, Center{content = {args.footnotes}})
	if not Table.isEmpty(links) then
		table.insert(widgets, Title{name = 'Links'})
		table.insert(widgets, Widgets.Links{content = links})
	end

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

    return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

function Company:_createLocation(location)
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
