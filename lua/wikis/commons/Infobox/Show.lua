---
-- @Liquipedia
-- page=Module:Infobox/Show
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Links = Lua.import('Module:Links')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Flags = Lua.import('Module:Flags')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

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
		Cell{name = 'Host(s)', children = self:getAllArgsForBase(args, 'host', {makeLink = true})},
		Cell{name = 'Format', children = {args.format}},
		Cell{name = 'Airs', children = {args.airs}},
		Cell{name = 'Location', children = {
			self:_createLocation(args.country, args.city),
			self:_createLocation(args.country2, args.city2)
		}},
		Cell{name = 'Status', children = {args.status}},
		Cell{name = 'Start', children = {args.sdate}},
		Cell{name = 'End', children = {args.edate}},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				local links = Links.transform(args)
				return WidgetUtil.collect(
					Widgets.Links{links = links},
					self:_addSecondaryLinkDisplay(links)
				)
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories('Shows')
		if args.itunes then
			self:categories('Podcasts')
		end
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

---@param links table
---@return (string|Widget)[]?
function Show:_addSecondaryLinkDisplay(links)
	local args = self.args
	local secondaryLinks = WidgetUtil.collect(
		args.topicid and Link{
			linktype = 'external',
			link = 'https://tl.net/forum/viewmessage.php?topic_id=' .. args.topicid,
			children = 'TL Thread',
		} or nil,
		args.itunes and Link{
			linktype = 'external',
			link = args.itunes,
			children = 'iTunes',
		} or nil,
		args.videoarchive and Link{
			linktype = 'external',
			link = args.videoarchive,
			children = 'Video Archive',
		} or nil
	)

	if Logic.isEmpty(secondaryLinks) then return end

	return WidgetUtil.collect(
		Logic.isEmpty(links) and Title{children = 'Links'} or nil,
		Array.interleave(secondaryLinks, '&nbsp;•&nbsp;')
	)
end

return Show
