local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')
local String = require('Module:String')
local Links = require('Module:Links')
local Flags = require('Module:Flags')

local getArgs = require('Module:Arguments').getArgs

local League = Class.new()
local Language = mw.language.new('en')

function League.run(frame)
    return League:createInfobox(frame)
end

function League:createInfobox(frame)
    local args = getArgs(frame)
    self.frame = frame
    self.pagename = mw.title.getCurrentTitle().title
    self.name = args.name or self.pagename

    if args.wiki == nil then
        return error('Please provide a wiki!')
    end

    local infobox = Infobox:create(frame, args.wiki)

    infobox :name(args.name)
            :image(args.image, args.default)
            :centeredCell(args.caption)
            :header('League Information', true)
            :fcell(Cell :new('Series')
                        :options({})
                        :content(
                            League:_createSeries(frame, args.series, args.abbrevation),
                            League:_createSeries(frame, args.series2, args.abbrevation2)
                        )
                        :make()
            )
            :fcell(Cell  :new('Organizer')
                        :options({})
                        :content(
                            League:_createOrganizer(
								args.organizer, args['organizer-name'], args['organizer-link'], args.organizerref),
                            League:_createOrganizer(
								args.organizer2, args['organizer-name2'], args['organizer-link2'], args.organizerref2),
                            League:_createOrganizer(
								args.organizer3, args['organizer-name3'], args['organizer-link3'], args.organizerref3),
                            League:_createOrganizer(
								args.organizer4, args['organizer-name4'], args['organizer-link4'], args.organizerref4)
                        )
                        :make()
            )
            :cell('Sponsor(s)', args.sponsor)
            :fcell(Cell  :new('Mode')
                        :options({})
                        :content(args.mode)
                        :variables({key = 'mode', value = args.mode})
                        :make()
            )
            :cell('Server', args.server)
            :fcell(Cell  :new('Type')
                        :options({})
                        :content(args.type)
                        :categories(
                            function(_, ...)
                                local value = select(1, ...)
                                value = tostring(value):lower()
                                if value == 'offline' then
                                    infobox:categories('Offline Tournaments')
                                elseif value == 'online' then
                                    infobox:categories('Online Tournaments')
                                else
                                    infobox:categories('Unknown Type Tournaments')
                                end
                            end
                        )
                        :variables({key = 'tournament_type', value = args.type})
                        :make()
            )
            :cell('Location', League:_createLocation({
                region = args.region,
                country = args.country,
                location = args.city or args.location
            }))
            :cell('Venue', args.venue)
            :fcell(self:createPrizepool(args):make())
            :fcell(Cell :new('Date')
                        :options({})
                        :content(args.date)
                        :variables(
                            {key = 'date', value = self:_cleanDate(args.date)},
                            {key = 'tournament_date',
								value = self:_cleanDate(args.edate) or self:_cleanDate(args.date) or ''}
                        )
						:make()
            )
            :fcell(Cell :new('Start Date')
                        :options({})
                        :content(args.sdate)
                        :variables(
                            {key = 'sdate', value = self:_cleanDate(args.sdate)}
                        )
						:make()
            )
            :fcell(Cell :new('End Date')
                        :options({})
                        :content(args.edate)
                        :variables(
                            {key = 'edate', value = self:_cleanDate(args.edate)}
                        )
						:make()
            )
            :fcell(self:createTier(args):make())
    League:addCustomCells(infobox, args)

    local links = Links.transform(args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links)
            :centeredCell(args.footnotes)
            :chronology({
                previous = args.previous,
                next = args.next,
                previous2 = args.previous2,
                next2 = args.next2,
            })
            :bottom(League.createBottomContent(infobox))

    if Namespace.isMain() then
        infobox:categories('Tournaments')
    end

    return infobox:build()
end

--- Allows for overriding this functionality
function League:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function League:createBottomContent(infobox)
    return infobox
end

function League:createTier(args)
    error('You need to define a tier function for this wiki!')
end

function League:createPrizepool(args)
    error('You need to define a prizepool function for this wiki!')
end

---
-- Format:
-- {
--     region: Region or continent
--     country: the country
--     location: the city or place
-- }
function League:_createLocation(details)
    if String.isEmpty(details) then
        return nil
    end

    local countryName = Flags._CountryName(details.country)
    return Flags._Flag(details.country) .. '&nbsp;' ..
        '[[:Category:' .. countryName .. ' Tournaments|' ..
        (details.city or countryName) .. ']]'
end

function League:_createSeries(frame, series, abbreviation)
	if String.isEmpty(series) then
		return nil
	end

    local output = ''

    if self:_exists('Template:LeagueIconSmall/' .. series:lower()) then
        output = Template.safeExpand(frame, 'LeagueIconSmall/' .. series:lower()) .. ' '
    end

    if not self:_exists(series) then
        if String.isEmpty(abbreviation) then
            output = output .. series
        else
            output = output .. abbreviation
        end
    elseif String.isEmpty(abbreviation) then
        output = output .. '[[' .. series .. '|' .. series .. ']]'
    else
        output = output .. '[[' .. series .. '|' .. abbreviation .. ']]'
    end

    return output
end

function League:_createOrganizer(organizer, name, link, reference)
    if String.isEmpty(organizer) then
        return nil
    end

    local output

    if self:_exists(organizer) then
        output = '[[' .. organizer .. '|'
        if String.isEmpty(name) then
            output = output .. organizer .. ']]'
        else
            output = output .. name .. ']]'
        end

    elseif not String.isEmpty(link) then
        if String.isEmpty(name) then
            output = '[' .. link .. ' ' .. organizer .. ']'
        else
            output = '[' .. link .. ' ' .. name .. ']'

        end
    elseif String.isEmpty(name) then
        output = organizer
    else
        output = name
    end

    if not String.isEmpty(reference) then
        output = output .. reference
    end

    return output
end

function League:_cleanDate(date)
    if self:_isUnknownDate(date) then
        return nil
    end

    date = date:gsub('-??', '-01')
    date = date:gsub('-XX', '-01')
    return date
end

function League:_exists(page)
    return mw.title.new(page).exists

end

function League:_isUnknownDate(date)
    return date == nil or string.lower(date) == 'tba' or string.lower(date) == 'tbd'
end

return League
