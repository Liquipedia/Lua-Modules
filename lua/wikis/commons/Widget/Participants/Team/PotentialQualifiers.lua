---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/PotentialQualifiers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class PotentialQualifiers: Widget
---@operator call(table): PotentialQualifiers
local PotentialQualifiers = Class.new(Widget)

---@return Widget?
function PotentialQualifiers:render()
	local participant = self.props.participant
	local potentialQualifiers = participant.potentialQualifiers

	if not potentialQualifiers or #potentialQualifiers == 0 then
		return nil
	end

	local children = {
		Div{
			classes = {'team-participant-card__potential-qualifiers-title'},
			children = 'Potential qualifiers'
		},
		Div{
			classes = {'team-participant-card__potential-qualifiers-list'},
			children = Array.map(potentialQualifiers, function(qualifierOpponent, index)
				return OpponentDisplay.BlockOpponent{
					opponent = qualifierOpponent,
					teamStyle = 'standard',
					additionalClasses = {
						'team-participant-card__potential-qualifiers-item',
						(index % 2 == 1) and 'team-participant-card__potential-qualifiers-item--odd' or nil
					}
				}
			end)
		}
	}

	return Div{
		classes = {'team-participant-card__potential-qualifiers'},
		children = children
	}
end

return PotentialQualifiers
