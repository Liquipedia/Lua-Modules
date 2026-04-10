---
-- @Liquipedia
-- page=Module:Infobox/Series
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Class = Lua.import('Module:Class')
local CountryCategory = Lua.import('Module:Infobox/Extension/CountryCategory')
local Currency = Lua.import('Module:Currency')
local Json = Lua.import('Module:Json')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Links = Lua.import('Module:Links')
local Locale = Lua.import('Module:Locale')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia ${tierMode}'

local Widgets = Lua.import('Module:Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Header = Widgets.Header
local Location = Widgets.Location
local Organizers = Widgets.Organizers
local Title = Widgets.Title
local Venue = Widgets.Venue

---@class SeriesInfobox: BasicInfobox
---@operator call(Frame): SeriesInfobox
local Series = Class.new(BasicInfobox)

---@param frame Frame
---@return Widget
function Series.run(frame)
	local series = Series(frame)
	return series:createInfobox()
end

---@return Widget
function Series:createInfobox()
	local args = self.args

	-- define this here so we can use it in lpdb data and the display
	local links = Links.transform(args)

	-- Split venue from legacy format to new format.
	-- Legacy format is a wiki-code string that can include an external link
	-- New format has |venue= and |venuelink= as different parameters.
	-- This should be removed once there's been a bot run to change this.
	if not args.venuelink and args.venue and args.venue:sub(1, 1) == '[' then
		-- Remove [] and split on space
		local splitVenue = mw.text.split(args.venue:gsub('%[', ''):gsub('%]', ''), ' ')
		args.venuelink = splitVenue[1]
		table.remove(splitVenue, 1)
		args.venue = table.concat(splitVenue, ' ')
	end

	self:getSeriesPrizepools()

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Series Information'},
		Organizers{args = args},
		Cell{
			name = 'Sponsor(s)',
			children = self:getAllArgsForBase(args, 'sponsor')
		},
		Customizable{id = 'type', children = {}},
		Customizable{
			id = 'location',
			children = {
				Location{args = args, showTbdOnEmpty = false},
			}
		},
		Venue{args = args},
		Cell{
			name = 'Date',
			children = {
				args.date
			}
		},
		Cell{
			name = 'Start Date',
			children = {
				args.sdate or args.launched or args.inaugurated
			}
		},
		Cell{
			name = 'End Date',
			children = {
				args.edate or args.defunct
			}
		},
		Customizable{
			id = 'custom',
			children = {}
		},
		Customizable{id = 'totalprizepool', children = {Builder{
			builder = function()
				if self.totalSeriesPrizepool then
					return {Cell{
						name = 'Cumulative Prize Pool',
						children = self:_displaySeriesPrizePool()
					}}
				end
			end
		}}},
		Customizable{
			id = 'liquipediatier',
			children = {
				Cell{
					name = 'Liquipedia Tier',
					children = {self:createLiquipediaTierDisplay(args)},
					classes = {self:liquipediaTierHighlighted(args) and 'valvepremier-highlighted' or ''},
				},
			}
		},
		Widgets.Links{links = links},
		Customizable{id = 'customcontent', children = {}},
	}

	if self:shouldStore(args) then
		self:_setLpdbData(args, links)
		self:categories(unpack(self:_getCategories(args)))
	end

	return self:build(widgets, 'Series')
end

---@param args table
---@param links table
function Series:_setLpdbData(args, links)
	local tier, tierType = Tier.toValue(args.liquipediatier, args.liquipediatiertype)

	local lpdbData = {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		abbreviation = args.abbreviation or args.acronym,
		icon = args.icon,
		icondark = args.icondark or args.icondarkmode,
		game = args.game,
		type = args.type,
		location = Locale.formatLocation({city = args.city, country = args.country}),
		location2 = Locale.formatLocation({city = args.city2, country = args.country2}),
		locations = Locale.formatLocations(args),
		previous = args.previous,
		previous2 = args.previous2,
		next = args.next,
		next2 = args.next2,
		prizepool = self.totalSeriesPrizepool or args.prizepool,
		liquipediatier = tier,
		liquipediatiertype = tierType,
		publishertier = args.publishertier,
		launcheddate = ReferenceCleaner.clean{input = args.launcheddate or args.sdate or args.inaugurated},
		defunctdate = ReferenceCleaner.clean{input = args.defunctdate or args.edate},
		defunctfate = ReferenceCleaner.clean{input = args.defunctfate},
		organizers = Json.stringify({
			organizer1 = args.organizer or args.organizer1,
			organizer2 = args.organizer2,
			organizer3 = args.organizer3,
			organizer4 = args.organizer4,
			organizer5 = args.organizer5,
		}),
		sponsors = Json.stringify({
			sponsor1 = args.sponsor1,
			sponsor2 = args.sponsor2,
			sponsor3 = args.sponsor3,
			sponsor4 = args.sponsor4,
			sponsor5 = args.sponsor5,
		}),
		links = Json.stringify(
			Links.makeFullLinksForTableItems(links or {})
		),
	}
	lpdbData = self:_getIconFromLeagueIconSmall(lpdbData)

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_series('series_' .. self.name, lpdbData)
end

