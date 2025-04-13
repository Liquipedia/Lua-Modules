---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchPage/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- luacheck: ignore
return {
	game =
		[=[
			<h3>Player Performance</h3>
			<div class="match-bm-players-wrapper">
				<div class="match-bm-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.1.iconDisplay}}</div>
					{{#teams.1.players}}
						<div class="match-bm-players-player">
							<div class="match-bm-players-player-character">
								<div class="match-bm-players-player-avatar"><div class="match-bm-players-player-icon">{{&heroIcon}}</div><div class="match-bm-players-player-role role--{{teams.1.side}}">[[File:Dota2 {{facet}} facet icon darkmode.png|link=|{{facet}}]]</div></div>
								<div class="match-bm-players-player-name">[[{{link}}|{{displayName}}]]<i>{{character}}</i></div>
							</div>
							<div class="match-bm-players-player-loadout">
								<!-- Loadout -->
								<div class="match-bm-players-player-loadout-items">
									<!-- Items -->
									{{#items}}<div class="match-bm-players-player-loadout-item">{{&.}}</div>{{/items}}
									{{#backpackitems}}<div class="match-bm-players-player-loadout-item item--backpack">{{&.}}</div>{{/backpackitems}}
								</div>
								<div class="match-bm-players-player-loadout-rs-wrap">
									<!-- Special Items -->
									<div class="match-bm-players-player-loadout-rs">{{&neutralitem}}</div>
									<div class="match-bm-players-player-loadout-rs">{{#shard}}[[File:Dota2_Aghanim's_Shard_symbol_allmode.png|64px|Aghanim's Shard|link=]]{{/shard}}</div>
									<div class="match-bm-players-player-loadout-rs">{{#scepter}}[[File:Dota2_Aghanim's_Scepter_symbol_allmode.png|64px|Aghanim's Scepter|link=]]{{/scepter}}</div>
								</div>
							</div>
							<div class="match-bm-players-player-stats">
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-skull-crossbones"></i>KDA</div><div class="match-bm-players-player-stat-data">{{kills}}<span class="slash">/</span>{{deaths}}<span class="slash">/</span>{{assists}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-sword"></i>DMG</div><div class="match-bm-players-player-stat-data">{{displayDamageDone}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-swords"></i>LH/DN</div><div class="match-bm-players-player-stat-data">{{lasthits}}<span class="slash">/</span>{{denies}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coin"></i>NET</div><div class="match-bm-players-player-stat-data">{{displayGold}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coins"></i>GPM</div><div class="match-bm-players-player-stat-data">{{gpm}}</div></div>
							</div>
						</div>
					{{/teams.1.players}}
				</div>
				<div class="match-bm-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.2.iconDisplay}}</div>
					{{#teams.2.players}}
						<div class="match-bm-players-player">
							<div class="match-bm-players-player-character">
								<div class="match-bm-players-player-avatar"><div class="match-bm-players-player-icon">{{&heroIcon}}</div><div class="match-bm-players-player-role role--{{teams.2.side}}">[[File:Dota2 {{facet}} facet icon darkmode.png|link=|{{facet}}]]</div></div>
								<div class="match-bm-players-player-name">[[{{link}}|{{displayName}}]]<i>{{character}}</i></div>
							</div>
							<div class="match-bm-players-player-loadout">
								<!-- Loadout -->
								<div class="match-bm-players-player-loadout-items">
									{{#items}}<div class="match-bm-players-player-loadout-item">{{&.}}</div>{{/items}}
									{{#backpackitems}}<div class="match-bm-players-player-loadout-item item--backpack">{{&.}}</div>{{/backpackitems}}
								</div>
								<div class="match-bm-players-player-loadout-rs-wrap">
									<!-- Special Items -->
									<div class="match-bm-players-player-loadout-rs">{{&neutralitem}}</div>
									<div class="match-bm-players-player-loadout-rs">{{#shard}}[[File:Dota2_Aghanim's_Shard_symbol_allmode.png|64px|Aghanim's Shard|link=]]{{/shard}}</div>
									<div class="match-bm-players-player-loadout-rs">{{#scepter}}[[File:Dota2_Aghanim's_Scepter_symbol_allmode.png|64px|Aghanim's Scepter|link=]]{{/scepter}}</div>
								</div>
							</div>
							<div class="match-bm-players-player-stats">
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-skull-crossbones"></i>KDA</div><div class="match-bm-players-player-stat-data">{{kills}}<span class="slash">/</span>{{deaths}}<span class="slash">/</span>{{assists}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-sword"></i>DMG</div><div class="match-bm-players-player-stat-data">{{displayDamageDone}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-swords"></i>LH/DN</div><div class="match-bm-players-player-stat-data">{{lasthits}}<span class="slash">/</span>{{denies}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coin"></i>NET</div><div class="match-bm-players-player-stat-data">{{displayGold}}</div></div>
								<div class="match-bm-players-player-stat"><div class="match-bm-players-player-stat-title"><i class="fas fa-coins"></i>GPM</div><div class="match-bm-players-player-stat-data">{{gpm}}</div></div>
							</div>
						</div>
					{{/teams.2.players}}
				</div>
			</div>

		]=]
}
