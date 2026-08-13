---
-- @Liquipedia
-- page=Module:Widget/GroupToggle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')

local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local Html = Lua.import('Module:Widget/Html')
local B = Html.B
local Div = Html.Div
local Span = Html.Span

---@alias GroupTableProps {
---id: string?,
---bracket: string,
---width: string?,
---done: boolean|string?,
---collapsed: boolean|string?,
---title: string?,
---group: string,
---win1: string?,
---}


---Reads the qualified slots from a bracket
---@param matchGroupId string
---@return standardOpponent[] qualified
---@return boolean finished
local function fetchQualified(matchGroupId)
	local function hasNoByeOpponent(opponents)
		return not Array.any(opponents, function(opp) return (opp.name or ''):lower() == 'bye' end)
	end

	local bracket = MatchGroupUtil.fetchMatchGroup(matchGroupId)
	if Logic.isEmpty(bracket.matchesById) then
		return {Opponent.tbd()}, false
	end
	assert(bracket.type == 'bracket', 'Automated GroupToggle only works with brackets')

	local qualified = {}
	local finished = true
	for _, match in Table.iter.spairs(bracket.matchesById) do
		if #match.opponents > 2 then
			error('Automated GroupToggle only supports matches with 2 opponents')
		elseif hasNoByeOpponent(match.opponents) and (not match.winner or match.winner > 2 or match.winner < 1) then
			finished = false
		end
		if match.bracketData.qualWin and match.bracketData.qualLose then
			table.insert(qualified, match.opponents[1])
			table.insert(qualified, match.opponents[2])
		elseif match.bracketData.qualWin then
			local qualifiedOpponent = match.opponents[match.winner or '']
				or Opponent.tbd()

			table.insert(qualified, qualifiedOpponent)
		end
	end

	if not qualified[1] then
		finished = false
	end

	return qualified, finished
end


---@param props GroupToggleProps
---@return qualified standardOpponent[]
---@return finished boolean
local function parseWinners(props)
	local winners = {}
	local finished = Logic.readBool(props.collapsed) or Logic.readBool(props.done)

	if props.id then
		winners, finished = fetchQualified(props.id)
	end

	for _, winner in Table.iter.pairsByPrefix(props, 'win') do
		-- Gracefully handle wikicode input for winX params (i.e. {{Player}})
		local opponent = Logic.tryCatch(
			function() return Opponent.readOpponentArgs{type = Opponent.solo, name = winner} end,
			function(error) end
		) or winner
		table.insert(winners, opponent)
	end

	if Logic.isEmpty(winners) then
		table.insert(winners, Opponent.tbd())
	end

	return winners, finished
end


---@param props GroupTableProps
---@return VNode?
local function GroupToggle(props)
	local title = (props.title or 'Group') .. ' ' .. props.group .. ': '

	local winners, finished = parseWinners(props)

	winners = Array.map(winners, function(winner)
		return tostring(B{
			children = Opponent.isOpponent(winner)
				and OpponentDisplay.InlineOpponent{opponent = winner}
				or winner
		})
	end)

	return Collapsible{
		css = {
			['width'] = props.width,
			['max-width'] = '100%',
			['margin-bottom'] = '10px',
		},
		shouldCollapse = finished,
		titleWidget = Div{
			classes = {'general-collapsible-default-title'},
			children = {
				B{
					classes = {'wiki-backgroundcolor-light'},
					css = {
						['padding'] = '0 1em',
					},
					children = title,
				},
				Span{
					css = {
						['padding-left'] = '0.25em'
					},
					children = {
						mw.text.listToText(winners),
						#winners == 1 and ' advances.' or ' advance.',
					}
				},
				CollapsibleToggle{css = {float = 'right'}},
			}
		},
		collapseAreaCss = {
			['padding-top'] = '5px'
		},
		children = props.bracket,
	}

end

return Component.component(GroupToggle, {width = '700px'})
