---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchPage/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- luacheck: ignore
return {
	game =
		[=[
			<h3>Head-to-Head</h3>
			<div class="match-bm-lol-h2h">
				<div class="match-bm-lol-h2h-header">
					<div class="match-bm-lol-h2h-header-team">{{&opponents.1.iconDisplay}}</div>
					<div class="match-bm-lol-h2h-stat-title"></div>
					<div class="match-bm-lol-h2h-header-team">{{&opponents.2.iconDisplay}}</div>
				</div>
				<div class="match-bm-lol-h2h-section">
					<div class="match-bm-lol-h2h-stat">
						<div>{{#finished}}{{teams.1.kills}}/{{teams.1.deaths}}/{{teams.1.assists}}{{/finished}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon kda.png|link=]]<br>KDA</div>
						<div>{{#finished}}{{teams.2.kills}}/{{teams.2.deaths}}/{{teams.2.assists}}{{/finished}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.gold}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon gold.png|link=]]<br>Gold</div>
						<div>{{teams.2.gold}}</div>
					</div>
				</div>
				<div class="match-bm-lol-h2h-section">
				<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.objectives.towers}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon tower.png|link=]]<br>Towers</div>
						<div>{{teams.2.objectives.towers}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.objectives.inhibitors}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon inhibitor.png|link=]]<br>Inhibitors</div>
						<div>{{teams.2.objectives.inhibitors}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.objectives.barons}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon baron.png|link=]]<br>Barons</div>
						<div>{{teams.2.objectives.barons}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.objectives.dragons}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon dragon.png|link=]]<br>Drakes</div>
						<div>{{teams.2.objectives.dragons}}</div>
					</div>
					<!--<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.objectives.heralds}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon herald.png|link=]]<br>Heralds</div>
						<div>{{teams.2.objectives.heralds}}</div>
					</div>-->
				</div>
			</div>
			<h3>Player Performance</h3>
			<div class="match-bm-lol-players-wrapper">
				<div class="match-bm-lol-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.1.iconDisplay}}</div>
					{{#teams.1.players}}
						<div class="match-bm-lol-players-player">
							<div class="match-bm-lol-players-player-details">
								<div class="match-bm-lol-players-player-character">
									<div class="match-bm-lol-players-player-avatar"><div class="match-bm-lol-players-player-icon">{{&heroIcon}}</div><div class="match-bm-lol-players-player-role">[[File:Lol role {{roleIcon}}.png|link=|{{role}}]]</div></div>
									<div class="match-bm-lol-players-player-name">[[{{player}}]]<i>{{character}}</i></div>
								</div>
								<div class="match-bm-lol-players-player-loadout">
									<!-- Loadout -->
									<div class="match-bm-lol-players-player-loadout-rs-wrap">
										<!-- Runes/Spells -->
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Rune {{runeKeystone}}.png|24px]][[File:Rune {{runes.secondary.tree}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Summoner spell {{spells.1}}.png|24px]][[File:Summoner spell {{spells.2}}.png|24px]]</div>
									</div>
									<div class="match-bm-lol-players-player-loadout-items">
										<!-- Items -->
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
									</div>
								</div>
							</div>
							<div class="match-bm-lol-players-player-stats">
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=|KDA]] {{kills}}/{{deaths}}/{{assists}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|CS]] {{creepscore}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=|Damage]] {{damagedone}}</div>
							</div>
						</div>
					{{/teams.1.players}}
				</div>
				<div class="match-bm-lol-players-team"><div class="match-bm-lol-players-team-header">{{&opponents.2.iconDisplay}}</div>
					{{#teams.2.players}}
						<div class="match-bm-lol-players-player">
							<div class="match-bm-lol-players-player-details">
								<div class="match-bm-lol-players-player-character">
									<div class="match-bm-lol-players-player-avatar"><div class="match-bm-lol-players-player-icon">{{&heroIcon}}</div><div class="match-bm-lol-players-player-role">[[File:Lol role {{roleIcon}}.png|link=|{{role}}]]</div></div>
									<div class="match-bm-lol-players-player-name">[[{{player}}]]<i>{{character}}</i></div>
								</div>
								<div class="match-bm-lol-players-player-loadout">
									<!-- Loadout -->
									<div class="match-bm-lol-players-player-loadout-rs-wrap">
										<!-- Runes/Spells -->
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Rune {{runeKeystone}}.png|24px]][[File:Rune {{runes.secondary.tree}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-rs">[[File:Summoner spell {{spells.1}}.png|24px]][[File:Summoner spell {{spells.2}}.png|24px]]</div>
									</div>
									<div class="match-bm-lol-players-player-loadout-items">
										<!-- Items -->
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
									</div>
								</div>
							</div>
							<div class="match-bm-lol-players-player-stats">
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=|KDA]] {{kills}}/{{deaths}}/{{assists}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|CS]] {{creepscore}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=|Damage]] {{damagedone}}</div>
							</div>
						</div>
					{{/teams.2.players}}
				</div>
			</div>
		]=]
}
