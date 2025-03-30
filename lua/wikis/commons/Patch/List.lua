---
-- @Liquipedia
-- wiki=commons
-- page=Module:Patch/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local PatchFetch = Lua.import('Module:Patch/Fetch')
local TableFormatter = Lua.import('Module:Format/Table')

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
			local name = Logic.nilIfEmpty(patch.name) or patch.pagename:gsub('_', ' '):gsub('^Patch/', '')
			return {
				Link{
					link = patch.pagename,
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
			if Logic.isEmpty(patch.extradata.version) then return {} end
			local rawVersion = patch.extradata.version:gsub('%(', '|'):gsub('%)', '|')
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
				DateExt.formatTimestamp('F j, Y', patch.timestamp)
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
			local highlights = Json.parseIfTable(patch.extradata.highlights) or patch.extradata.highlights
			if Logic.isEmpty(highlights) or type(highlights) ~= 'table' then return end
			return {Ul{children = Array.map(highlights, function(highlight)
				return Li{children = highlight}
			end)}}
		end
	},
}

---@class PatchList
---@operator call(table): PatchList
---@field fetchConfig {game: string?, startDate: integer?, endDate: integer?, year: integer?, limit: integer?}
---@field displayConfig {collapsed: boolean, showMonthHeaders: boolean, showVersion: boolean, yearInAnchorText: boolean}
---@field latestPatchDate integer
---@field latestPatchId integer
---@field patches datapoint[]
---@field currentAnchor string?
local PatchList = Class.new(function(self, args)
	self.fetchConfig = {
		game = args.game,
		startDate = DateExt.readTimestamp(args.sdate),
		endDate = DateExt.readTimestamp(args.edate),
		year = tonumber(args.year),
		limit = tonumber(args.limit),
	}
	self.displayConfig = {
		collapsed = Logic.readBool(args.collapsed),
		showMonthHeaders = not Logic.readBool(args.noheadermonth),
		showVersion = Logic.readBool(args.showVersion),
		yearInAnchorText = Logic.isEmpty(self.fetchConfig.year),
	}
	-- fetch the latest patch
	local latestPatch = (PatchFetch.run{limit = 1, game = args.game} or {})[1]
	self.latestPatchDate = DateExt.readTimestamp(latestPatch.date)
	self.latestPatchId = tonumber(latestPatch.pageid)
end)

---@param frame Frame
---@return Widget
function PatchList.run(frame)
	local args = Arguments.getArgs(frame)
	return PatchList(args):fetch():build()
end

---@return self
function PatchList:fetch()
	local patches = PatchFetch.run(self.fetchConfig)
	assert(type(patches[1]) == 'table',
		'No patches found for the given criteria: ' .. TableFormatter.toLuaCode(self.fetchConfig, {asText = true}))
	-- make sure extradata is not nil
	self.patches = Array.map(patches, function(patch)
		patch.extradata = patch.extradata or {}
		patch.timestamp = DateExt.readTimestamp(patch.date)
		return patch
	end)

	return self
end

---@return Widget
function PatchList:build()
	return DataTable{
		classes = {'collapsible', self.displayConfig.collapsed and 'collapsed' or nil},
		children = WidgetUtil.collect(
			self:_buildHeader(),
			Array.map(self.patches, FnUtil.curry(self._buildRow, self)),
			self:_footer()
		)
	}
end

---@return Widget
function PatchList:_buildHeader()
	return Tr{children = Array.map(COLUMNS, function(column)
		if column.hide and column.hide(self.displayConfig) then return end
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
	local isLatestPatch = patch.timestamp == self.latestPatchDate and patch.pageid == self.latestPatchId
	return Fragment{children = WidgetUtil.collect(
		self:_monthHeaderRow(patch),
		Tr{children = Array.map(COLUMNS, function(column)Td{children = {
			css = {['font-size'] = '0.875rem'},
			children = column.row(patch, isLatestPatch)
		}}end)}
	)}
end

---@return integer
function PatchList:_numberOfColumns()
	return Array.reduce(COLUMNS, function(currentSum, column)
		if column.hide and column.hide(self.displayConfig) then return currentSum end
		return currentSum + 1
	end, 0)
end

---@param patch datapoint
---@return Widget?
function PatchList:_monthHeaderRow(patch)
	local month = DateExt.formatTimestamp('M', patch.timestamp)
	local year = DateExt.formatTimestamp('Y', patch.timestamp)
	local anchor = month .. '_' .. year
	if anchor == self.currentAnchor then return end
	self.currentAnchor = anchor

	if self.displayConfig.showMonthHeaders then
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
					self.displayConfig.yearInAnchorText and (' (' .. year .. ')') or nil,
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
