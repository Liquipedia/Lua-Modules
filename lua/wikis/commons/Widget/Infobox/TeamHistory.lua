---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/TeamHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TeamHistoryAuto = Lua.import('Module:Infobox/Extension/TeamHistoryAuto')
local Widget = Lua.import('Module:Widget')
local Widgets = require('Module:Widget/All')

local Big = HtmlWidgets.Big
local Br = HtmlWidgets.Br
local Div = HtmlWidgets.Div
local Small = HtmlWidgets.Small

local DEFAULT_MODE = 'manual'

---@alias automatedHistoryMode
---|'manual' # always use manual input, never call THA
---|'automatic' # always use THA and ignore manual input
---|'manualPrio' # use manual input if present and THA else
---|'merge' # display both manual input and THA
---|'cleanup' # display THA and for logged in users manual input if present too

---@class TeamHistoryWidget: Widget
---@operator call(table): TitleWidget
local TeamHistory = Class.new(Widget)

---@return Widget[]
function TeamHistory:render()
	local teamHistory = self:_getHistory()

	if Logic.isEmpty(teamHistory) then
		return {}
	end

	return {
		Widgets.Title{children = 'History'},
		Widgets.Center{children = {teamHistory}},
	}
end

---@return Widget|string?
function TeamHistory:_getHistory()
	local config = (Info.config.infoboxPlayer or {}).automatedHistory or {}
	---@type string?
	local manualInput = self.props.manualInput

	---@type automatedHistoryMode
	local mode = config.mode or DEFAULT_MODE
	if mode == DEFAULT_MODE or (Logic.isNotEmpty(manualInput) and mode == 'manualPrio') then
		return manualInput
	end

	local automatedHistory = TeamHistoryAuto{player = self.props.player}:fetch():store():build()

	if Logic.isEmpty(manualInput) or (mode ~= 'cleanup' and mode ~= 'merge') then
		return automatedHistory
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
