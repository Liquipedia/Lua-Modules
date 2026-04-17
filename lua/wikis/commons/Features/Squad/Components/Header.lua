---
-- @Liquipedia
-- page=Module:Widget/Squad/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Component = Lua.import('Module:Lib/Component/Core')
local Context = Lua.import('Module:Lib/Component/Context')

local SquadUtils = Lua.import('Module:Squad/Utils')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

---@param props {status: SquadStatus}
---@param context any
---@return Table2
local function SquadHeader(props, context)
	local status = props.status
	local visibility = Context.read(context, SquadContexts.ColumnVisibility)

	local function show(col)
		return visibility == nil or visibility[col] == nil or visibility[col] == true
	end

	local isInactive = status == SquadUtils.SquadStatus.INACTIVE or status == SquadUtils.SquadStatus.FORMER_INACTIVE
	local isFormer = status == SquadUtils.SquadStatus.FORMER or status == SquadUtils.SquadStatus.FORMER_INACTIVE

	local name = show('name') and TableWidgets.CellHeader{children = {Context.read(
		context,
		SquadContexts.NameSection
	)}} or nil
	local inactive = isInactive and WidgetUtil.collect(
		show('inactivedate') and TableWidgets.CellHeader{children = {'Inactive Team'}} or nil,
		show('activeteam') and TableWidgets.CellHeader{children = {'Active Team'}} or nil
	) or nil
	local former = isFormer and WidgetUtil.collect(
		show('leavedate') and TableWidgets.CellHeader{children = {'Leave Date'}} or nil,
		show('newteam') and TableWidgets.CellHeader{children = {'New Team'}} or nil
	) or nil
	local role = show('role') and {TableWidgets.CellHeader{children = {Context.read(context, SquadContexts.RoleTitle)}}} or nil

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

return Component.component(
	SquadHeader,
	{
		status = SquadUtils.SquadStatus.ACTIVE,
		type = SquadUtils.SquadType.PLAYER,
	}
)