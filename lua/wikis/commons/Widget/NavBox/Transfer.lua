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

---@class SeriesChildFromLpdb: Widget
local TransferNavBox = Class.new(Widget)
TransferNavBox.defaultProps = {portalLink = Portal:Transfers}

---@return Widget
function TransferNavBox:render()
	local pagesByYear = TransferNavBox._getGroupedData()
	local children = {}
	local childIndex = 1

	local sort = function(tbl, year1, year2)
		return year2 < year1
	end

	for year, pages in Table.iter.spairs(pagesByYear, sort) do
		---@type table
		local childData = Array.map(pages, TransferNavBox._buildPageDisplay)
		if Logic.isNotEmpty(childData) then
			childData.name = year
			children['child' .. childIndex] = childData
			childIndex = childIndex + 1
		end
	end
	return NavBox(Table.merge(children, {title = 'Transfers', titleLink = self.props.portalLink}))
end

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

---@return table<integer, string[]>
function TransferNavBox._getGroupedData()
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		query = 'pagename',
		order = 'date desc',
		groupby = 'pagename asc',
		limit = 5000,
	})
	local pages = Array.map(queryData, Operator.property('pagename'))
	-- throw away all pages that do not contain a year
	pages = Array.filter(pages, function(pageName)
		return pageName:find('%d%d%d%d') ~= nil
	end)
	local _, pagesByYear = Array.groupBy(pages, function(pageName)
		local year = tonumber((pageName:gsub('.*(%d%d%d%d).*', '%1')))
		return year
	end)
	return pagesByYear
end

return TransferNavBox
