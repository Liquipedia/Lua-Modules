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
local Div = Html.Div

---@param props ValorantSkirmishResult
---@return VNode?
local function ValorantSkirmishDisplay(props)
	if Logic.isEmpty(props) then
		return
	end
	local players = Array.map(
		props.players,
		function (player)
			---@type standardPlayer
			return {
				displayName = player.displayname,
				pageName = player.name,
				flag = player.flag,
			}
		end
	)
	return Div{
		css = {
			display = 'grid',
			['grid-template-columns'] = '1fr min-content 1fr',
			gap = '0.25rem',
		},
		children = {
			Html.B{
				css = {
					['grid-column'] = '1 / -1'
				},
				children = 'Skirmish Side Selection Result'
			},
			Html.Span{
				css = {
					['justify-self'] = 'end',
				},
				children = PlayerDisplay.InlinePlayer{
					flip = true,
					player = players[1],
				}
			},
			Div{
				css = {
					display = 'grid',
					['grid-template-columns'] = '1fr min-content 1fr',
					gap = '0.25rem',
				},
				children = Array.interleave(
					Array.map(
						props.scores,
						function (score, scoreIndex)
							return Html.Span{
								css = props.winner == scoreIndex and {
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
	}
end

return Component.component(ValorantSkirmishDisplay)
