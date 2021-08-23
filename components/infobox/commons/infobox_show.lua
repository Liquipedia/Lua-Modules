---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Show
--

local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Namespace = require('Module:Namespace')
local Cell = require('Module:Infobox/Cell')
local Links = require('Module:Links')
local Table = require('Module:Table')
local Flags = require('Module:Flags')

local Show = Class.new(BasicInfobox)

function Show.run(frame)
	local show = Show(frame)
	return show:createInfobox()
end

function Show:createInfobox()
	local infobox = self.infobox
	local args = self.args

	infobox:name(args.name)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Show Information', true)
	infobox:fcell(Cell:new('Organizer')
				:options({})
				:content(
					unpack(self:_createHosts(args))
				)
				:make()
			)
	infobox:cell('Format', args.format)
	infobox:cell('Airs', args.airs)
	infobox:fcell(Cell:new('Location'):options({}):content(
			self:_createLocation(args.country, args.city),
			self:_createLocation(args.country2, args.city2)
		):make())
	self:addCustomCells(infobox, args)

	local links = Links.transform(args)
	infobox:header('Links', not Table.isEmpty(links))
	infobox:links(links)
	infobox:centeredCell(self:_addSecondaryLinkDisplay(args))
	self:addCustomContent(infobox, args)
	infobox:centeredCell(args.footnotes)
	infobox:bottom(self:createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Shows')
	end

	return infobox:build()
end

function Show:_createHosts(args)
	local hosts = {}
	local host1 = args.host or args.host1
	if host1 then
		host1 = '[[' ..
			(args.hostlink or args.host1link or host1)
			.. '|' .. host1 .. ']]'
		table.insert(hosts, host1)
		for index = 2, 99 do
			if not args['host' .. index] then
				break
			else
				local host = '[[' .. (args['host' .. index .. 'link'] or args['host' .. index])
				host = host .. '|' .. args['host' .. index] .. ']]'
				table.insert(hosts, host)
			end
		end
	end
	return hosts
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
