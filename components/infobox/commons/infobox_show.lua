local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Namespace = require('Module:Namespace')
local Cell = require('Module:Infobox/Cell')
local Links = require('Module:Links')
local Table = require('Module:Table')
local Flags = require('Module:Flags')

local getArgs = require('Module:Arguments').getArgs

local Show = Class.new(BasicInfobox)

function Show.run(frame)
	local show = Show(frame)
	local args = show.args
	local infobox = show.infobox

	infobox:name(args.name)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Show Information', true)
	infobox:fcell(Cell:new('Host'):options({makeLink = true}):content(args.host):make())
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
