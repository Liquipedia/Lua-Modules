---
-- @Liquipedia
-- page=Module:Widget/Transfer/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local IconModule = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Platform = Lua.import('Module:Platform')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local References = Lua.import('Module:Transfer/References')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local EMPTY_POSITION_ICON = IconImage{imageLight = 'Logo filler event.png', size = '16px'}
local HAS_PLATFORM_ICONS = Lua.moduleExists('Module:Platform/data')
local SPECIAL_ROLES = {'retired', 'inactive', 'military', 'passed away'}
local TRANSFER_STATUS_TO_ICON_NAME = {
	neutral = 'transferbetween',
	['from-team'] = 'transfertofreeagent',
	['to-team'] = 'transferfromfreeagent',
}
local RUMOUR_STATUS_TO_ICON_ARGS = {
	correct = {iconName = 'correct', color = 'forest-green-text'},
	wrong = {iconName = 'wrong', color = 'cinnabar-text'},
	uncertain = {iconName = 'uncertain', color = 'bright-sun-text'},
}
local CONFIDENCE_TO_COLOR = {
	certain = 'forest-theme-dark-text',
	likely = 'bright-sun-non-text',
	possible = 'california-non-text',
	unlikely = 'cinnabar-theme-dark-text',
	unknown = 'gigas-theme-light-alt-text',
}

---@param props {classes?: string[], css?: table<string, string|number?>, children?: Renderable|Renderable[]}
---@return HtmlNode
local function createDivCell(props)
	return Html.Div{
		classes = Array.extend('divCell', props.classes),
		css = props.css,
		children = props.children
	}
end

local TransferRowWidget = {}

---@param props {transfers: transfer[], showTeamName: boolean?}
---@return HtmlNode?
function TransferRowWidget.render(props)
	local transfer = TransferRowWidget._enrichTransfers(props.transfers)
	if Logic.isEmpty(transfer) then return end

	return Html.Div{
		classes = TransferRowWidget._getClasses(transfer),
		children = WidgetUtil.collect(
			TransferRowWidget.rumourCells(transfer),
			TransferRowWidget.date(transfer),
			TransferRowWidget.platform(transfer),
			TransferRowWidget.players(transfer),
			TransferRowWidget.from(transfer, props.showTeamName),
			TransferRowWidget.icon(transfer),
			TransferRowWidget.to(transfer, props.showTeamName),
			TransferRowWidget.references(transfer)
		)
	}
end

---@private
---@param transfers transfer[]
---@return enrichedTransfer
function TransferRowWidget._enrichTransfers(transfers)
	if Logic.isEmpty(transfers) then return {} end

	local transfer = transfers[1]

	local date = DateExt.toYmdInUtc(transfer.date)

	return {
		from = {
			teams = {
				String.nilIfEmpty(transfer.fromteamtemplate),
				String.nilIfEmpty(transfer.extradata.fromteamsectemplate),
			},
			roles = {
				String.nilIfEmpty(transfer.role1),
				String.nilIfEmpty(transfer.extradata.role1sec),
			},
		},
		to = {
			teams = {
				String.nilIfEmpty(transfer.toteamtemplate),
				String.nilIfEmpty(transfer.extradata.toteamsectemplate),
			},
			roles = {
				String.nilIfEmpty(transfer.role2),
				String.nilIfEmpty(transfer.extradata.role2sec),
			},
		},
		platform = HAS_PLATFORM_ICONS and TransferRowWidget._displayPlatform(transfer.extradata.platform) or nil,
		displayDate = String.nilIfEmpty(transfer.extradata.displaydate) or date,
		date = date,
		wholeteam = Logic.readBool(transfer.wholeteam),
		players = TransferRowWidget._readPlayers(transfers),
		references = TransferRowWidget._getReferences(transfers),
		confirmed = transfer.extradata.confirmed,
		confidence = transfer.extradata.confidence,
		isRumour = transfer.extradata.isRumour,
	}
end

---@private
---@param platform string
---@return string?
function TransferRowWidget._displayPlatform(platform)
	if not HAS_PLATFORM_ICONS then return end
	if Logic.isEmpty(platform) then return '' end
	return Platform._getIcon(platform) or ''
end

