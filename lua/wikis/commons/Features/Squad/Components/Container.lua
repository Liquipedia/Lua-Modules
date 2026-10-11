---
-- @Liquipedia
-- page=Module:Features/Squad/Components/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local SquadTypes = Lua.import('Module:Features/Squad/Types')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local SquadStatusToDisplay = {
	[SquadTypes.SquadStatus.ACTIVE] = '',
	[SquadTypes.SquadStatus.INACTIVE] = 'Inactive',
	[SquadTypes.SquadStatus.FORMER] = 'Former',
	[SquadTypes.SquadStatus.FORMER_INACTIVE] = 'Former',
}

local SquadTypeToDisplay = {
	[SquadTypes.SquadType.PLAYER] = 'Players',
	[SquadTypes.SquadType.STAFF] = 'Organization',
}

---@param squadStatus SquadStatus
---@param title string?
---@param squadType SquadType
---@return string?
local function getTitle(squadStatus, title, squadType)
	local defaultTitle
	-- TODO: Work away this special case
	if squadType == SquadTypes.SquadType.PLAYER and
		(squadStatus == SquadTypes.SquadStatus.FORMER or squadStatus == SquadTypes.SquadStatus.FORMER_INACTIVE) then

		defaultTitle = 'Former Squad'
	elseif squadStatus ~= SquadTypes.SquadStatus.ACTIVE then
		defaultTitle = SquadStatusToDisplay[squadStatus] .. ' ' .. SquadTypeToDisplay[squadType]
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
				children = {props.header},
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
		status = SquadTypes.SquadStatus.ACTIVE,
		type = SquadTypes.SquadType.PLAYER,
	}
)
