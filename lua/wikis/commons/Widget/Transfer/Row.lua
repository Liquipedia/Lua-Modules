---
-- @Liquipedia
-- page=Module:Widget/Transfer/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local IconModule = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local EMPTY_POSITION_ICON = IconImage{imageLight = 'Logo filler event.png', size = '16px'}
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

local function createDivCell(props)
	return HtmlWidgets.Div{
		classes = Array.extend('divCell', props.classes),
		css = props.css,
		children = props.children
	}
end

---@class TransferRowWidget: Widget
---@operator call({transfer: enrichedTransfer, showTeamName: boolean?}): TransferRowWidget
---@field props {transfer: enrichedTransfer, showTeamName: boolean?}
local TransferRowWidget = Class.new(Widget)

---@return Widget?
function TransferRowWidget:render()
	local transfer = self.props.transfer
	if Logic.isEmpty(transfer) then return end

	return HtmlWidgets.Div{
		classes = self:_getClasses(),
		children = WidgetUtil.collect(
			self:status(),
			self:confidence(),
			self:date(),
			self:platform(),
			self:players(),
			self:from(),
			self:icon(),
			self:to(),
			self:references()
		)
	}
end

---@private
---@return string[]
function TransferRowWidget:_getClasses()
	local transfer = self.props.transfer

	if transfer.isRumour then
		return {'RumourRow'}
	end
	return {
		'divRow',
		'mainpage-transfer-' .. self:_getStatus()
	}
end

---@private
---@return string
function TransferRowWidget:_getStatus()
	local transfer = self.props.transfer

	if transfer.from.teams[1] and transfer.to.teams[1] then
		return 'neutral'
	elseif transfer.from.teams[1] then
		return 'from-team'
	elseif transfer.to.teams[1] then
		return 'to-team'
	elseif self:_isSpecialRole(transfer.from.roles[1]) then
		return 'to-team'
	elseif self:_isSpecialRole(transfer.to.roles[1]) then
		return 'from-team'
	end

	return 'neutral'
end

---@private
---@param role string?
---@return boolean
function TransferRowWidget:_isSpecialRole(role)
	if not role then return false end
	role = role:lower()
	return Table.includes(SPECIAL_ROLES, role)
end

---@return Widget?
function TransferRowWidget:status()
	local transfer = self.props.transfer

	if not transfer.isRumour then return end

	return createDivCell{
		classes = {'Status'},
		children = IconFa(RUMOUR_STATUS_TO_ICON_ARGS[transfer.confirmed])
	}
end

---@return Widget?
function TransferRowWidget:confidence()
	local transfer = self.props.transfer
	if not transfer.isRumour then return end

	local confidence = transfer.confidence

	return createDivCell{
		classes = {'Confidence', CONFIDENCE_TO_COLOR[confidence]},
		css = {['font-weight'] = 'bold'},
		children = confidence and String.upperCaseFirst(confidence) or nil
	}
end

---@return Widget
function TransferRowWidget:date()
	return createDivCell{
		classes = {'Date'},
		children = self.props.transfer.displayDate
	}
end

---@return Widget?
function TransferRowWidget:platform()
	local transfer = self.props.transfer
	if not transfer.platform then return end

	return createDivCell{
		classes = {'GameIcon'},
		children = transfer.platform
	}
end

---@return Widget
function TransferRowWidget:players()
	return createDivCell{
		classes = {'Name'},
		children = Array.map(self.props.transfer.players, function (player)
			return PlayerDisplay.BlockPlayer{player = player}
		end)
	}
end

---@return Widget
function TransferRowWidget:from()
	return self:_displayTeam{
		data = self.props.transfer.from,
		date = self.props.transfer.date,
		isOldTeam = true,
	}
end

---@private
---@param args {isOldTeam: boolean, date: string, data: {teams: string[], roles: string[]}}
---@return Widget
function TransferRowWidget:_displayTeam(args)
	local showTeamName = self.props.showTeamName
	local isOldTeam = args.isOldTeam
	local data = args.data
	local align = isOldTeam and 'right' or 'left'

	local function createTeamCell(props)
		return createDivCell{
			classes = {'Team', isOldTeam and 'OldTeam' or 'NewTeam'},
			css = showTeamName and {['text-align'] = align} or nil,
			children = props.children
		}
	end

	if not data.teams[1] and not data.roles[1] then
		return createTeamCell{
			children = self:_createRole{'&nbsp;None&nbsp;'}:css('margin-' .. align, showTeamName and '60px' or nil)
		}
	end

	---@param team string
	---@return Widget?
	local function teamDisplay(team)
		return OpponentDisplay.InlineTeamContainer{
			template = team,
			date = args.date,
			flip = isOldTeam,
			style = showTeamName and 'short' or 'icon'
		}
	end

	local teams = Array.map(data.teams, teamDisplay)

	local roleCell = self:_createRole(data.roles, data.teams[1])

	if roleCell and showTeamName and not data.teams[1] then
		roleCell:css('margin-' .. align, '60px')
	end

	return createTeamCell{
		children = WidgetUtil.collect(
			Array.interleave(teams, ' / '),
			#teams >= 1 and HtmlWidgets.Br{} or nil,
			roleCell
		)
	}
end

---@param roles string[]
---@param team string?
---@return Widget?
function TransferRowWidget:_createRole(roles, team)
	if Logic.isEmpty(roles) then return end

	if Logic.isEmpty(team) then
		return HtmlWidgets.Span{
			css = {['font-style'] = 'italic'},
			children = Array.interleave(Array.filter(roles, Logic.isNotEmpty), '/')
		}
	end

	return HtmlWidgets.Span{
		css = {['font-style'] = 'italic', ['font-size'] = '85%'},
		children = WidgetUtil.collect(
			'(',
			Array.interleave(Array.filter(roles, Logic.isNotEmpty), '/'),
			')'
		)
	}
end

---@private
---@return Widget
function TransferRowWidget:_getTransferArrow()
	return IconFa{iconName = TRANSFER_STATUS_TO_ICON_NAME[self:_getStatus()]}
end

---@return Widget
function TransferRowWidget:icon()
	if not IconModule then
		return createDivCell{
			classes = {'Icon'},
			css = {width = '70px', ['font-size'] = 'larger'},
			children = self:_getTransferArrow()
		}
	end

	---@param iconInput string?
	---@return string|Widget
	local getIcon = function(iconInput)
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
	end

	local targetRoleIsSpecialRole = self:_isSpecialRole(self.props.transfer.to.roles[1])

	return createDivCell{
		classes = {'Icon'},
		css = {width = '70px'},
		children = WidgetUtil.collect(Array.interleave(
			Array.map(self.props.transfer.players, function (player)
				return HtmlWidgets.Fragment{children = {
					getIcon(player.icons[1]),
					'&nbsp;',
					self:_getTransferArrow(),
					'&nbsp;',
					getIcon(player.icons[2] or targetRoleIsSpecialRole and player.icons[1] or nil)
				}}
			end),
			HtmlWidgets.Br{}
		))
	}
end

---@return Widget
function TransferRowWidget:to()
	return self:_displayTeam{
		data = self.props.transfer.to,
		date = self.props.transfer.date,
		isOldTeam = false,
	}
end

---@return Widget
function TransferRowWidget:references()
	return createDivCell{
		classes = {'Ref'},
		children = Array.interleave(self.props.transfer.references, HtmlWidgets.Br{})
	}
end

return TransferRowWidget
