---
-- @Liquipedia
-- page=Module:Infobox/Show
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Links = require('Module:Links')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class ShowInfobox: BasicInfobox
local Show = Class.new(BasicInfobox)

---Entry point
---@param frame Frame
---@return Html
function Show.run(frame)
	local show = Show(frame)
	return show:createInfobox()
end

---@return string
function Show:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Show Information'},
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
				local returnWidgets = {}
				if (not Table.isEmpty(links)) or (secondaryLinks ~= '') then
					table.insert(returnWidgets, Title{children = 'Links'})
				end
				if not Table.isEmpty(links) then
					table.insert(returnWidgets, Widgets.Links{links = links})
				end
				if secondaryLinks ~= '' then
					table.insert(returnWidgets, Center{children = {secondaryLinks}})
				end
				return returnWidgets
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories('Shows')
	end

	return self:build(widgets)
end

---@param country string?
---@param city string?
---@return string
function Show:_createLocation(country, city)
	if country == nil or country == '' then
		return ''
	end

	local countryDisplay = Flags.CountryName{flag = country}

	return Flags.Icon{flag = country, shouldLink = true} .. '&nbsp;' ..
		'[[:Category:' .. countryDisplay .. '|' .. (city or countryDisplay) .. ']]'
end

---@param args table
---@return string
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
