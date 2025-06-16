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

	for year, pages in Table.iter.spairs(pagesByYear, TransferNavBox._sortByYear) do
		---@type table
		local childData = Array.map(pages, TransferNavBox._buildPageDisplay)
		if Logic.isNotEmpty(childData) then
			childData.name = year
			collapsedChildren['child' .. childIndex] = childData
			childIndex = childIndex + 1
		end
	end


	local unsorted, unsourced, yearly = TransferNavBox._getUnsortedUnsourcedYearly(pagesByYear)
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

	if Logic.isNotEmpty(miscPages) then
		---@type table
		local childData = Array.map(miscPages, function(pageName, index) return Link{
			link = pageName,
			children = {'#' .. index}
		} end)
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
---@param tbl table
---@param year1 integer
---@param year2 integer
---@return boolean
function TransferNavBox._sortByYear(tbl, year1, year2)
	return year2 < year1
end

---@private
---@param pagesByYear table<integer, string[]>
---@return Widget[]
---@return Widget[]
---@return Widget[]
function TransferNavBox._getUnsortedUnsourcedYearly(pagesByYear)
	local toDisplay = function(pageName, year)
		return Link{link = pageName, children = {year}}
	end

	local unsorted, unsourced, yearly = {}, {}, {}
	for year, pages in Table.iter.spairs(pagesByYear, TransferNavBox._sortByYear) do
		Array.forEach(pages, function(pageName)
			local name, name2, _
			_, _, name = string.find(pageName, '.*/' .. year .. '/(.*)')
			_, _, name2 = string.find(pageName, '.*/(.*)/' .. year)
			name = (name or name2 or ''):lower()
			if name == 'unsorted' then
				table.insert(unsorted, toDisplay(pageName, year))
			elseif name == 'unsourced' or name == 'nosource' then
				table.insert(unsourced, toDisplay(pageName, year))
			elseif pageName:match('[tT]ransfers/' .. year .. '$') then
				table.insert(yearly, toDisplay(pageName, year))
			end
		end)
	end

	return unsorted, unsourced, yearly
end

---@private
---@param pageName string
---@return Widget?
function TransferNavBox._buildPageDisplay(pageName)
	-- try to extract quarter
	local quarter, _
	_, _, quarter = string.find(pageName, '.*(%d)%a%a_[qQ]uarter.*')
	if Logic.isNotEmpty(quarter) then
		return Link{
			link = pageName,
			children = {'Q' .. quarter}
		}
	end
	-- try to extract month
	local month
	_, _, month = string.find(pageName, '.*[tT]ransfers/%d%d%d%d/(.*)')
	if Logic.isEmpty(month) then return end

	-- we have to account for transfer pages not fitting the format we will ignore those and throw them away
	-- but since the date functions would error on them rather pcall the date functions
	local formatMonth = function()
		local timestamp = DateExt.readTimestamp(month .. ' 1970')
		assert(timestamp)
		return DateExt.formatTimestamp('M', timestamp)
	end
	local success, monthAbbrviation = pcall(formatMonth)
	if not success then return end
	return Link{
		link = pageName,
		children = {monthAbbrviation}
	}
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
