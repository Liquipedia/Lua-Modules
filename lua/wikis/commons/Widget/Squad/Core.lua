---
-- @Liquipedia
-- page=Module:Widget/Squad/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local SquadUtils = Lua.import('Module:Squad/Utils')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

---@class SquadWidget: Widget
---@operator call(table): SquadWidget
local Squad = Class.new(Widget)
Squad.defaultProps = {
	status = SquadUtils.SquadStatus.ACTIVE,
	type = SquadUtils.SquadType.PLAYER,
}

local SquadStatusToDisplay = {
	[SquadUtils.SquadStatus.ACTIVE] = '',
	[SquadUtils.SquadStatus.INACTIVE] = 'Inactive',
	[SquadUtils.SquadStatus.FORMER] = 'Former',
	[SquadUtils.SquadStatus.FORMER_INACTIVE] = 'Former',
}

local SquadTypeToDisplay = {
	[SquadUtils.SquadType.PLAYER] = 'Players',
	[SquadUtils.SquadType.STAFF] = 'Organization',
}

---@return Table2
function Squad:render()
	local title = self:_title(self.props.status, self.props.title, self.props.type)
	local header = self:_header(self.props.status)

	return TableWidgets.Table{
		title = title,
		children = {
			TableWidgets.TableHeader{
				children = {header},
			},
			TableWidgets.TableBody{
				children = self.props.children,
			},
		},
	}
end

---@param squadStatus SquadStatus
---@param title string?
---@param squadType SquadType
---@return string?
function Squad:_title(squadStatus, title, squadType)
	local defaultTitle
	-- TODO: Work away this special case
	if squadType == SquadUtils.SquadType.PLAYER and
		(squadStatus == SquadUtils.SquadStatus.FORMER or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE) then

		defaultTitle = 'Former Squad'
	elseif squadStatus ~= SquadUtils.SquadStatus.ACTIVE then
		defaultTitle = SquadStatusToDisplay[squadStatus]  .. ' ' .. SquadTypeToDisplay[squadType]
	end

	local titleText = Logic.emptyOr(title, defaultTitle)

	if String.isEmpty(titleText) then
		return
	end

	return titleText
end

---@param status SquadStatus
---@return Widget
function Squad:_header(status)
	local visibility = self:useContext(SquadContexts.ColumnVisibility)

	local function show(col)
		return visibility == nil or visibility[col] == nil or visibility[col] == true
	end

	local isInactive = status == SquadUtils.SquadStatus.INACTIVE or status == SquadUtils.SquadStatus.FORMER_INACTIVE
	local isFormer = status == SquadUtils.SquadStatus.FORMER or status == SquadUtils.SquadStatus.FORMER_INACTIVE

	local name = show('name') and self:useContext(
		SquadContexts.NameSection,
		{TableWidgets.CellHeader{children = {'Name'}}}
	) or nil
	local inactive = isInactive and show('inactivedate') and self:useContext(SquadContexts.InactiveSection, {
		TableWidgets.CellHeader{children = {'Inactive Date'}}
	}) or nil
	local former = isFormer and WidgetUtil.collect(
		show('leavedate') and TableWidgets.CellHeader{children = {'Leave Date'}} or nil,
		show('newteam') and TableWidgets.CellHeader{children = {'New Team'}} or nil
	) or nil
	local role = show('role') and {TableWidgets.CellHeader{children = {self:useContext(SquadContexts.RoleTitle)}}} or nil

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = {'ID'}},
			show('teamIcon') and TableWidgets.CellHeader{} or nil,
			name,
			role,
			show('joindate') and TableWidgets.CellHeader{children = {'Join Date'}} or nil,
			inactive,
			former
		)
	}
end

return Squad
