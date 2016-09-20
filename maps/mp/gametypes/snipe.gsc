/* vim: syntax=C++ */

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;

	ModMajorVersion = 1;
	ModMinorVersion	= 4;
	level.Version = " v" + ModMajorVersion + "." + ModMinorVersion;

	level.ExternalGameSettings = mod_main\settings::LoadGameSettings();

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	level.objectiveBased = true;

	setDvarIfUninitialized( "scr_" + level.gameType + "_timelimit", level.ExternalGameSettings["TimePerRound"] );
	registerTimeLimitDvar( level.gameType, level.ExternalGameSettings["TimePerRound"], 0, 1440 );

	setDvarIfUninitialized( "scr_" + level.gameType + "_scorelimit", 0 );
	registerScoreLimitDvar( level.gameType, 0, 0, 500 );

	setDvarIfUninitialized( "scr_" + level.gameType + "_winlimit", level.ExternalGameSettings["WinLimit"] );
	registerWinLimitDvar( level.gameType, level.ExternalGameSettings["WinLimit"], 3, 24 );

	setDvarIfUninitialized( "scr_" + level.gameType + "_roundswitch", 2 );
	registerRoundSwitchDvar( level.gameType, 2, 0, 30 );

	setDvarIfUninitialized( "scr_" + level.gameType + "_roundlimit", 12 );
	registerRoundLimitDvar( level.gameType, 0, 0, 12 );

	setDvarIfUninitialized( "scr_" + level.gameType + "_halftime", 0 );
	registerHalfTimeDvar( level.gameType, 0, 0, 12 );

	setDvar("scr_" + level.gameType + "_numlives", 1);
	registerNumLivesDvar( level.gameType, 1, 0, 100);

	// We don't want fall damage do we?
	if ( !level.ExternalGameSettings["EnableFallDamage"] )
	{
		setDvar("bg_fallDamageMinHeight", 998);
		setDvar("bg_fallDamageMaxHeight", 999);
	}

	setDvar("scr_player_maxhealth", level.ExternalGameSettings["PlayerMaxHealth"]);
	setDvar("g_speed", level.ExternalGameSettings["GameSpeed"]);

	level.teamBased = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.getSpawnPoint = ::getSpawnPoint;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onNormalDeath = ::onNormalDeath;

	game["dialog"]["gametype"] = "Enhanced Sniping";

	if ( getDvarInt( "g_hardcore" ) )
		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "camera_thirdPerson" ) )
		game["dialog"]["gametype"] = "thirdp_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "scr_diehard" ) )
		game["dialog"]["gametype"] = "dh_" + game["dialog"]["gametype"];
	else if (getDvarInt( "scr_" + level.gameType + "_promode" ) )
		game["dialog"]["gametype"] = game["dialog"]["gametype"] + "_pro";

}

onPrecacheGameType()
{
}

onStartGameType()
{
	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	setObjectiveHintText( game["attackers"], level.ExternalGameSettings["ObjectiveHintAxis"] );
	setObjectiveHintText( game["defenders"], level.ExternalGameSettings["ObjectiveHintAllies"] );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );

	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	allowed[0] = level.gameType;
	allowed[1] = "airdrop_pallet";
	maps\mp\gametypes\_gameobjects::main( allowed );

	if ( game["roundsPlayed"] == 0 && level.ExternalGameSettings["EnableWarmUpRound"] )
		level.WarmUpRound = true;
	else
		level.WarmUpRound = false;

	if ( level.WarmUpRound )
	{
		maps\mp\gametypes\_rank::registerScoreInfo( "win", 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "loss", 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "tie", 0 );

		maps\mp\gametypes\_rank::registerScoreInfo( "kill", 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "assist", 0 );

		setDvar("scr_" + level.gameType + "_numlives", 0);
	}

	else
	{
		maps\mp\gametypes\_rank::registerScoreInfo( "win", 2 );
		maps\mp\gametypes\_rank::registerScoreInfo( "loss", 1 );
		maps\mp\gametypes\_rank::registerScoreInfo( "tie", 1.5 );

		maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
		maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
		maps\mp\gametypes\_rank::registerScoreInfo( "assist", 20 );

		setDvar("scr_" + level.gameType + "_timelimit", level.ExternalGameSettings["TimePerRound"] );
		setDvar("scr_" + level.gameType + "_numlives", 1);
	}

	onRoundStart();
}

onRoundStart()
{
	if ( level.ExternalGameSettings["EnableRoundStartTimer"] && game["roundsPlayed"] > 0 && !level.WarmUpRound ) // We don't want to set a timer if we're already in the pre-match timer!
		RoundStartTimer( level.ExternalGameSettings["RoundStartTimerLength"] );

	if ( level.WarmUpRound )
	{
		WarmUpTimer( level.ExternalGameSettings["WarmUpRoundTimerLength"] );
		mod_main\main::resetScores();
		return;
	}

	foreach( player in level.players )
	{
		if ( ( player.pers["resurrection_earned"] && !player.pers["resurrection_given"] ) || level.ExternalGameSettings["DEV"] )
			player thread maps\mp\killstreaks\_resurrection::killstreak_give( "resurrection_stone" );
	}

	delayThread( 5, maps\mp\_load::delayedThread() );
}

getSpawnPoint()
{
	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";

	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( spawnPointName );
	spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

	return spawnPoint;
}

