---
-- @Liquipedia
-- page=Module:Widget/NavBox/Transfer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Ordinal = Lua.import('Module:Ordinal')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local NavBox = Lua.import('Module:Widget/NavBox')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class TransferNavBox: Widget
local TransferNavBox = Class.new(Widget)

---@return Widget
function TransferNavBox:render()
	local pagesByYear = TransferNavBox._getGroupedData()
	local collapsedChildren = {}
	local childIndex = 0

	local miscPages = Table.extract(pagesByYear, 'misc')
	---@cast pagesByYear table<integer, string[]>

	local remainingPagesByYear = {}

	local firstEntry

	for year, pages in Table.iter.spairs(pagesByYear, TransferNavBox._sortByYear) do
		---@type table
		local childData = Array.map(pages, function(pageName)
			local abbreviation = TransferNavBox._readQuarterOrMonth(pageName)
			if not abbreviation then
				if not remainingPagesByYear[year] then
					remainingPagesByYear[year] = {}
				end
				table.insert(remainingPagesByYear[year], pageName)
				return
			end
			if not firstEntry then
				firstEntry = {pageName = pageName, year = year, abbreviation = abbreviation}
			end

			return Link{
				link = pageName,
				children = {abbreviation}
			}
		end)

		if Logic.isNotEmpty(childData) then
			childData.name = year
			collapsedChildren['child' .. childIndex] = childData
			childIndex = childIndex + 1
		end
	end

	if firstEntry then
		collapsedChildren = TransferNavBox._checkForCurrentQuarterOrMonth(collapsedChildren, firstEntry)
	end

	local unsorted, unsourced, yearly, additionalMisc = TransferNavBox._getUnsortedUnsourcedYearly(remainingPagesByYear)
	if Logic.isNotEmpty(unsorted) then
		collapsedChildren['child' .. childIndex] = Table.merge(unsorted, {name = 'Unsorted'})
		childIndex = childIndex + 1
	end
	if Logic.isNotEmpty(unsourced) then
		collapsedChildren['child' .. childIndex] = Table.merge(unsourced, {name = 'Unsourced'})
		childIndex = childIndex + 1
	end
	if Logic.isNotEmpty(yearly) then
		collapsedChildren['child' .. childIndex] = Table.merge(yearly, {name = 'Year'})
		childIndex = childIndex + 1
	end

	Array.extendWith(miscPages or {}, additionalMisc)
	if Logic.isNotEmpty(miscPages) then
		---@type table
		local childData = Array.map(miscPages, function(pageName)
			local subPageName = pageName:gsub('.*[tT]ransfers/', ''):gsub('_', ' ')
			return Link{
				link = pageName,
				children = {subPageName}
			}
		end)
		childData.name = 'Misc'
		collapsedChildren['child' .. childIndex] = childData
	end

	local firstChild = Table.extract(collapsedChildren, 'child0')

	return NavBox{
		title = 'Transfers',
		titleLink = 'Portal:Transfers',
		child1 = firstChild,
		collapsed = false, -- is used on pages without navbox / HDB, hence would always collapse else
		child2 = Logic.isNotEmpty(collapsedChildren)
			and Table.merge({collapsed = true, title = 'Further Transfers'}, collapsedChildren)
			or nil,
	}
end

---@private
---@param children table<string, table<string|integer, string|Widget|integer>>
---@param firstEntry {pageName: string, year: integer, abbreviation: string}
---@return table<string, table<string|integer, string|Widget|integer>>
function TransferNavBox._checkForCurrentQuarterOrMonth(children, firstEntry)
	local currentYear = DateExt.getYearOf()
	local currentQuarter = DateExt.quarterOf{}
	local currentMonth = DateExt.getMonthOf()
	local quarter = tonumber((firstEntry.abbreviation:match('Q(%d)')))
	local origMonthAbbreviation = firstEntry.abbreviation:gsub('#.*', '')
	local monthTimeStamp = (not quarter) and DateExt.readTimestamp(origMonthAbbreviation .. ' 1970') or nil
	local month = monthTimeStamp and DateExt.formatTimestamp('n', monthTimeStamp) or nil

	local addCurrent = function()
		if not month and not quarter then return children end
		local pageName = firstEntry.pageName
			:gsub(firstEntry.year, currentYear)

		if quarter then
			local ordinal = currentQuarter .. Ordinal.suffix(currentQuarter)
			pageName = pageName:gsub('(%d)%a%a(_[qQ]uarter)', ordinal .. '%1')
			table.insert(children.child0, 1, Link{
				link = pageName,
				children = {'Q' .. currentQuarter},
			})
			return children
		end

		local monthAbbreviation = TransferNavBox._getMonthAbbreviation(month)
		if not monthAbbreviation then return children end

		pageName = pageName:gsub('/[^/]*/?%d?$', '/' .. monthAbbreviation)
		table.insert(children.child0, 1, Link{
			link = pageName,
			children = {monthAbbreviation},
		})
		return children
	end

	if currentYear == firstEntry.year then
		if quarter == currentQuarter or month == currentMonth then
			return children
		end
		return addCurrent()
	elseif currentYear ~= (firstEntry.year + 1) or currentMonth ~= 1 then
		return children
	end
	children = Table.map(children, function(key, child)
		local index = tonumber((key:match('child(%d)')))
		return 'child' .. (index + 1), child
	end)
	children.child0 = {name = currentYear}
	return addCurrent()