--- Allows for overriding this functionality
---@param lpdbData table
---@param args table
---@return table
function Series:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
---@return boolean
function Series:shouldStore(args)
	return Namespace.isMain() and Lpdb.isStorageEnabled()
end

---@param args table
---@return string
function Series:createLiquipediaTierDisplay(args)
	return (Tier.display(args.liquipediatier, args.liquipediatiertype, {link = true}) or '')
		.. self:appendLiquipediatierDisplay(args)
end

--- Allows for overriding this functionality
---@param args table
---@return boolean
function Series:liquipediaTierHighlighted(args)
	return false
end

--- Allows for overriding this functionality
---@param args table
---@return string
function Series:appendLiquipediatierDisplay(args)
	return ''
end

---@param lpdbData table
---@return table
function Series:_getIconFromLeagueIconSmall(lpdbData)
	local icon = lpdbData.icon
	local iconDark = lpdbData.icondark
	local iconSmallTemplate = LeagueIcon.display{
		icon = icon,
		iconDark = iconDark,
		series = lpdbData.name,
		date = lpdbData.defunctfate
	}
	local trackingCategory

	icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate{
		icon = icon,
		iconDark = iconDark,
		stringOfExpandedTemplate = iconSmallTemplate
	}

	if String.isNotEmpty(trackingCategory) then
		table.insert(
			self.warnings,
			'Missing icon while icondark is set.' .. trackingCategory
		)
	end

	lpdbData.icon = icon
	lpdbData.icondark = iconDark

	return lpdbData
end

---@param args table
---@return string[]
function Series:_getCategories(args)
	return Array.extend({'Tournament series'},
		self:addTierCategories(args),
		CountryCategory.run(args, 'Tournaments')
	)
end

---@param args table
---@return string[]
function Series:addTierCategories(args)
	local categories = {}
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype

	local tierCategory, tierTypeCategory = Tier.toCategory(tier, tierType)
	local isValidTierTuple = Tier.isValid(tier, tierType)
	table.insert(categories, tierCategory)
	table.insert(categories, tierTypeCategory)

	if not isValidTierTuple and not tierCategory and String.isNotEmpty(tier) then
		table.insert(self.warnings, String.interpolate(INVALID_TIER_WARNING, {tierString = tier, tierMode = 'Tier'}))
		table.insert(categories, 'Pages with invalid Tier')
	end
	if not isValidTierTuple and not tierTypeCategory and String.isNotEmpty(tierType) then
		table.insert(self.warnings,
			String.interpolate(INVALID_TIER_WARNING, {tierString = tierType, tierMode = 'Tiertype'}))
		table.insert(categories, 'Pages with invalid Tiertype')
	end

	return categories
end

function Series:getSeriesPrizepools()
	local args = Json.parseIfTable(self.args.prizepooltot) or {}

	local series = Array.parseCommaSeparatedString(args.series or mw.title.getCurrentTitle().prefixedText)
	series = Array.map(series, Page.pageifyLink)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.anyOf(ColumnName('seriespage'), series),
		ConditionNode(ColumnName('prizepool'), Comparator.gt, 0),
		ConditionUtil.anyOf(ColumnName('status'), {'finished', ''}),
	}

	local parseToFormattedNumber = function(input)
		local int = MathUtil.toInteger(input)
		if not int then return end
		return string.format("%05d", int)
	end

	local offset = parseToFormattedNumber(args.offset)
	if offset then
		conditions:add(ConditionNode(ColumnName('extradata_seriesnumber'), Comparator.gt, offset))
	end
	local limit = parseToFormattedNumber(args.limit)
	if limit then
		conditions:add(ConditionNode(ColumnName('extradata_seriesnumber'), Comparator.le, limit))
	end

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = tostring(conditions),
		query = 'prizepool, liquipediatier',
		limit = 5000,
	})

	if not data[1] then
		return
	end

	local sums = {total = 0}
	Array.forEach(data, function(item)
		local value = (tonumber(item.prizepool) or 0)
		sums[item.liquipediatier] = (sums[item.liquipediatier] or 0) + value
		sums.total = sums.total + value
	end)

	-- if sum has only 2 elements then we only have 1 tier
	if sums.total == 0 or Table.size(sums) <= 2 then
		return
	end

	self.totalSeriesPrizepool = Table.extract(sums, 'total')
	if not Logic.readBool(args.onlytotal) then
		self.prizePoolByTier = sums
	end
end


---@return Renderable[]|Renderable?
function Series:_displaySeriesPrizePool()
	if not self.totalSeriesPrizepool then
		return
	end

	---@param value number
	---@param tier string|integer?
	---@return string
	local displayRow = function(value, tier)
		local row = '≃ ' .. Currency.display('USD', value, {formatPrecision = 0, formatValue = true})
		if not tier then
			return row
		end
		return Tier.display(tier) .. ': ' .. row
	end

	local rows = {displayRow(self.totalSeriesPrizepool)}

	for tier, value in Table.iter.spairs(self.prizePoolByTier or {}) do
		table.insert(rows, displayRow(value, tier))
	end

	return rows
end

return Series
