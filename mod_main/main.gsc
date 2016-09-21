/* vim: syntax=C++ */

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
Sniping mod originally started sometime in 2012
Revisited for NBS sniping server 2015
Authored by RaidMax
*/

init()
{
	level thread onPlayerConnect();
	level thread onPlayerDisconnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connecting", player );

		player setClientDvar( "ui_gametype", "Enhanced Sniping" );
		player.firstConnect = player.pers["firstConnect"];

		if ( player.firstConnect )
				printLnConsole("Connected -> " + player.name );

		if ( !isDefined( player.pers["PerkSwitched"] ) )
			player.pers["PerkSwitched"] = false;
		if ( !isDefined( player.pers["resurrection_given"] ) )
			player.pers["resurrection_given"] = false;
		if ( !isDefined(player.pers["resurrection_earned"] ) )
			player.pers["resurrection_earned"] = false;

		player setClientDvar("sv_cheats", 1);
		player setClientDvar("fx_draw", 0);
		player setClientDvar("sv_cheats", 0);

		player setClientDvar( "cl_maxpackets", 100 );
		player setClientDvar( "snaps", 30 );
		player setClientDvar( "rate", 999999 );

		player thread onPlayerSpawned();
	 	player thread MonitorWeaponSwitch();

		if ( level.ExternalGameSettings["EnableOSD"])
			player thread MonitorOSD();

		if (level.ExternalGameSettings["EnableAimRestriction"] && !level.ExternalGameSettings["DEV"])
			player thread MonitorPlayerADS(player); // This way we monitor it as soon as they connect, rather than starting a new thread EVERY time they spawn.
	}
}

onPlayerDisconnect()
{
	for(;;)
	{
		level waittill( "disconnect", player );
		printLnConsole("Disconnected -> " + player.name );
		player thread eachPlayerDisconnectEvent();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		thread eachPlayerSpawnEvent();
	}
}

eachPlayerSpawnEvent()
{
	self endon("disconnect");
	self endon("death");

	self.isRevive = false;
	self.deathLoc = undefined;
	self takeAllWeapons();

	// sadly we have to do class stuff here. thx repz
	primary = self.pers["primaryWeapon"];
	secondary = level.ExternalGameSettings["SecondaryWeapon"];
	offhand = "throwingknife_mp";

	self [[game["axis_model"]["GHILLIE"]]]();

	if ( !level.WarmUpRound )
		self giveWeapon( primary );

	self giveWeapon( secondary );
	self maps\mp\perks\_perks::givePerk( offhand );
	self _setActionSlot( 1, "nightvision" );

	if ( !level.WarmUpRound )
		self giveMaxAmmo( primary );

	else
	{
		self setWeaponAmmoClip( primary, 0 );
		self setWeaponAmmoStock( primary, 0 );
	}

	self setWeaponAmmoClip( secondary, 0 );
	self setWeaponAmmoStock( secondary, 0 );
	// original sniper speed
	self.isSniper = true;

	if ( level.WarmUpRound )
	{
		self switchToWeapon( secondary );
		freezeControlsWrapper( false );
		self VisionSetNakedForPlayer( "grayscale", 0 );
		self.moveSpeedScaler = randomIntRange( 5, 20 ) / 10;
	}

	else
	{
		self.moveSpeedScaler = 1.0;
		self switchToWeapon( primary );
		self Loadout_Perks(); // Because complaints of "I WANT PERK EVEN THOUGH I HAS NOT UNLOCKED" ;(
		self MonitorPerkSwitch();
	}

	self notify ( "changed_kit" );
	self notify ( "giveLoadout" );

	self iPrintLn( level.ExternalGameSettings["SpawnAdvertisement"] );
}

eachPlayerDisconnectEvent()
{
	if ( level.ExternalGameSettings["EnableOSD"] )
	{
		self.latencyText 	destroyElem();
		self.playersAlive destroyElem();
		self.pers["PerkSwitched"] 				= false;
		self.pers["resurrection_given"] 	= false;
		self.pers["resurrection_earned"] 	= false;
		self.pers["primaryWeapon"] 				= level.ExternalGameSettings["PrimaryWeapon"];
	}
}

