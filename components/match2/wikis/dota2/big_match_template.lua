---
-- @Liquipedia
-- wiki=dota2
-- page=Module:BigMatch/Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- todo's:
-- Team logo's are currently 50x50 => need to be 80x80. Already made preparations for this in the css.

-- luacheck: ignore
return {
	header =
		[=[
			<div class="match-bm-lol-match-header">
				<div class="match-bm-match-header-powered-by">Data powered by [[File:Team liquid logo 2019.png|link=]]</div>
				<div class="match-bm-lol-match-header-overview">
					<div class="match-bm-match-header-team">{{#opponents.1}}{{&iconDisplay}}<div class="match-bm-match-header-team-group"><div class="match-bm-match-header-team-long">{{#page}}[[{{page}}|{{name}}]]{{/page}}</div><div class="match-bm-match-header-team-short">[[{{page}}|{{shortname}}]]</div><div class="match-bm-lol-match-header-round-results">{{#seriesDots}}<div class="match-bm-lol-match-header-round-result result--{{.}}"></div>{{/seriesDots}}</div>{{/opponents.1}}</div></div>
					<div class="match-bm-match-header-result">{{#isBestOfOne}}{{#games.1.apiInfo}}{{team1.scoreDisplay}}&ndash;{{team2.scoreDisplay}}{{/games.1.apiInfo}}{{/isBestOfOne}}{{^isBestOfOne}}{{opponents.1.score}}&ndash;{{opponents.2.score}}{{/isBestOfOne}}<div class="match-bm-match-header-result-text">{{statusText}}</div></div>
					<div class="match-bm-match-header-team">{{#opponents.2}}{{&iconDisplay}}<div class="match-bm-match-header-team-group"><div class="match-bm-match-header-team-long">{{#page}}[[{{page}}|{{name}}]]{{/page}}</div><div class="match-bm-match-header-team-short">[[{{page}}|{{shortname}}]]</div><div class="match-bm-lol-match-header-round-results">{{#seriesDots}}<div class="match-bm-lol-match-header-round-result result--{{.}}"></div>{{/seriesDots}}</div>{{/opponents.2}}</div></div>
				</div>
				<div class="match-bm-lol-match-header-tournament">[[{{parent}}|{{tournament}}]]</div>
				<div class="match-bm-lol-match-header-date">{{&dateCountdown}}</div>
			</div>
			{{#isBestOfOne}}<div class="match-bm-lol-game-overview"><div class="match-bm-lol-game-summary">
			<div class="match-bm-lol-game-summary-team">{{#games.1.teams.1.side}}[[File:Lol faction {{games.1.teams.1.side}}.png|link=|{{games.1.teams.1.side}} side]]{{/games.1.teams.1.side}}</div>
			<div class="match-bm-lol-game-summary-center"><div class="match-bm-lol-game-summary-score-holder"><div class="match-bm-lol-game-summary-length">{{games.1.length}}</div></div></div>
			<div class="match-bm-lol-game-summary-team">{{#games.1.teams.2.side}}[[File:Lol faction {{games.1.teams.2.side}}.png|link=|{{games.1.teams.1.side}} side]]{{/games.1.teams.2.side}}</div>
			</div></div>{{/isBestOfOne}}
			{{#extradata.mvp}}<div class="match-bm-lol-match-mvp"><b>MVP</b> {{#players}}[[{{name}}|{{displayname}}]]{{/players}}</div>{{/extradata.mvp}}
		]=],
	footer =
		[=[
			<h3>Additional Information</h3>
			<div class="match-bm-lol-match-additional">
				{{#vods}}
					<div class="match-bm-lol-match-additional-list">{{#icons}}{{&.}}{{/icons}}</div>
				{{/vods}}
				<div class="match-bm-lol-match-additional-list">{{#links}}[[File:{{icon}}|link={{link}}|15px|{{text}}]]{{/links}}</div>
				{{#patch}}
					<div class="match-bm-lol-match-additional-list">[[Patch {{patch}}]]</div>
				{{/patch}}
			</div>
		]=],
	game =
		[=[
			{{^isBestOfOne}}<div class="match-bm-lol-game-overview">
				<div class="match-bm-lol-game-summary">
					<div class="match-bm-lol-game-summary-team">{{&opponents.1.iconDisplay}}</div>
					<div class="match-bm-lol-game-summary-center">
						<div class="match-bm-lol-game-summary-faction">{{#teams.1.side}}[[File:Lol faction {{teams.1.side}}.png|link=|{{teams.1.side}} side]]{{/teams.1.side}}</div>
						<div class="match-bm-lol-game-summary-score-holder">{{#finished}}<div class="match-bm-lol-game-summary-score">{{teams.1.scoreDisplay}}&ndash;{{teams.2.scoreDisplay}}</div><div class="match-bm-lol-game-summary-length">{{length}}</div>{{/finished}}</div>
						<div class="match-bm-lol-game-summary-faction">{{#teams.2.side}}[[File:Lol faction {{teams.2.side}}.png|link=|{{teams.2.side}} side]]{{/teams.2.side}}</div>
					</div>
					<div class="match-bm-lol-game-summary-team">{{&opponents.2.iconDisplay}}</div>
				</div>
			</div>{{/isBestOfOne}}
			<h3>Picks and Bans</h3>
			<div class="match-bm-lol-game-veto collapsed general-collapsible">
				<div class="match-bm-lol-game-veto-overview">
					<div class="match-bm-lol-game-veto-overview-team"><div class="match-bm-lol-game-veto-overview-team-header">{{&opponents.1.iconDisplay}}</div>
						<div class="match-bm-lol-game-veto-overview-team-veto">
							<ul class="match-bm-lol-game-veto-overview-pick" aria-labelledby="picks">{{#teams.1.picks}}<li class="match-bm-lol-game-veto-overview-item">{{vetoNumber}}{{&heroIcon}}<div class="match-bm-lol-game-veto-pick-bar-{{teams.1.side}}"></div></li>{{/teams.1.picks}}</ul>
							<ul class="match-bm-lol-game-veto-overview-ban" aria-labelledby="bans">{{#teams.1.bans}}<li class="match-bm-lol-game-veto-overview-item">{{vetoNumber}}{{&heroIcon}}</li>{{/teams.1.bans}}</ul>
						</div>
					</div>
					<div class="match-bm-lol-game-veto-overview-team"><div class="match-bm-lol-game-veto-overview-team-header">{{&opponents.2.iconDisplay}}</div>
						<div class="match-bm-lol-game-veto-overview-team-veto">
							<ul class="match-bm-lol-game-veto-overview-pick" aria-labelledby="picks">{{#teams.2.picks}}<li class="match-bm-lol-game-veto-overview-item">{{vetoNumber}}{{&heroIcon}}<div class="match-bm-lol-game-veto-pick-bar-{{teams.2.side}}"></div></li>{{/teams.2.picks}}</ul>
							<ul class="match-bm-lol-game-veto-overview-ban" aria-labelledby="bans">{{#teams.2.bans}}<li class="match-bm-lol-game-veto-overview-item">{{vetoNumber}}{{&heroIcon}}</li>{{/teams.2.bans}}</ul>
						</div>
					</div>
				</div>
			</div>
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
						<div>{{teams.1.objectives.barracks}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon inhibitor.png|link=]]<br>Barracks</div>
						<div>{{teams.2.objectives.barracks}}</div>
					</div>
					<div class="match-bm-lol-h2h-stat">
						<div>{{teams.1.objectives.roshans}}</div>
						<div class="match-bm-lol-h2h-stat-title">[[File:Lol stat icon baron.png|link=]]<br>Roshan</div>
						<div>{{teams.2.objectives.roshans}}</div>
					</div>
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
									<div class="match-bm-lol-players-player-loadout-items">
										<!-- Items -->
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:{{backpackitems.1}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.2}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.3}} itemicon dota2 gameasset.png|24px]]</div>
									</div>
									<div class="match-bm-lol-players-player-loadout-rs-wrap">
										<!-- Runes/Spells -->
										<div class="match-bm-lol-players-player-loadout-rs">[[File:{{neutralitem}} itemicon dota2 gameasset.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-rs">{{#shard}}[[File:Dota2_Aghanim's_Shard_symbol_allmode.png|24px]]{{/shard}}</div>
										<div class="match-bm-lol-players-player-loadout-rs">{{#scepter}}[[File:Dota2_Aghanim's_Scepter_symbol_allmode.png|24px]]{{/scepter}}</div>
									</div>
								</div>
							</div>
							<div class="match-bm-lol-players-player-stats">
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=|KDA]]KDA {{kills}}/{{deaths}}/{{assists}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=|Damage]]DMG {{damagedone}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|Last Hits / Denies]]LH/DN {{lasthits}} / {{denies}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|Net Worth]]NET {{gold}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|Gold per Minute]]GPM {{gpm}}</div>
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
									<div class="match-bm-lol-players-player-loadout-items">
										<!-- Items -->
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.1}}.png|24px]][[File:Lol item {{items.2}}.png|24px]][[File:Lol item {{items.3}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:Lol item {{items.4}}.png|24px]][[File:Lol item {{items.5}}.png|24px]][[File:Lol item {{items.6}}.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-item">[[File:{{backpackitems.1}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.2}} itemicon dota2 gameasset.png|24px]][[File:{{backpackitems.3}} itemicon dota2 gameasset.png|24px]]</div>
									</div>
									<div class="match-bm-lol-players-player-loadout-rs-wrap">
										<!-- Runes/Spells -->
										<div class="match-bm-lol-players-player-loadout-rs">[[File:{{neutralitem}} itemicon dota2 gameasset.png|24px]]</div>
										<div class="match-bm-lol-players-player-loadout-rs">{{#shard}}[[File:Dota2_Aghanim's_Shard_symbol_allmode.png|24px]]{{/shard}}</div>
										<div class="match-bm-lol-players-player-loadout-rs">{{#scepter}}[[File:Dota2_Aghanim's_Scepter_symbol_allmode.png|24px]]{{/scepter}}</div>
									</div>
								</div>
							</div>
							<div class="match-bm-lol-players-player-stats">
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon kda.png|link=|KDA]]KDA {{kills}}/{{deaths}}/{{assists}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon dmg.png|link=|Damage]]DMG {{damagedone}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|Last Hits / Denies]]LH/DN {{lasthits}} / {{denies}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|Net Worth]]NET {{gold}}</div>
								<div class="match-bm-lol-players-player-stat">[[File:Lol stat icon cs.png|link=|Gold per Minute]]GPM {{gpm}}</div>
							</div>
						</div>
					{{/teams.2.players}}
				</div>
			</div>

		]=]
}
