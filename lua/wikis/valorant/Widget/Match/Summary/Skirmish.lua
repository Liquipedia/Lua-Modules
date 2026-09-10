---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Skirmish
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {skirmish: ValorantSkirmishResult?}
---@return VNode?
local function ValorantMatchSummarySkirmishDisplay(props)
	local skirmish = props.skirmish
	if Logic.isEmpty(skirmish) then
		return
	end
	---@cast skirmish -nil
	local players = Array.map(
		skirmish.players,
		function (player)
			---@type standardPlayer
			return {
				displayName = player.displayname,
				pageName = player.name,
				flag = player.flag,
			}
		end
	)
	return Html.Div{
		classes = {'brkts-popup-body-grid-row'},
		children = {
			Html.B{
				css = {
					['grid-column'] = '1 / -1',
					['justify-self'] = 'center',
				},
				children = 'Skirmish Side Selection Result'
			},
			Html.Div{
				classes = {'brkts-popup-body-grid-row-detail'},
				children = {
					Html.Span{
						css = {
							['justify-self'] = 'end',
						},
						children = PlayerDisplay.InlinePlayer{
							flip = true,
							player = players[1],
						}
					},
					Html.Div{
						css = {
							display = 'grid',
							['grid-template-columns'] = '1fr min-content 1fr',
							gap = '0.25rem',
							['justify-self'] = 'center',
						},
						children = Array.interleave(
							Array.map(
								skirmish.scores,
								function (score, scoreIndex)
									return Html.Span{
										css = skirmish.winner == scoreIndex and {
											['font-weight'] = 'bold'
										} or nil,
										children = score,
									}
								end
							),
							Html.Span{children = '&ndash;'}
						)
					},
					Html.Span{
						css = {
							['justify-self'] = 'start',
						},
						children = PlayerDisplay.InlinePlayer{
							player = players[2],
						}
					},
				}
			},
		}
	}
end

return Component.component(ValorantMatchSummarySkirmishDisplay)