showHudHints()
{
		self endon("disconnect");
		self setClientDvar( "r_blur", 8 );
		self freezeControlsWrapper( true );
		self.notifyOverlay setPoint( "topleft" );
		self.notifyOverlay setShader( "black", 640, 480 );
		self.notifyOverlay.alpha = 0.7;
		self.notifyOverlay.color = ( 1, 0, 0 );
		self.notifyOverlay.hideWhenInMenu = true;
		self.notifyOverlay.sort = 100;

		self.notifyOverlay.x = 0;
		self.notifyOverlay.y = 0;
		self.notifyOverlay.alignX = "left";
		self.notifyOverlay.alignY = "top";
		self.notifyOverlay.horzAlign = "fullscreen";
		self.notifyOverlay.vertAlign = "fullscreen";

		self.hintWeapon = self createFontString( "objective", 1 );
		self.hintWeapon.foreground = false;
		self.hintWeapon.font = "hudbig";
		self.hintWeapon.alpha = 0.75;
		self.hintWeapon.color = ( 1.0, 1.0, 1.0 );
		self.hintWeapon.hideWhenInMenu = true;
		self.hintWeapon setPoint ( "CENTER", "TOP", 0, 90 );
		self.hintWeapon setText( "Press ^3[{+smoke}] ^7to switch weapons\nPress ^3[{+actionslot 2}] ^7to switch perks\nPress ^3[{+attack}] ^7to continue" );
}

hideHudHints()
{
	self endon( "disconnect" );
	self.notifyOverlay.alpha = 0;
	self.hintWeapon destroyElem();
	self setClientDvar( "r_blur", 0 );
	self freezeControlsWrapper( false );
}

Loadout_Perks()
{
	self givePerk( "stopping power", true );
	self givePerk( "commando", true );

	if ( self.pers["PerkSwitched"] )
		self givePerk( "marathon", true );
	if ( !self.pers["PerkSwitched"] )
		self givePerk( "sleight of hand", true );
}

MonitorPerkSwitch()
{
	self endon("disconnect");
	self endon("death");

	self notifyOnPlayerCommand( "Player_Pressed_5", "+actionslot 2" );
	lastToggle = 0;
	while ( true )
	{
		self waittill( "Player_Pressed_5" );

		if ( !isAlive( self ) )
		{
			wait( 1 );
			continue;
		}

		if (level.ExternalGameSettings["DEV"])
			mod_main\dev::initTestClients(5);

		thisToggle = ( getTime() / 1000 );
		if ( thisToggle - lastToggle < 10 )
		{
			self iPrintLnBold("You must wait ^310 ^7seconds between switching perks");
		}

		else
		{
			self TogglePerk();
			lastToggle = ( getTime() / 1000 );
		}
	}

	return;
}

MonitorPlayerADS( player )
{
	player endon("disconnect");

	player waittill("spawned_player");

	player notifyOnPlayerCommand( "Player_Scoped_Toggle", "+toggleads_throw" );
	player notifyOnPlayerCommand( "Player_Scoped_Hold", "+speed_throw" );

	while ( true )
	{
		player waittill_either( "Player_Scoped_Toggle", "Player_Scoped_Hold");

		if ( !isAlive( player ) )
		{
			wait( 1 );
			continue;
		}

		ScopeTimeout = 0.6;

		if ( player.pers["PerkSwitched"] )
			ScopeTimeout = 1.45;

		watchedWeapon = getBaseWeaponName( player getCurrentWeapon() ) == "cheytac" || getBaseWeaponName( player getCurrentWeapon() ) == "m40a3" || getBaseWeaponName( player getCurrentWeapon() ) == "remington700";

		if ( watchedWeapon && player playerADS() )
		{
			wait ( ScopeTimeout );
			count = 0;

			while ( player playerADS() > 0.9 && isAlive( player ) )
			{
				Earthquake( 0.85, 0.5, player getTagOrigin( "j_spine4" ), 25 ); // This should be a suprise eh?
				wait ( 0.4 );
				if (count % 5 == 0)
				{
					player iPrintLNBold("This is a quick-scoping only server!");
					count = 0;
				}
				count++;
			}
		}
	}
}

