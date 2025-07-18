---
-- @Liquipedia
-- page=Module:Widget/ProjectOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Grid = Lua.import('Module:Widget/Grid')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local Panel = Lua.import('Module:Widget/Panel')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LabProjectOverviewParameters
---@field projectName string
---@field projectUrl string
---@field projectImage string?
---@field projectImageDark string?

---@class LabProjectOverview: Widget
---@field props LabProjectOverviewParameters
local ProjectOverview = Class.new(Widget)

---@return Widget
function ProjectOverview:render()
	assert(Logic.isNotEmpty(self.props.projectUrl), '|projectUrl= not specified')
	return Grid.Cell{
		xs = 12,
		md = 6,
		cellContent = Panel{
			heading = self.props.projectName,
			padding = true,
			children = Grid.Container{
				gridCells = {
					self:_generateImage(),
					self:_generateOverview()
				}
			}
		}
	}
end

---@private
---@return Widget
function ProjectOverview:_generateImage()
	local hasImage = Logic.isNotEmpty(self.props.projectImage)

	return Grid.Cell{
		xs = 12,
		sm = 12,
		md = 6,
		cellContent = HtmlWidgets.Div{
			classes = not hasImage and {'mobile-hide'} or nil,
			attributes = {
				style = 'height: 160px; display: flex; align-items: center; justify-content: center;'
			},
			children = {
				IconImage{
					imageLight = hasImage and self.props.projectImage or 'Filler 600px.png',
					imageDark = hasImage and Logic.emptyOr(self.props.projectImageDark, self.props.projectImage) or 'Filler 600px.png',
					size = '260x160px',
					link = self.props.projectUrl
				}
			}
		}
	}
end

---@private
---@return Widget
function ProjectOverview:_generateOverview()

	local timestamp = DateExt.readTimestamp(
		mw.getCurrentFrame():callParserFunction(
			'#lastupdated_by_prefix',
			self.props.projectUrl .. '/'
		)
	)

	return Grid.Cell{
		xs = 12,
		sm = 12,
		md = 6,
		cellContent = WidgetUtil.collect(
			HtmlWidgets.H5{
				children = {
					IconFa{iconName = 'projecthome', screenReaderHidden = true},
					Link{link = self.props.projectUrl}
				}
			},
			{
				IconFa{iconName = 'contributors', screenReaderHidden = true},
				' Current Contributors: ',
				mw.ext.LiquipediaDB.lpdb('datapoint', {
					conditions = tostring(
						ConditionTree(BooleanOperator.all)
							:add(ConditionNode(ColumnName('type'), Comparator.eq, 'project contributor'))
							:add(ConditionNode(ColumnName('name'), Comparator.eq, self.props.projectUrl))
					),
					query = 'count::pageid'
				})[1].count_pageid,
			},
			HtmlWidgets.Br{},
			{
				IconFa{iconName = 'articles', screenReaderHidden = true},
				' Articles Created: ',
				mw.getCurrentFrame():callParserFunction('#count_pages_by_prefix', self.props.projectUrl),
			},
			HtmlWidgets.Br{},
			{
				IconFa{iconName = 'lastupdated', screenReaderHidden = true},
				' Last Update: ',
				timestamp and Countdown._create{
					timestamp = timestamp,
					date = DateExt.toCountdownArg(timestamp),
					rawdatetime = true
				} or nil,
			}
		)
	}
end

return ProjectOverview
