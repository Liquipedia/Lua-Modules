---
-- @Liquipedia
-- page=Module:Infobox/Company
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Json = Lua.import('Module:Json')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local Logic = Lua.import('Module:Logic')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

local Language = mw.getContentLanguage()

---@class CompanyInfobox: BasicInfobox
---@operator call(Frame): CompanyInfobox
local Company = Class.new(BasicInfobox)

local COMPANY_TYPE_ORGANIZER = 'ORGANIZER'
local LINK_VARIANT = 'company'

---@param frame Frame
---@return Widget
function Company.run(frame)
	local company = Company(frame)
	return company:createInfobox()
end

---@return Widget
function Company:createInfobox()
	local args = self.args

	local links = Links.transform(args)

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
				children = self:getAllArgsForBase(args, 'parent', {makeLink = true}),
			}
		}},
		Customizable{id = 'dates', children = {
			Cell{name = 'Founded', children = {args.foundeddate or args.founded}},
			Cell{name = 'Defunct', children = {args.defunctdate or args.defunct}},
		}},
		Cell{
			name = 'Location',
			children = {self:_createLocation(args.location)},
		},
		Cell{name = 'Headquarters', children = {args.headquarters}},
		Customizable{id = 'employees', children = {
			Cell{name = 'Employees', children = {args.employees}},
		}},
		Cell{
			name = 'Focus',
			children = {args.focus},
		},
		Cell{name = 'Trades as', children = {args.tradedas}},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if args.companytype == COMPANY_TYPE_ORGANIZER then
					self:categories('Tournament organizers')
					return {
						Cell{
							name = 'Awarded Prize Pools',
							children = {self:_getOrganizerPrizepools()}
						}
					}
				end
			end
		},
		Center{children = {args.footnotes}},
		Widgets.Links{links = links, variant = LINK_VARIANT},
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
		links = Json.stringify(Links.makeFullLinksForTableItems(links, LINK_VARIANT))
	})

	self:categories('Companies')

	return self:build(widgets, 'Company')
end

---@param location string?
---@return string
function Company:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon{flag = location, shouldLink = true} .. '&nbsp;' ..
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