/*startcam()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "cam_end" );

	if( gameFlag( "prematch_done" ) && gameFlag( "prematch_ending" ) )
	{
		self VisionSetNakedForPlayer( getDvar("mapname"), 0.2 );
		self setclientdvar( "r_blur", 0 );
	}

	if ( !gameFlag( "prematch_done" ) && !gameFlag( "prematch_ending" ) && !level.WarmUpRound )
	{
		self.camera = spawn( "script_model", level.mapCenter + ( 0,0,5000 ) );
		self.camera setModel( "tag_origin" );
		self.angle = self getPlayerAngles();
		self.camera.angles = ( self.angle + ( 90, 0, 0 ) );

		if( getDvar( "g_gametype" ) == "snipe" )
		{
			self setClientDvar( "sv_cheats", 1 );
			self setClientDvar( "cg_draw2d", 0 );

			self CameraLinkTo( self.camera, "tag_origin");

			level waittill( "RoundStartTimer_Finishing" );

			self playlocalsound( "ui_camera_whoosh_in" );
			self.camera MoveTo( self getTagOrigin( "j_head" ) + ( 0, 0, 20 ), 2.0, 0, .5 );
			wait ( 1.8 );
			self VisionSetNakedForPlayer( "blacktest", 0.2 );
			wait ( 0.2 );
			self VisionSetNakedForPlayer( getDvar( "mapname" ), .2 );
			self CameraUnlink();

			self setClientDvar( "cg_draw2d", 1 );
			self setClientDvar( "sv_cheats", 0 );

		}
	}

	self notify( "cam_end" );
}*/

MonitorOSD()
{
	self endon("disconnect");

	self.latencyText 								= createFontString( "objective", 1.5 );
	self.latencyText 								setPoint( "TOPRIGHT", "TOPRIGHT", -3, 3);
	self.latencyText.sort 					= 1;
	self.latencyText.foreground 		= false;
	self.latencyText.hidewheninmenu = true;
	self.latencyText.alpha					= 0.75;

	self.playersAlive 							= createFontString( "objective", 1.25 );
	self.playersAlive 							setPoint( "TOPRIGHT", "TOPRIGHT", -3, 20);
	self.playersAlive.sort 					= 1;
	self.playersAlive.foreground 		= false;
	self.playersAlive.hidewheninmenu= true;
	self.playersAlive.alpha					= 0.75;

	while( true )
	{
		if ( !isAlive( self ) )
		{
			self.latencyText 	setText("");
			self.playersAlive setText("");
			wait( 1 );
			continue;
		}

		clientPing = getPlayerPing( self getEntityNumber() );
		self.latencyText setText( GetColorForPing( clientPing ) + clientPing );
		self.playersAlive setText( level.aliveCount[self.team] + " | " + level.aliveCount[getOtherTeam( self.team )] );

		wait ( 1 );	// This is our update interval of OSD
	}
}

MonitorWeaponSwitch()
{
	self endon("disconnect");

	if ( self.firstConnect )
		self.pers["primaryWeapon"] = level.ExternalGameSettings["PrimaryWeapon"];

	self waittill("spawned_player");
	self notifyOnPlayerCommand( "Player_Pressed_Smoke", "+smoke" );

	while ( true )
	{
		self waittill( "Player_Pressed_Smoke" );

		wait( 0.25 );

		if ( !isAlive( self ) || game["state"] == "postgame" || level.WarmUpRound )
			continue;

		primary = self.pers["primaryWeapon"];
		ammoClip 	= self getWeaponAmmoClip( primary );
		ammoStock = self getWeaponAmmoStock( primary );
		newWeapon = "";

		switch( primary )
		{
			case "cheytac_fmj_xmags_mp":
				newWeapon = "m40a3_fmj_xmags_mp";
				break;
			case "m40a3_fmj_xmags_mp":
				newWeapon = "remington700_fmj_xmags_mp";
				break;
			case "remington700_fmj_xmags_mp":
				newWeapon = "cheytac_fmj_xmags_mp";
				break;
		}

		if ( newWeapon == "" )
			newWeapon = "cheytac_fmj_xmags_mp";

		shouldSwitch = false;

		if (self getCurrentWeapon() == primary)
			shouldSwitch = true;

		self takeWeapon( primary );
		self.pers["primaryWeapon"] = newWeapon;
		self.primaryWeapon = newWeapon;
		self giveWeapon( newWeapon );
		self setWeaponAmmoClip( newWeapon, ammoClip );
		self setWeaponAmmoStock( newWeapon, ammoStock );

		if ( shouldSwitch )
		{
			self switchToWeapon( newWeapon );
			wait ( 0.5 );
		}
	}
}