onSpawnPlayer()
{
	level notify ( "spawned_player" );
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId)
{
	victim = self;

	if(attacker.finalkill && isPlayer(attacker))
	{
		if (sMeansOfDeath == "MOD_HEAD_SHOT" && level.aliveCount[victim.team] == 0 || game["roundsWon"][attacker.team] >= ( getDvarInt( "scr_" + level.gametype + "_winlimit" ) - 1) && level.aliveCount[victim.team] == 0)
		{
			distance = distance( attacker.origin, victim.origin );
			if ( distance > 100 )
				attacker thread mod_main\main::runBulletCam( victim );
		}
	}

	thread checkAllowSpectating();
}

checkAllowSpectating()
{
	wait ( 0.05 );

	update = false;
	if ( !level.aliveCount[ game["attackers"] ] )
	{
		level.spectateOverride[game["attackers"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( !level.aliveCount[ game["defenders"] ] )
	{
		level.spectateOverride[game["defenders"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( update )
		maps\mp\gametypes\_spectating::updateSpectateSettings();
}

snipe_endGame( winningTeam, endReasonText )
{
	thread maps\mp\gametypes\_gamelogic::endGame( winningTeam, endReasonText );
}

onDeadEvent( team )
{
	if ( team == game["attackers"] )
		level thread snipe_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );

	else if ( team == game["defenders"] )
		level thread snipe_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
}

onOneLeftEvent( team )
{
	lastPlayer = getLastLivingPlayer( team );
	lastPlayer thread giveLastOnTeamWarning();
}

onNormalDeath( victim, attacker, lifeId )
{
	attacker maps\mp\killstreaks\_resurrection::seeIfKillstreakOwed();
	victim.deathLoc = victim.origin;

	if ( game["state"] == "postgame" || level.aliveCount[victim.team] < 1 && !level.WarmUpRound )
		attacker.finalKill = true;
}

giveLastOnTeamWarning()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );

	otherTeam = getOtherTeam( self.pers["team"] );
	level thread teamPlayerCardSplash( "callout_lastteammemberalive", self, self.pers["team"] );
	level thread teamPlayerCardSplash( "callout_lastenemyalive", self, otherTeam );
	level notify ( "last_alive", self );
	self maps\mp\gametypes\_missions::lastManSD();
}

onTimeLimit()
{
	snipe_endGame( "forfeit", "All enemies failed to be eliminated!" );
}

RoundStartTimer( duration )
{
	level endon( "RoundStartTimer_Finished" );
	visionSetNaked( "mpIntro", 0 );

	for ( index = 0; index < level.players.size; index++ )
		level.players[index] freezeControlsWrapper( true );

	roundStartText = createServerFontString( "objective", 1.5 );
	roundStartText setPoint( "CENTER", "CENTER", 0, -40 );
	roundStartText.sort = 1001;
	roundStartText.foreground = false;
	roundStartText.hidewheninmenu = true;

	roundStartText setText( "Round Begins In:" );

	roundStartTimer = createServerFontString( "hudbig", 1 );
	roundStartTimer setPoint( "CENTER", "CENTER", 0, 0 );
	roundStartTimer.sort = 1001;
	roundStartTimer.color = (1,1,0);
	roundStartTimer.foreground = false;
	roundStartTimer.hidewheninmenu = true;

	roundStartTimer maps\mp\gametypes\_hud::fontPulseInit();

	waittillframeend;

	while ( duration != 0 )
	{
		playSoundOnPlayers( "ui_mp_timer_countdown" );

		roundStartTimer setText( duration );
		roundStartTimer thread maps\mp\gametypes\_hud::fontPulse( level );

		if ( duration == 2 )
			level notify( "RoundStartTimer_Finishing" );

		if ( duration == 1 )
		{
			visionSetNaked( getDvar( "mapname" ), 1 );
			level notify( "RoundStartTimer_Finishing" );
		}

		duration--;
		wait ( 1 );
	}

	roundStartTimer destroyElem();
	roundStartText destroyElem();

	for ( index = 0; index < level.players.size; index++ )
		level.players[index] freezeControlsWrapper( false );

	level notify( "RoundStartTimer_Finished" );
}

WarmUpTimer( duration )
{
	visionSetNaked( "grayscale", 0.3 );

	WarmUpText = createServerFontString( "hudbig", 0.7 );
	WarmUpText setPoint( "TOPCENTER", "TOPCENTER", 0, 0 );
	WarmUpText.sort = 1001;
	WarmUpText.foreground = false;
	WarmUpText.hidewheninmenu = true;

	WarmUpText setText( "WarmUp Left:" );

	WarmUpTimer = createServerFontString( "hudbig", 0.7 );
	WarmUpTimer setPoint( "TOPCENTER", "TOPCENTER", 72, 0 );
	WarmUpTimer.sort = 1001;
	WarmUpTimer.foreground = false;
	WarmUpTimer.hidewheninmenu = true;

	waittillframeend;

	while ( duration != 0 )
	{
		if ( duration < 10 )
		{
			playSoundOnPlayers( "ui_mp_timer_countdown" );
			WarmUpTimer.color = (1,0,0);
		}

		WarmUpTimer setText( duration );

		duration--;
		wait ( 1 );
	}

	WarmUpTimer destroyElem();
	WarmUpText destroyElem();

	level notify( "WarmUpTimer_Finished" );

	maps\mp\gametypes\snipe::snipe_endGame( "tie", "Warm Up Over!" );
}
