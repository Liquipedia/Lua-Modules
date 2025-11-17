---
-- @Liquipedia
-- page=Module:Widget/Patch/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Patch = Lua.import('Module:Patch')
local TableFormatter = Lua.import('Module:Format/Table')

local Widget = Lua.import('Module:Widget')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local IconFontawesome = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local B = HtmlWidgets.B
local Fragment = HtmlWidgets.Fragment
local Li = HtmlWidgets.Li
local Span = HtmlWidgets.Span
local Td = HtmlWidgets.Td
local Th = HtmlWidgets.Th
local Tr = HtmlWidgets.Tr
local Ul = HtmlWidgets.Ul
local WidgetUtil = Lua.import('Module:Widget/Util')

local COLUMNS = {
	{
		header = {
			IconFontawesome{iconName = 'patch'},
			' Patch',
		},
		width = '280px',
		row = function(patch, isLatestPatch)
			local name = Logic.nilIfEmpty(patch.displayName) or patch.pageName:gsub('_', ' '):gsub('^Patch/', '')
			return {
				Link{
					link = patch.pageName,
					children = {name},
				},
				isLatestPatch and ' (latest)' or nil,
			}
		end
	},
	{
		hide = function(config)
			return not config.showVersion
		end,
		header = {'Version'},
		width = '280px',
		row = function(patch, isLatestPatch)
			-- the later and the nilIfEmpty wrapper can be kicked once all wikis switched to standardized infobox patch
			local versionStorage = patch.version
			if Logic.isEmpty(versionStorage) then return {} end
			local rawVersion = versionStorage:gsub('%(', '|'):gsub('%)', '|')
			local versions = Array.parseCommaSeparatedString(rawVersion, '|')
			return {
				B{children = {versions[1] or ''}},
				versions[2] and ' (' or nil,
				versions[2],
				versions[2] and ')' or nil,
			}
		end
	},
	{
		header = {
			IconFontawesome{iconName = 'calendar', colorClass = 'gray-text'},
			' Release Date',
		},
		width = '180px',
		row = function(patch, isLatestPatch)
			return {
				DateExt.formatTimestamp('F j, Y', patch.releaseDate.timestamp)
			}
		end
	},
	{
		header = {
			IconFontawesome{iconName = 'highlights', colorClass = 'gold-text'},
			' Release Highlights',
		},
		width = '490px',
		row = function(patch, isLatestPatch)
			if Logic.isEmpty(patch.highlights) then return end
			return {
				Ul{children = Array.map(patch.highlights, function(highlight)
					return Li{children = highlight}
				end)}
			}
		end
	},
}

---@class PatchList: Widget
---@field config {collapsed: boolean, showMonthHeaders: boolean, showVersion: boolean, yearInAnchorText: boolean}
---@field latestPatchDate integer
---@field latestPatchPage string
---@operator call(table):PatchList
local PatchList = Class.new(Widget, function(self, props)
	self.config = {
		collapsed = Logic.readBool(props.collapsed),
		showMonthHeaders = not Logic.readBool(props.noheadermonth),
		showVersion = Logic.readBool(props.showVersion),
		yearInAnchorText = not tonumber(props.year),
	}
	-- fetch the latest patch
	local latestPatch = Patch.getLatestPatch{game = props.game}
	assert(latestPatch, 'No patch found for |game="' .. (props.game or '') .. '"')
	self.latestPatchDate = latestPatch.releaseDate.timestamp
	self.latestPatchPage = latestPatch.pageName
end)

---@return Widget?
function PatchList:render()
	local patches = self:_fetch()

	return DataTable{
		classes = {'collapsible', self.config.collapsed and 'collapsed' or nil},
		children = WidgetUtil.collect(
			self:_buildHeader(),
			Array.map(patches, FnUtil.curry(self._buildRow, self)),
			self:_footer()
		)
	}
end

---@return StandardPatch[]
function PatchList:_fetch()
	local props = self.props

	local fetchConfig = {
		game = props.game,
		startDate = DateExt.readTimestamp(props.sdate),
		endDate = DateExt.readTimestamp(props.edate),
		year = tonumber(props.year),
		limit = tonumber(props.limit),
	}

	local patches = Patch.getByGameYearStartDateEndDate(fetchConfig)
	assert(type(patches[1]) == 'table',
		'No patches found for the given criteria: ' .. TableFormatter.toLuaCode(fetchConfig, {asText = true}))

	return patches
end

---@return Widget
function PatchList:_buildHeader()
	return Tr{children = Array.map(COLUMNS, function(column)
		if column.hide and column.hide(self.config) then return end
		return Th{
			css = {['font-size'] = '1rem', width = column.width},
			children = column.header,
		}
	end)}
end

---@return Widget
function PatchList:_footer()
	return Tr{children = Td{
		css = {['font-weight'] = 'bold', ['text-align'] = 'center'},
		attributes = {colspan = self:_numberOfColumns()},
		children = {Link{
			link = '#top',
			children = {'Back to the Top'},
		}},
	}}
end

---@param patch datapoint
---@return Widget
function PatchList:_buildRow(patch)
	local isLatestPatch = patch.releaseDate.timestamp == self.latestPatchDate and patch.pageName == self.latestPatchPage
	return Fragment{children = WidgetUtil.collect(
		self:_monthHeaderRow(patch),
		Tr{children = Array.map(COLUMNS, function(column)
			if column.hide and column.hide(self.config) then return end
			return Td{
				css = {['font-size'] = '0.875rem'},
				children = column.row(patch, isLatestPatch)
			}
		end)}
	)}
end

---@return integer
function PatchList:_numberOfColumns()
	return Array.reduce(COLUMNS, function(currentSum, column)
		if column.hide and column.hide(self.config) then return currentSum end
		return currentSum + 1
	end, 0)
end

---@param patch datapoint
---@return Widget?
function PatchList:_monthHeaderRow(patch)
	local month = DateExt.formatTimestamp('M', patch.releaseDate.timestamp)
	local year = patch.releaseDate.year
	local anchor = month .. '_' .. year
	if anchor == self.currentAnchor then return end
	self.currentAnchor = anchor

	if self.config.showMonthHeaders then
		return Tr{children = {Td{
			attributes = {colspan = self:_numberOfColumns()},
			classes = {'gray-bg'},
			css = {['text-align'] = 'center'},
			children = {
				Span{
					attributes = {id = anchor},
					css = {position = 'relative', top = '-250px', visibility = 'hidden'},
				},
				B{children = {
					month,
					self.config.yearInAnchorText and (' ' .. year) or nil,
				}}
			},
		}}}
	end

	return Tr{
		css = {height = 0, padding = 0, margin = 0, border = 'none'},
		children = {Td{
			attributes = {colspan = self:_numberOfColumns()},
			css = {height = 0, padding = 0, margin = 0, border = 'none'},
			children = {Span{
				attributes = {id = anchor},
				css = {position = 'relative', top = '-250px', visibility = 'hidden'}
			}},
		}},
	}
end

return PatchList