// Global Functions

TogglePerk()
{
	if ( !self.pers["PerkSwitched"] )
	{
		self _unsetPerk( "specialty_fastreload" );
		self _unsetPerk( "specialty_quickdraw" );
		self givePerk( "marathon", true );
		self iPrintLnBold( "Exchanged ^3Sleight of Hand ^7for ^3Marathon^7" );
	}

	else if ( self.pers["PerkSwitched"] )
	{
		self _unsetPerk( "specialty_marathon" );
		self _unsetPerk( "specialty_fastmantle" );
		self givePerk( "sleight of hand", true );
		self iPrintLnBold( "Exchanged ^3Marathon ^7for ^3Sleight of Hand^7" );
	}

	self.pers["PerkSwitched"] = !self.pers["PerkSwitched"];
}

// Misc Functions

runBulletCam( victim )
{
	level endon ("round_win");

	if( level.bulletcam )
	{
		// Im using hide() and actually moving the player ( after after taking their weapon ), as it provides a more seamless transition.
		self hide();
		weapon = self getCurrentWeapon();
		self takeweapon( weapon );
		self freezeControls( true );

		dist = distance(self.origin, victim.origin);
		self.victimpos = ( victim getTagOrigin( "j_head" ) - ( 0, 0, 47 ) ); // Tag j_head orgin seems to return higher than actual, so fixed that.

		bulletcam = spawn( "script_model", ( 0, 0, 0 ) );
		bulletcam.angles = self getPlayerAngles();
		bulletcam.origin = self.origin;

		bulletcam setmodel( "tag_origin" );
		self PlayerLinkToAbsolute( bulletcam );

		endpos = VectorLerp( bulletcam.origin, self.victimpos, 0.9 ); // <3 vector lerp
		bulletcam MoveTo( endpos, dist*.00023, 0, 0.08 );
	}
}

// Utility Functions

givePerk( perk, weWantPro )
{
	_perk = "";
	_proPerk = "";
	switch( perk )
	{
		case "marathon":
			_perk = "marathon";
			_proPerk = "fastmantle";
			break;
		case "sleight of hand":
			_perk = "fastreload";
			_proPerk = "quickdraw";
			break;
		case "stopping power":
			_perk = "bulletdamage";
			_proPerk = "armorpiercing";
			break;
		case "commando":
			_perk = "extendedmelee";
			_proPerk = "falldamage";
			break;
		case "steady aim":
			_perk = "bulletaccuracy";
			_proPerk = "steelnerves";
			break;
	}

	self maps\mp\perks\_perks::givePerk( "specialty_"+ _perk );

	if ( weWantPro )
		self maps\mp\perks\_perks::givePerk( "specialty_"+ _proPerk );
}

GetColorForPing( ping )
{
	if ( ping > 250 )
		return "^1";
	if ( ping > 100 )
		return "^3";
	else
		return "^2";
}

resetScores()
{
	foreach( player in level.players )
	{
		player.pers["score"] 						= 0;
		player.pers["kills"] 						= 0;
		player.pers["deaths"] 					= 0;
		player.pers["cur_kill_streak"] 	= 0;
		player.pers["numkills"]					= 0;
		player.pers["killstreak"] 			= undefined;
		player.pers["lastEarnedStreak"] = undefined;
		player _setActionSlot(4, "");
		player maps\mp\killstreaks\_killstreaks::clearKillstreaks();
	}

	game["roundsWon"]["axis"]		= 0;
	game["roundsWon"]["allies"] = 0;
	game["roundsPlayed"]				= 0;
}
