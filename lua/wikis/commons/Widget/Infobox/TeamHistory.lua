---
-- @Liquipedia
-- page=Module:Widget/Infobox/TeamHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local TeamHistoryAuto = Lua.import('Module:Infobox/Extension/TeamHistory/Auto')

local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Html = Lua.import('Module:Widget/Html')
local Widget = Lua.import('Module:Widget')
local Widgets = Lua.import('Module:Widget/All')

local Big = Html.Big
local Br = Html.Br
local Div = Html.Div
local Small = Html.Small

local DEFAULT_MODE = 'manual'

---@alias automatedHistoryMode
---|'manual' # always use manual input, never call THA
---|'automatic' # always use THA and ignore manual input
---|'manualPrio' # use manual input if present and THA else
---|'merge' # display both manual input and THA
---|'cleanup' # display THA and for logged in users manual input if present too

---@class TeamHistoryWidget: Widget
---@operator call(table): TeamHistoryWidget
---@field props {player: string, manualInput: string?}
local TeamHistory = Class.new(Widget)

---@return VNode?
function TeamHistory:render()
	local teamHistory = self:_getHistory()

	if Logic.isEmpty(teamHistory) then
		return
	end

	return GeneralCollapsible{
		shouldCollapse = true,
		titleWidget = Widgets.Title{
			isCollapsibleToggle = true,
			children = {
				'Team History',
			},
		},
		children = Widgets.Center{children = {teamHistory}},
	}
end

---@return Widget|string?
function TeamHistory:_getHistory()
	local config = (Info.config.infoboxPlayer or {}).automatedHistory or {}
	local manualInput = self.props.manualInput

	---@type automatedHistoryMode
	local mode = config.mode or DEFAULT_MODE
	if mode == DEFAULT_MODE or (Logic.isNotEmpty(manualInput) and mode == 'manualPrio') then
		return manualInput
	end

	local automatedHistory = TeamHistoryAuto.run{player = self.props.player, store = true}

	if Logic.isEmpty(manualInput) or (mode ~= 'cleanup' and mode ~= 'merge') then
		return automatedHistory
	end

	if Logic.isEmpty(automatedHistory) then
		return manualInput
	end

	if mode == 'merge' then
		return Div{children = {
			manualInput,
			automatedHistory,
		}}
	end

	return Div{children = {
		Div{children = {
			Big{
				classes = {'show-when-logged-in', 'navigation-not-searchable'},
				children = {'Automated History'},
			},
			automatedHistory,
		}},
		Div{
			classes = {'show-when-logged-in', 'navigation-not-searchable'},
			children = {
				Big{
					children = {'Manual History'},
				},
				Br{},
				Small{
					children = {'The below shown manual input only shows when logged in.'},
				},
				manualInput,
			},
		},
	}}
end

return TeamHistory
