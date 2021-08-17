local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Infobox = require('Module:Infobox')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')
local String = require('Module:String')
local Links = require('Module:Links')
local Flags = require('Module:Flags')
local Localisation = require('Module:Localisation')
local Variables = require('Module:Variables')

local getArgs = require('Module:Arguments').getArgs

local League = Class.new()

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
                            unpack(League:_createOrganizers(args))
                        )
                        :make()
            )
            :cell('Sponsor(s)', args.sponsor)
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
                        :make()
            )
            :cell('Location', League:_createLocation({
                region = args.region,
                country = args.country,
                location = args.city or args.location
            }))
            :cell('Venue', args.venue)
            :cell('Format', args.format)
            :fcell(self:createPrizepool(args):make())
            :fcell(Cell :new('Date')
                        :options({})
                        :content(args.date)
						:make()
            )
            :fcell(Cell :new('Start Date')
                        :options({})
                        :content(args.sdate)
						:make()
            )
            :fcell(Cell :new('End Date')
                        :options({})
                        :content(args.edate)
						:make()
            )
            :fcell(self:createTier(args):make())
    League:addCustomCells(infobox, args)

    local links = Links.transform(args)

    infobox :header('Links', not Table.isEmpty(links))
            :links(links)
    League:addCustomContent(infobox, args)
    infobox :centeredCell(args.footnotes)
            :header('Chronology', self:_isChronologySet(args.previous, args.next))
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

    self:_definePageVariables(args)

    return infobox:build()
end

--- Allows for overriding this functionality
function League:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function League:addCustomContent(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function League:createBottomContent(infobox)
    return infobox
end

--- Allows for overriding this functionality
function League:createTier(args)
    error('You need to define a tier function for this wiki!')
end

--- Allows for overriding this functionality
function League:createPrizepool(args)
    error('You need to define a prizepool function for this wiki!')
end

--- Allows for overriding this functionality
function League:_defineCustomPageVariables(args)
end

function League:_definePageVariables(args)
    Variables.varDefine('tournament_name', args.name)
    Variables.varDefine('tournament_short_name', args.shortname)
    Variables.varDefine('tournament_ticker_name', args.tickername)
    Variables.varDefine('tournament_icon', args.icon)
    Variables.varDefine('tournament_series', args.series)

    Variables.varDefine('tournament_liquipedia_tier', args.liquipediatier)
    Variables.varDefine('tournament_liquipedia_tier_type', args.liquipediatiertype)
    Variables.varDefine('tournament_liquipedia_tier_type2', args.liquipediatiertype2)

    Variables.varDefine('tournament_mode', args.mode)
    Variables.varDefine('tournament_type', args.type)

    Variables.varDefine('tournament_region', args.region)
    Variables.varDefine('tournament_country', args.country)
    Variables.varDefine('tournament_location', args.location or args.city)
    Variables.varDefine('tournament_venue', args.venue)

    Variables.varDefine('tournament_game', args.game)

    Variables.varDefine('tournament_parent', args.parent)
    Variables.varDefine('tournament_parent_name', args.parentname)
    Variables.varDefine('tournament_subpage', args.subpage)

    self:_defineCustomPageVariables(args)
end

---
-- Format:
-- {
--     region: Region or continent
--     country: the country
--     location: the city or place
-- }
function League:_createLocation(details)
    if Table.isEmpty(details) then
        return nil
    end

    local nationality = Localisation.getLocalisation(details.country)
    local countryName = Localisation.getCountryName(details.country)
    return Flags._Flag(details.country) .. '&nbsp;' ..
        '[[:Category:' .. nationality .. ' Tournaments|' ..
        (details.location or countryName) .. ']]' ..
        '[[Category:' .. nationality .. ' Tournaments]]'
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

function League:_createOrganizers(args)
    local organizers = {
        League:_createOrganizer(
            args.organizer, args['organizer-name'], args['organizer-link'], args.organizerref),
    }

    local index = 2

    while not String.isEmpty(args['organizer' .. index]) do
        table.insert(
            organizers,
            League:_createOrganizer(
                args['organizer' .. index],
                args['organizer-name' .. index],
                args['organizer-link' .. index],
                args['organizerref' .. index])
        )
        index = index + 1
    end

    return organizers
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

function League:_isChronologySet(previous, next)
    -- We only need to check the first of these params, since it makes no sense
    -- to set next2 and not next, etc.
    return not (String.isEmpty(previous) and String.isEmpty(next))
end

return League
