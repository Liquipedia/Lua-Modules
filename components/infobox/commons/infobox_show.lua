local Class = require('Module:Class')
local Infobox = require('Module:Infobox')
local Namespace = require('Module:Namespace')
local Cell = require('Module:Infobox/Cell')
local Links = require('Module:Links')
local Table = require('Module:Table')
local Flags = require('Module:Flags')

local getArgs = require('Module:Arguments').getArgs

local Show = Class.new()

function Show.run(frame)
	return Show:createInfobox(frame)
end

function Show:createInfobox(frame)
	local args = getArgs(frame)
	self.frame = frame
	self.pagename = mw.title.getCurrentTitle().text
	self.name = args.name or self.pagename

	if args.game == nil then
		return error('Please provide a game!')
	end

	local infobox = Infobox:create(frame, args.game)

	infobox:name(args.name)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Show Information', true)
	infobox:cell('Host', args.host)
	infobox:cell('Format', args.format)
	infobox:cell('Airs', args.airs)
	infobox:fcell(Cell:new('Location'):options({}):content(
			Show:_createLocation(args.country, args.city),
			Show:_createLocation(args.country2, args.city2)
		):make())
	Show:addCustomCells(infobox, args)

	local links = Links.transform(args)
	infobox:header('Links', not Table.isEmpty(links))
	infobox:links(links)
	infobox:centeredCell(Show:_addSecondaryLinkDisplay(args))
	Show:addCustomContent(infobox, args)
	infobox:centeredCell(args.footnotes)
	infobox:bottom(Show.createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Shows')
	end

	return infobox:build()
end

--- Allows for overriding this functionality
function Show:addCustomCells(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function Show:addCustomContent(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function Show:createBottomContent(infobox)
	return infobox
end

function Show:_createLocation(country, city)
	if country == nil or country == '' then
		return ''
	end

	local countryDisplay = Flags._CountryName(country)

	return Flags._Flag(country) .. '&nbsp;' ..
		'[[:Category:' .. countryDisplay .. '|' .. (city or countryDisplay) .. ']]'
end

function Show:_addSecondaryLinkDisplay(args)
	local secondaryLinks = {}
	if args.topicid then
		secondaryLinks[#secondaryLinks + 1] = '[https://tl.net/forum/viewmessage.php?topic_id='
			.. args.topicid .. ' TL Thread]'
	end
	if args.itunes then
		secondaryLinks[#secondaryLinks + 1] = '['
			.. args.itunes .. ' iTunes] [[Category:Podcasts]]'
	end
	if args.videoarchive then
		secondaryLinks[#secondaryLinks + 1] = '['
			.. args.videoarchive .. ' Video Archive]'
	end

	return table.concat(secondaryLinks, '&nbsp;•&nbsp;')
end

return Show
