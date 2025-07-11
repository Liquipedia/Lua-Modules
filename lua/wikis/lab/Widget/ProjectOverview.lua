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
---@field ProjectName string
---@field ProjectUrl string
---@field ProjectImage string?
---@field ProjectImageDark string?

---@class LabProjectOverview: Widget
---@field props LabProjectOverviewParameters
local ProjectOverview = Class.new(Widget)

---@return Widget
function ProjectOverview:render()
	assert(Logic.isNotEmpty(self.props.ProjectUrl), '|ProjectUrl= not specified')
	return Grid.Cell{
		xs = 12,
		md = 6,
		cellContent = Panel{
			heading = self.props.ProjectName,
			padding = true,
			children = Grid.Container{
				gridCells = WidgetUtil.collect(
					self:_generateImage(),
					self:_generateOverview()
				)
			}
		}
	}
end

---@private
---@return Widget?
function ProjectOverview:_generateImage()
	if Logic.isEmpty(self.props.ProjectImage) then return end
	return Grid.Cell{
		xs = 12,
		xm = 12,
		md = 6,
		cellContent = IconImage{
			imageLight = self.props.ProjectImage,
			imageDark = Logic.nilIfEmpty(self.props.ProjectImageDark),
			size = '280x180px',
			link = self.props.ProjectUrl,
			alignment = 'center'
		}
	}
end

---@private
---@return Widget
function ProjectOverview:_generateOverview()
	return Grid.Cell{
		xs = 12,
		sm = 12,
		md = 6,
		cellContent = WidgetUtil.collect(
			HtmlWidgets.H5{
				children = {
					IconFa{iconName = 'projecthome', screenReaderHidden = true},
					Link{link = self.props.ProjectUrl}
				}
			},
			{
				IconFa{iconName = 'contributors', screenReaderHidden = true},
				' Current Contributors: ',
				mw.ext.LiquipediaDB.lpdb('datapoint', {
					conditions = tostring(
						ConditionTree(BooleanOperator.all)
							:add(ConditionNode(ColumnName('type'), Comparator.eq, 'project contributor'))
							:add(ConditionNode(ColumnName('name'), Comparator.eq, self.props.ProjectUrl))
					),
					query = 'count::pageid'
				})[1].count_pageid,
			},
			HtmlWidgets.Br{},
			{
				IconFa{iconName = 'articles', screenReaderHidden = true},
				' Articles Created: ',
				mw.getCurrentFrame():callParserFunction('#count_pages_by_prefix', self.props.ProjectUrl),
			},
			HtmlWidgets.Br{},
			{
				IconFa{iconName = 'lastupdated', screenReaderHidden = true},
				' Last Update: ',
				Countdown._create{
					date = DateExt.toCountdownArg(
						mw.getCurrentFrame():callParserFunction(
							'#lastupdated_by_prefix',
							self.props.ProjectUrl .. '/'
						)
					),
					rawdatetime = true
				},
			}
		)
	}
end

return ProjectOverview
