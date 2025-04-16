---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Company
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Links = require('Module:Links')
local Locale = require('Module:Locale')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

local Language = mw.getContentLanguage()

---@class CompanyInfobox: BasicInfobox
local Company = Class.new(BasicInfobox)

local COMPANY_TYPE_ORGANIZER = 'ORGANIZER'

---@param frame Frame
---@return Html
function Company.run(frame)
	local company = Company(frame)
	return company:createInfobox()
end

---@return string
function Company:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Company Information'},
		Customizable{id = 'parent', children = {
			Cell{
				name = 'Parent Company',
				content = self:getAllArgsForBase(args, 'parent', {makeLink = true}),
			}
		}},
		Customizable{id = 'dates', children = {
			Cell{name = 'Founded', content = {args.foundeddate or args.founded}},
			Cell{name = 'Defunct', content = {args.defunctdate or args.defunct}},
		}},
		Cell{
			name = 'Location',
			content = {self:_createLocation(args.location)},
		},
		Cell{name = 'Headquarters', content = {args.headquarters}},
		Customizable{id = 'employees', children = {
			Cell{name = 'Employees', content = {args.employees}},
		}},
		Cell{name = 'Trades as', content = {args.tradedas}},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if args.companytype == COMPANY_TYPE_ORGANIZER then
					self:categories('Tournament organizers')
					return {
						Cell{
							name = 'Awarded Prize Pools',
							content = {self:_getOrganizerPrizepools()}
						}
					}
				end
			end
		},
		Center{children = {args.footnotes}},
		Builder{
			builder = function()
				local links = Links.transform(args)
				if not Table.isEmpty(links) then
					return {
						Title{children = 'Links'},
						Widgets.Links{links = links}
					}
				end
			end
		}
	}

	mw.ext.LiquipediaDB.lpdb_company('company_' .. self.name, {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		location = args.location,
		locations = Locale.formatLocations(args),
		headquarterslocation = args.headquarters,
		parentcompany = args.parent,
		foundeddate = ReferenceCleaner.clean{input = args.foundeddate},
		defunctdate = ReferenceCleaner.clean{input = args.defunctdate},
		numberofemployees = ReferenceCleaner.cleanNumber{input = args.employees},
		links = mw.ext.LiquipediaDB.lpdb_create_json({
			discord = Links.makeFullLink{platform = 'discord', id = args.discord},
			facebook = Links.makeFullLink{platform = 'facebook', id = args.facebook},
			instagram = Links.makeFullLink{platform = 'instagram', id = args.instagram},
			twitch = Links.makeFullLink{platform = 'twitch', id = args.twitch},
			twitter = Links.makeFullLink{platform = 'twitter', id = args.twitter},
			website = Links.makeFullLink{platform = 'website', id = args.website},
			weibo = Links.makeFullLink{platform = 'weibo', id = args.weibo},
			vk = Links.makeFullLink{platform = 'vk', id = args.vk},
			youtube = Links.makeFullLink{platform = 'youtube', id = args.youtube},
		})
	})

	self:categories('Companies')

	return self:build(widgets)
end

---@param location string?
---@return string
function Company:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon({flag = location, shouldLink = true}) .. '&nbsp;' ..
				'[[:Category:' .. location .. '|' .. location .. ']]'
end

---@return string?
function Company:_getOrganizerPrizepools()
	local queryName = Logic.readBool(self.args.queryByBasename) and mw.title.getCurrentTitle().baseText or self.pagename
	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions =
			'[[organizers_organizer1::' .. queryName .. ']] OR ' ..
			'[[organizers_organizer2::' .. queryName .. ']] OR ' ..
			'[[organizers_organizer3::' .. queryName .. ']] OR ' ..
			'[[organizers_organizer4::' .. queryName .. ']] OR ' ..
			'[[organizers_organizer5::' .. queryName .. ']]',
		query = 'sum::prizepool'
	})

	local prizemoney = tonumber(queryData[1]['sum_prizepool'])

	if prizemoney == nil or prizemoney == 0 then
		return nil
	end

	return '$' .. Language:formatNum(math.floor(prizemoney + 0.5))
end

return Company