---@private
---@param transfers transfer[]
---@return transferPlayer[]
function TransferRowWidget._readPlayers(transfers)
	return Array.map(transfers, function(transfer)
		local extradata = transfer.extradata
		return {
			pageName = transfer.player,
			displayName = String.nilIfEmpty(extradata.displayname) or transfer.player,
			flag = transfer.nationality,
			icons = {String.nilIfEmpty(extradata.icon), String.nilIfEmpty(extradata.icon2)},
			faction = extradata.faction,
			chars = extradata.chars,
		}
	end)
end

---@private
---@param transfers transfer[]
---@return string[]
function TransferRowWidget._getReferences(transfers)
	local references = {}
	Array.forEach(transfers, function(transfer)
		Array.extendWith(references, References.fromStorageData(transfer.reference))
	end)
	references = References.makeUnique(references)

	return Array.map(references, References.createReferenceIconDisplay)
end

---@private
---@param transfer enrichedTransfer
---@return string[]
function TransferRowWidget._getClasses(transfer)
	if transfer.isRumour then
		return {'RumourRow'}
	end
	return {
		'divRow',
		'mainpage-transfer-' .. TransferRowWidget._getStatus(transfer)
	}
end

---@private
---@param transfer enrichedTransfer
---@return string
function TransferRowWidget._getStatus(transfer)
	if transfer.from.teams[1] and transfer.to.teams[1] then
		return 'neutral'
	elseif transfer.from.teams[1] then
		return 'from-team'
	elseif transfer.to.teams[1] then
		return 'to-team'
	elseif (
		TransferRowWidget._isSpecialRole(transfer.from.roles[1]) and TransferRowWidget._isSpecialRole(transfer.to.roles[1])
	) then
		return 'neutral'
	elseif TransferRowWidget._isSpecialRole(transfer.from.roles[1]) then
		return 'to-team'
	elseif TransferRowWidget._isSpecialRole(transfer.to.roles[1]) then
		return 'from-team'
	end

	return 'neutral'
end

---@private
---@param role string?
---@return boolean
TransferRowWidget._isSpecialRole = FnUtil.memoize(function (role)
	if not role then return false end
	role = role:lower()
	return Table.includes(SPECIAL_ROLES, role)
end)

---@param transfer enrichedTransfer
---@return HtmlNode[]?
function TransferRowWidget.rumourCells(transfer)
	if not transfer.isRumour then return end

	local confidence = transfer.confidence

	return {
		createDivCell{
			classes = {'Status'},
			children = IconFa(RUMOUR_STATUS_TO_ICON_ARGS[transfer.confirmed])
		},
		createDivCell{
			classes = {'Confidence', CONFIDENCE_TO_COLOR[confidence]},
			css = {['font-weight'] = 'bold'},
			children = confidence and String.upperCaseFirst(confidence) or nil
		}
	}
end

---@param transfer enrichedTransfer
---@return HtmlNode
function TransferRowWidget.date(transfer)
	return createDivCell{
		classes = {'Date'},
		children = transfer.displayDate
	}
end

---@param transfer enrichedTransfer
---@return HtmlNode?
function TransferRowWidget.platform(transfer)
	if not transfer.platform then return end

	return createDivCell{
		classes = {'GameIcon'},
		children = transfer.platform
	}
end

---@param transfer enrichedTransfer
---@return HtmlNode
function TransferRowWidget.players(transfer)
	return createDivCell{
		classes = {'Name'},
		children = Array.map(transfer.players, function (player)
			return PlayerDisplay.BlockPlayer{player = player}
		end)
	}
end

---@param transfer enrichedTransfer
---@param showTeamName boolean?
---@return HtmlNode
function TransferRowWidget.from(transfer, showTeamName)
	return TransferRowWidget._displayTeam{
		data = transfer.from,
		date = transfer.date,
		isOldTeam = true,
		showTeamName = showTeamName,
	}
end

