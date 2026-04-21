---
-- @Liquipedia
-- page=Module:Features/Squad/Components/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Components/Component')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local SquadUtils = Lua.import('Module:Squad/Utils')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

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

---@param squadStatus SquadStatus
---@param title string?
---@param squadType SquadType
---@return string?
local function getTitle(squadStatus, title, squadType)
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

---@param props {status: SquadStatus, title: string?, type: SquadType, header: Renderable, children: Renderable[]}
---@param context Context
---@return Renderable
local function SquadContainer(props, context)
	local title = getTitle(props.status, props.title, props.type)

	return TableWidgets.Table{
		title = title,
		children = {
			TableWidgets.TableHeader{
				children = props.header,
			},
			TableWidgets.TableBody{
				children = props.children,
			},
		},
	}
end

return Component.component(
	SquadContainer,
	{
		status = SquadUtils.SquadStatus.ACTIVE,
		type = SquadUtils.SquadType.PLAYER,
	}
)