end

---@private
---@param tbl table
---@param year1 integer
---@param year2 integer
---@return boolean
function TransferNavBox._sortByYear(tbl, year1, year2)
	return year2 < year1
end

---@private
---@param pagesByYear table<integer, string[]>
---@return Widget[] unsorted
---@return Widget[] unsourced
---@return Widget[] yearly
---@return Widget[] misc
function TransferNavBox._getUnsortedUnsourcedYearly(pagesByYear)
	local toDisplay = function(pageName, year)
		return Link{link = pageName, children = {year}}
	end

	local unsorted, unsourced, yearly, misc = {}, {}, {}, {}
	local latestYear
	for year, pages in Table.iter.spairs(pagesByYear, TransferNavBox._sortByYear) do
		Array.forEach(pages, function(pageName)
			local name = pageName:match('.*/' .. year .. '/(.*)')
			local name2 = pageName:match('.*/(.*)/' .. year)
			name = (name or name2 or ''):lower()
			if name == 'unsorted' then
				table.insert(unsorted, toDisplay(pageName, year))
			elseif name == 'unsourced' or name == 'nosource' then
				table.insert(unsourced, toDisplay(pageName, year))
			elseif pageName:match('[tT]ransfers/' .. year .. '$') then
				table.insert(yearly, toDisplay(pageName, year))
				if not latestYear then
					latestYear = {year = tonumber(year), pageName = pageName}
				end
			else
				table.insert(misc, pageName)
			end
		end)
	end

	local currentYear = DateExt.getYearOf()
	if latestYear and currentYear == (latestYear.year + 1) then
		local pageName = latestYear.pageName:gsub(latestYear.year, currentYear)
		table.insert(yearly, 1, toDisplay(pageName, currentYear))
	end

	return unsorted, unsourced, yearly, misc
end


---@private
---@param pageName string
---@return string?
function TransferNavBox._readQuarterOrMonth(pageName)
	-- try to extract quarter
	local quarter = pageName:match('.*(%d)%a%a_[qQ]uarter.*')
	if Logic.isNotEmpty(quarter) then
		return 'Q' .. quarter
	end
	-- try to extract month
	local month = pageName:match('.*[tT]ransfers/%d%d%d%d/(.*)$')
	if not month then return end
	local appendix = month:match('/(%d)$')
	month = month:gsub('/%d$', '')

	local abbreviation = TransferNavBox._getMonthAbbreviation(month)
	if not abbreviation then return end
	return table.concat({abbreviation, appendix}, '#')
end

---@private
---@param month string?
---@return string?
function TransferNavBox._getMonthAbbreviation(month)
	if Logic.isEmpty(month) then return end

	-- we have to account for transfer pages not fitting the format we will ignore those and throw them away
	-- but since the date functions would error on them rather pcall the date functions
	local formatMonth = function()
		local timestamp = DateExt.readTimestamp(month .. ' 1970')
		assert(timestamp)
		return DateExt.formatTimestamp('M', timestamp)
	end
	local success, monthAbbrviation = pcall(formatMonth)

	return success and monthAbbrviation or nil
end

---@private
---@return table<integer|'misc', string[]>
function TransferNavBox._getGroupedData()
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		query = 'pagename',
		order = 'date desc',
		groupby = 'pagename asc',
		limit = 5000,
	})
	local pages = Array.map(queryData, Operator.property('pagename'))
	local _, pagesByYear = Array.groupBy(pages, function(pageName)
		local year = tonumber((pageName:gsub('.*(%d%d%d%d).*', '%1')))
		return year or 'misc'
	end)
	return pagesByYear
end

return TransferNavBox