---@private
---@param args {isOldTeam: boolean, date: string, data: {teams: string[], roles: string[]}, showTeamName: boolean?}
---@return HtmlNode
function TransferRowWidget._displayTeam(args)
	local showTeamName = args.showTeamName
	local isOldTeam = args.isOldTeam
	local data = args.data
	local align = isOldTeam and 'right' or 'left'

	---@param props {children?: Renderable|Renderable[]}
	---@return HtmlNode
	local function createTeamCell(props)
		return createDivCell{
			classes = {'Team', isOldTeam and 'OldTeam' or 'NewTeam'},
			css = showTeamName and {['text-align'] = align} or nil,
			children = props.children
		}
	end

	if not data.teams[1] and not data.roles[1] then
		return createTeamCell{children = TransferRowWidget._createRole{
			roles = {'&nbsp;None&nbsp;'}, marginDirection = align, showTeamName = showTeamName
		}}
	end

	---@param team string
	---@return VNode
	local function teamDisplay(team)
		return OpponentDisplay.InlineTeamContainer{
			template = team,
			date = args.date,
			flip = isOldTeam,
			style = showTeamName and 'short' or 'icon'
		}
	end

	local teams = Array.map(data.teams, teamDisplay)

	local roleCell = TransferRowWidget._createRole{
		roles = data.roles, team = data.teams[1], marginDirection = align, showTeamName = showTeamName
	}

	return createTeamCell{
		children = WidgetUtil.collect(
			Array.interleave(teams, ' / '),
			#teams >= 1 and Html.Br{} or nil,
			roleCell
		)
	}
end

---@private
---@param props {roles: string[], team: string?, marginDirection: 'left'|'right', showTeamName: boolean?}
---@return HtmlNode?
function TransferRowWidget._createRole(props)
	if Logic.isEmpty(props.roles) then return end

	if Logic.isEmpty(props.team) then
		return Html.Span{
			css = {['font-style'] = 'italic'},
			children = Array.interleave(Array.filter(props.roles, Logic.isNotEmpty), '/')
		}
	end

	return Html.Span{
		css = {
			['font-style'] = 'italic',
			['font-size'] = '85%',
			['margin' .. props.marginDirection] = props.showTeamName and '60px' or nil,
		},
		children = WidgetUtil.collect(
			'(',
			Array.interleave(Array.filter(props.roles, Logic.isNotEmpty), '/'),
			')'
		)
	}
end

---@private
---@param status string?
---@return VNode
TransferRowWidget._getTransferArrow = FnUtil.memoize(function (status)
	return IconFa{iconName = TRANSFER_STATUS_TO_ICON_NAME[status]}
end)

---@private
---@param iconInput string?
---@return Renderable
TransferRowWidget._getIcon = FnUtil.memoize(function (iconInput)
	if Logic.isEmpty(iconInput) then
		return EMPTY_POSITION_ICON
	end
	---@cast iconInput -nil
	local icon = IconModule[iconInput:lower()]
	if not icon then
		mw.log( 'No entry found in Module:PositionIcon/data: ' .. iconInput)
		mw.ext.TeamLiquidIntegration.add_category('Pages with transfer errors')
		return EMPTY_POSITION_ICON
	end

	return icon
end)

---@param transfer enrichedTransfer
---@return HtmlNode
function TransferRowWidget.icon(transfer)
	if not IconModule then
		return createDivCell{
			classes = {'Icon'},
			css = {width = '70px', ['font-size'] = 'larger'},
			children = TransferRowWidget._getTransferArrow(TransferRowWidget._getStatus(transfer))
		}
	end

	local targetRoleIsSpecialRole = TransferRowWidget._isSpecialRole(transfer.to.roles[1])

	return createDivCell{
		classes = {'Icon'},
		css = {width = '70px'},
		children = WidgetUtil.collect(Array.interleave(
			Array.map(transfer.players, function (player)
				return Html.Fragment{children = {
					TransferRowWidget._getIcon(player.icons[1]),
					'&nbsp;',
					TransferRowWidget._getTransferArrow(TransferRowWidget._getStatus(transfer)),
					'&nbsp;',
					TransferRowWidget._getIcon(player.icons[2] or targetRoleIsSpecialRole and player.icons[1] or nil)
				}}
			end),
			Html.Br{}
		))
	}
end

---@param transfer enrichedTransfer
---@param showTeamName boolean?
---@return HtmlNode
function TransferRowWidget.to(transfer, showTeamName)
	return TransferRowWidget._displayTeam{
		data = transfer.to,
		date = transfer.date,
		isOldTeam = false,
		showTeamName = showTeamName,
	}
end

---@param transfer enrichedTransfer
---@return HtmlNode
function TransferRowWidget.references(transfer)
	return createDivCell{
		classes = {'Ref'},
		children = Array.interleave(transfer.references, Html.Br{})
	}
end

return Component.component(TransferRowWidget.render, {
	showTeamName = Logic.readBool((Info.config.transfers or {}).showTeamName)
})
