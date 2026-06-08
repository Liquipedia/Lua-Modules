---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/PotentialQualifiers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {participant: TeamParticipant}
---@return Widget?
local function PotentialQualifiers(props)
	local participant = props.participant
	local potentialQualifiers = participant.potentialQualifiers

	if not potentialQualifiers or #potentialQualifiers == 0 then
		return nil
	end

	local children = {
		Div{
			classes = {'team-participant-card__subheader'},
			children = 'Potential qualifiers'
		},
		Div{
			classes = {'team-participant-card__potential-qualifiers-list'},
			children = Array.map(potentialQualifiers, function(qualifierOpponent)
				return OpponentDisplay.BlockOpponent{
					opponent = qualifierOpponent,
					teamStyle = 'standard',
					additionalClasses = {'team-participant-card__potential-qualifiers-item'}
				}
			end)
		}
	}

	return Div{
		classes = {'team-participant-card__potential-qualifiers'},
		children = children
	}
end

return Component.component(PotentialQualifiers)
