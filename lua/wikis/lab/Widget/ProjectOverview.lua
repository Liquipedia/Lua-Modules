---
-- @Liquipedia
-- page=Module:Widget/ProjectOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Count = Lua.import('Module:Count')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Component = Lua.import('Module:Widget/Component')
local Grid = Lua.import('Module:Widget/Grid')
local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local Panel = Lua.import('Module:Widget/Panel')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LabProjectOverviewParameters
---@field projectName string
---@field projectUrl string
---@field projectImage string?
---@field projectImageDark string?

local ProjectOverview = {}

---@param props LabProjectOverviewParameters
---@return VNode
function ProjectOverview.render(props)
	assert(Logic.isNotEmpty(props.projectUrl), '|projectUrl= not specified')
	return Grid.Cell{
		xs = 12,
		md = 6,
		cellContent = Panel{
			heading = props.projectName,
			padding = true,
			children = Grid.Container{
				gridCells = {
					ProjectOverview._generateImage(props),
					ProjectOverview._generateOverview(props)
				}
			}
		}
	}
end

---@private
---@param props LabProjectOverviewParameters
---@return VNode
function ProjectOverview._generateImage(props)
	local hasImage = Logic.isNotEmpty(props.projectImage)

	return Grid.Cell{
		xs = 12,
		sm = 12,
		md = 6,
		cellContent = Html.Div{
			classes = not hasImage and {'mobile-hide'} or nil,
			css = {
				height = '160px',
				display = 'flex',
				['align-items'] = 'center',
				['justify-content'] = 'center',
			},
			children = {
				IconImage{
					imageLight = hasImage and props.projectImage or 'Filler 600px.png',
					imageDark = hasImage and Logic.emptyOr(props.projectImageDark, props.projectImage) or 'Filler 600px.png',
					size = '260x160px',
					link = props.projectUrl
				}
			}
		}
	}
end

---@private
---@param props LabProjectOverviewParameters
---@return VNode
function ProjectOverview._generateOverview(props)

	local timestamp = DateExt.readTimestamp(
		mw.getCurrentFrame():callParserFunction(
			'#lastupdated_by_prefix',
			props.projectUrl .. '/'
		)
	)

	return Grid.Cell{
		xs = 12,
		sm = 12,
		md = 6,
		cellContent = WidgetUtil.collect(
			Html.H5{
				children = {
					IconFa{iconName = 'projecthome', screenReaderHidden = true},
					Link{link = props.projectUrl}
				}
			},
			{
				IconFa{iconName = 'contributors', screenReaderHidden = true},
				' Current Contributors: ',
				Count.query(
					'datapoint',
					ConditionTree(BooleanOperator.all):add{
						ConditionNode(ColumnName('type'), Comparator.eq, 'project contributor'),
						ConditionNode(ColumnName('name'), Comparator.eq, props.projectUrl)
					}
				),
			},
			Html.Br{},
			{
				IconFa{iconName = 'articles', screenReaderHidden = true},
				' Articles Created: ',
				mw.getCurrentFrame():callParserFunction('#count_pages_by_prefix', props.projectUrl),
			},
			Html.Br{},
			{
				IconFa{iconName = 'lastupdated', screenReaderHidden = true},
				' Last Update: ',
				timestamp and Countdown.create{
					timestamp = timestamp,
					date = DateExt.toCountdownArg(timestamp),
					rawdatetime = true
				} or nil,
			}
		)
	}
end

return Component.component(ProjectOverview.render)
