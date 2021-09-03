---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Show
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Namespace = require('Module:Namespace')
local Links = require('Module:Links')
local Table = require('Module:Table')
local Flags = require('Module:Flags')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

local Show = Class.new(BasicInfobox)

function Show.run(frame)
	local show = Show(frame)
	return show:createInfobox()
end

function Show:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{name = args.name, image = args.image},
		Center{content = {args.caption}},
		Title{name = 'Show Information'},
		Cell{name = 'Host(s)', content = self:getAllArgsForBase(args, 'host', {makeLink = true})},
		Cell{name = 'Format', content = {args.format}},
		Cell{name = 'Airs', content = {args.airs}},
		Cell{name = 'Location', content = {
				self:_createLocation(args.country, args.city),
				self:_createLocation(args.country2, args.city2)
			}},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				local links = Links.transform(args)
				local secondaryLinks = Show:_addSecondaryLinkDisplay(args)
				if (not Table.isEmpty(links)) or (secondaryLinks ~= '') then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links},
						Center{content = {secondaryLinks}},
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Shows')
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
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
			.. args.itunes .. ' iTunes][[Category:Podcasts]]'
	end
	if args.videoarchive then
		secondaryLinks[#secondaryLinks + 1] = '['
			.. args.videoarchive .. ' Video Archive]'
	end

	return table.concat(secondaryLinks, '&nbsp;•&nbsp;')
end

return Show
