#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_playerlogic;

init()
{
	level.missileRemoteLaunchVert = 14000;
	level.missileRemoteLaunchHorz = 7000;
	level.missileRemoteLaunchTargetDist = 1500;

	precacheItem( "remotemissile_projectile_mp" );
	precacheShader( "ac130_overlay_grain" );
	precacheShader( "hud_teamcaret" );
	precacheShader( "cardicon_sniper" );
	precacheString( &"MP_CIVILIAN_AIR_TRAFFIC" );
	
	level.rockets = [];
	
	level.killstreakFuncs["predator_missile"] = ::tryUsePredatorMissile;
	
	level.missilesForSightTraces = [];
}

clearShit()
{
	self endon("shit_finish");
	
	self waittill_any("death", "pred_off", "weapon_switched");
	self clearUsingRemote();
	if( isDefined( self.targetselector ) )
	{
		self.targetselector destroyElem();
		self.selectIcon destroyElem();
		self.targetTitle destroyElem();
		self.targetselectorTitle destroyElem();
		self.spacer destroyElem();
	}
	removeTarketPerk();
	level.rocketactive = false;
	
	self notify("shit_finish");
}

MUSTBEPRED()
{
	self endon("weapon_switched");
	
	while( true )
	{
		if( self getCurrentWeapon() != "killstreak_predator_missile_mp" )
		{
			self notify("weapon_switched");
		}
		wait ( 0.1 );
	}
}
		
tryUsePredatorMissile( lifeId )
{		
	self endon( "pred_off"  );
	self endon( "disconnect" );
	self endon("shit_finish");
	
	if( !level.rocketactive )
	{
		level.rocketactive = true;
		self.playerselected = false;
		
		self thread clearShit();
		self thread MUSTBEPRED();
		
		wait ( 1 );
	
		self.spacer = createIcon( "black", 200, 70 );
		self.spacer setPoint( "CENTER", "CENTER", 0, 0 );
		self.spacer.alpha = 0.5;
		self.spacer.hidewheninmenu = 1;
		
		self.targetselector = createFontString( "hudbig", 0.8 );
		self.targetselector setPoint( "CENTER", "CENTER", 0, 0 );
		self.targetselector setText( "All Targets" );
		self.targetselector.hidewheninmenu = 1;
		
		self.targetselectorTitle = createFontString( "hudbig", .5 );
		self.targetselectorTitle setPoint( "CENTER", "CENTER", 0, -25 );
		self.targetselectorTitle setText( "Hellfire Missile Target Selection" );
		self.targetselectorTitle.hidewheninmenu = 1;
		
		self.targetTitle = createFontString( "objective", .7 );
		self.targetTitle setPoint( "CENTER", "CENTER", 0, 25 );
		self.targetTitle setText( "^3LMB ^7to select   ^3RMB ^7to cycle" );
		self.targetTitle.hidewheninmenu = 1;
			
		self.selectIcon = createIcon( "hud_teamcaret", 24, 24 );
		self.selectIcon setPoint( "CENTER", "CENTER", -92, 0 );
		self.selectIcon.alpha = 1;
		self.selectIcon.hidewheninmenu = 1;
		self.selectIcon.sort = 10;
		
		setDvar("missileRemoteSpeedTargetRange", "2000 6000");
		setDvar("missileRemoteSteerPitchRange", "-180 180");
		setDvar("missileRemoteSteerPitchRate", 200);
		setDvar("missileRemoteSteerYawRate", 200);
		setDvar("missileRemoteSpeedUp", 900 );
		
		self setclientDvar("missileRemoteFOV", 68);
		self setclientDvar("missileRemoteSpeedTargetRange", "2000 6000");
		self setclientDvar("missileRemoteSteerPitchRange", "-180 180");
		self setclientDvar("missileRemoteSteerPitchRate", 200);
		self setclientDvar("missileRemoteSteerYawRate", 200);
		self setclientDvar("missileRemoteSpeedUp", 900);
		
		self setclientDvar("bg_weaponbobmax", 0 );
		
		self thread WaitForRight();
		WaitForLeft();
		
		self notify( "right_finished" );
		
		if( !self.alltargets )
		{
			PlayerTargetsPlayer( self.playertarget );
			giveTarketPerk( self.playertarget );
		}
	
		self.targetselector destroyElem();
		self.selectIcon destroyElem();
		self.targetTitle destroyElem();
		self.targetselectorTitle destroyElem();
		self.spacer destroyElem();
		
		self setUsingRemote( "remotemissile" );
		
		result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak();
		
		if ( result != "success" )
		{
			if ( result != "disconnect" )
			{
				self clearUsingRemote();
				self iPrintLnBold( "Predator Missile unavailable. Please inform RaidMax of this error: result != success" );
				self notify( "pred_off" );
			}
			return false;
		}
	
		level thread _fire( lifeId, self, self.Target );
	
		return true;
	}
	
	else
	{
		self iPrintLnBold( "Predator Missile will be available when airspace is clear." );
		self clearUsingRemote();
		return false;
	}
	
	self notify("pred_off");
	return false;
}

WaitForLeft()
{
	self endon( "left_click" );
	self endon( "death");
	self endon("shit_finish");
	
	self notifyOnPlayerCommand( "left", "+attack" );
	self waittill( "left" );
	
	self playLocalSound( "weap_c4detpack_trigger_plr" );
	
	self.clicked = true;
	
	if( self.alltargets )
	{
		self iprintlnbold( "All targets selected" );
	}
	
	else
	{
		self.alltargets = false;
	}
	
	self notify( "left_click" );
}

WaitForRight()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "left_click" );
	self endon( "right_finished" );
	self endon("shit_finish");
	
	self.clicked = false;
		
	self.playertarget = undefined;
	level.rocketdisttarg = undefined;

	self.alltargets = true;
	
	count = -1;
	
	self notifyOnPlayerCommand( "right", "+toggleads_throw" );
	self notifyOnPlayerCommand( "right2", "+speed_throw" );
	
	LastTarget = undefined;
		
	while( !self.clicked )
	{
		self waittill_either( "right", "right2" );	
		self playLocalSound( "javelin_clu_aquiring_lock" );
		
		self iprintlnbold( LastTarget.name );
		targetableEnts = [];
		
		foreach ( player in level.players )
		{
			if( isAlive( player ) && player != self && player.team != self.team )
			{
				targetableEnts[player.clientid] = player;
			}
		}
		
		foreach ( player in targetableEnts )
		{
			if ( lastTarget != player.guid )
			{
				self.alltargets = false;
				self.targetselector setText( player.name );
				self.playertarget = player;
				level.rocketdisttarg = player;
				LastTarget = player.guid;
				break;
			}
		}

	}
}
	
giveTarketPerk( playertarget )
{
	foreach( player in level.players )
	{
		if( playertarget != player )
		{ 
			player maps\mp\perks\_perks::givePerk("specialty_coldblooded");
		}
	}
	
	return;
}

removeTarketPerk()
{
	foreach( player in level.players )
	{
		player _unsetperk("specialty_coldblooded");
	}
	
	return;
}

PlayerTargetsPlayer( targetplayer )
{	
	foreach( player in level.players )
	{
		if ( player == targetplayer )
		{
			player iprintlnbold( self.name + " is targeting ^1YOU" );
			player PlayLocalSound( "javelin_clu_lock" );
		}
	}	
	return;
}	

getBestSpawnPoint( remoteMissileSpawnPoints )
{
	validEnemies = [];

	foreach ( spawnPoint in remoteMissileSpawnPoints )
	{
		spawnPoint.validPlayers = [];
		spawnPoint.spawnScore = 0;
	}
	
	foreach ( player in level.players )
	{
		if ( !isReallyAlive( player ) )
			continue;

		if ( player.team == self.team )
			continue;
		
		if ( player.team == "spectator" )
			continue;
		
		bestDistance = 999999999;
		bestSpawnPoint = undefined;
	
		foreach ( spawnPoint in remoteMissileSpawnPoints )
		{
			//could add a filtering component here but i dont know what it would be.
			spawnPoint.validPlayers[spawnPoint.validPlayers.size] = player;
		
			potentialBestDistance = Distance2D( spawnPoint.targetent.origin, player.origin );
			
			if ( potentialBestDistance <= bestDistance )
			{
				bestDistance = potentialBestDistance;
				bestSpawnpoint = spawnPoint;	
			}	
		}
		
		//assertEx( isDefined( bestSpawnPoint ), "Closest remote-missile spawnpoint undefined for player: " + player.name );
		bestSpawnPoint.spawnScore += 2;
	}

	bestSpawn = remoteMissileSpawnPoints[0];
	foreach ( spawnPoint in remoteMissileSpawnPoints )
	{
		foreach ( player in spawnPoint.validPlayers )
		{
			spawnPoint.spawnScore += 1;
			
			if ( bulletTracePassed( player.origin + (0,0,32), spawnPoint.origin, false, player ) )
				spawnPoint.spawnScore += 3;
		
			if ( spawnPoint.spawnScore > bestSpawn.spawnScore )
			{
				bestSpawn = spawnPoint;
			}
			else if ( spawnPoint.spawnScore == bestSpawn.spawnScore ) // equal spawn weights so we toss a coin.
			{			
				if ( coinToss() )
					bestSpawn = spawnPoint;	
			}
		}
	}
	
	return ( bestSpawn );
}

drawLine( start, end, timeSlice, color )
{
	drawTime = int(timeSlice * 20);
	for( time = 0; time < drawTime; time++ )
	{
		line( start, end, color,false, 1 );
		wait ( 0.05 );
	}
}

_fire( lifeId, player, Target )
{		
	self.Target = Target;
	remoteMissileSpawnArray = getEntArray( "remoteMissileSpawn" , "targetname" );
	//assertEX( remoteMissileSpawnArray.size > 0 && getMapCustom( "map" ) != "", "No remote missile spawn points found.  Contact friendly neighborhood designer" );
	
	foreach ( spawn in remoteMissileSpawnArray )
	{
		if ( isDefined( spawn.target ) )
			spawn.targetEnt = getEnt( spawn.target, "targetname" );	
	}
	
	if ( remoteMissileSpawnArray.size > 0 )
		remoteMissileSpawn = player getBestSpawnPoint( remoteMissileSpawnArray );
	else
		remoteMissileSpawn = undefined;
	
	if ( isDefined( remoteMissileSpawn ) )
	{	
		startPos = remoteMissileSpawn.origin;	
		targetPos = remoteMissileSpawn.targetEnt.origin;

		//thread drawLine( startPos, targetPos, 30, (0,1,0) );

		vector = vectorNormalize( startPos - targetPos );		
		startPos = vector_multiply( vector, 14000 ) + targetPos;

		//thread drawLine( startPos, targetPos, 15, (1,0,0) );
		
		rocket = MagicBullet( "remotemissile_projectile_mp", startpos, targetPos, player );

	}
	else
	{
		upVector = (0, 0, level.missileRemoteLaunchVert );
		backDist = level.missileRemoteLaunchHorz;
		targetDist = level.missileRemoteLaunchTargetDist;
	
		forward = AnglesToForward( player.angles );
		startpos = player.origin + upVector + forward * backDist * -1;
		targetPos = player.origin + forward * targetDist;
		
		rocket = MagicBullet( "remotemissile_projectile_mp", startpos, targetPos, player );

	}
	
	level.rocketent = rocket getEntityNumber();
	
	player iprintln( targetPos );
	
	if ( !IsDefined( rocket ) )
	{
		player clearUsingRemote();
		return;
	}
	
	rocket thread maps\mp\gametypes\_weapons::AddMissileToSightTraces( player.team );
	rocket thread handleDamage();
	
	rocket.lifeId = lifeId;
	rocket.type = "remote";

	MissileEyes( player, rocket );
}

handleDamage()
{
	self endon ( "death" );
	self endon ( "deleted" );

	self setCanDamage( true );

	for ( ;; )
	{
	  self waittill( "damage" );
	  println ( "projectile damaged!" );
	}
}	
	
MissileEyes( player, rocket )
{
	player endon ( "joined_team" );
	player endon ( "joined_spectators" );
	player endon ( "disconnected" );
	
	level notify( "rocket_active" );
	
	level.rocketactive = true;
	rocket thread Rocket_CleanupOnDeath();
	player thread Player_CleanupOnGameEnded( rocket );
	player thread Player_CleanupOnTeamChange( rocket );

	player endon ( "disconnect" );

	if ( isDefined( rocket ) )
	{
		
		player VisionSetMissilecamForPlayer( game["thermal_vision"], 0 );
		player ThermalVisionOn();
		player thread RocketSpeed ( rocket );
		player thread delayedFOFOverlay( rocket );
		player CameraLinkTo( rocket, "tag_origin" );
		player ControlsLinkTo( rocket, player );
	
		
		if ( getDvarInt( "camera_thirdPerson" ) )
			player setThirdPersonDOF( false );

		
		rocket waittill( "death" );

		// is defined check required because remote missile doesnt handle lifetime explosion gracefully
		// instantly deletes its self after an explode and death notify
		if ( isDefined(rocket) )
			player maps\mp\_matchdata::logKillstreakEvent( "predator_missile", rocket.origin );
			
		level.rocketactive = false;
		player ControlsUnlink();
		player freezeControlsWrapper( true );
		player ThermalVisionOff();
	
		// If a player gets the final kill with a hellfire, level.gameEnded will already be true at this point
		if ( !level.gameEnded || isDefined( player.finalKill ) )
			player thread staticEffect( 0.5 );

		wait ( 0.5 );
		
		player ThermalVisionFOFOverlayOff();
		
		player CameraUnlink();
		
		if ( getDvarInt( "camera_thirdPerson" ) )
			player setThirdPersonDOF( true );
		
	}
	
	player clearUsingRemote();
}

delayedFOFOverlay( rocket )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	wait ( 0.15 );
	
	self ThermalVisionFOFOverlayOn();
}

RocketSpeed( rocket )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	for(;;)
	{	
	
		height = distance( rocket.origin, level.rocketdisttarg.origin );
		// Slowing down the rocket in relation to the target can be fun.
		if ( height <= 3000 && height >= 500 )
		{
			setDvar("missileRemoteSpeedTargetRange", ( height/2.3 + " 6000" ) );
		}
		
		wait ( 0.1 );	
	}
}

staticEffect( duration )
{
	self endon ( "disconnect" );
	
	staticBG = newClientHudElem( self );
	staticBG.horzAlign = "fullscreen";
	staticBG.vertAlign = "fullscreen";
	staticBG setShader( "white", 640, 480 );
	staticBG.archive = true;
	staticBG.sort = 10;

	static = newClientHudElem( self );
	static.horzAlign = "fullscreen";
	static.vertAlign = "fullscreen";
	static setShader( "ac130_overlay_grain", 640, 480 );
	static.archive = true;
	static.sort = 20;
	
	wait ( duration );
	
	static destroy();
	staticBG destroy();
}


Player_CleanupOnTeamChange( rocket )
{
	rocket endon ( "death" );
	self endon ( "disconnect" );

	self waittill_any( "joined_team" , "joined_spectators" );

	if ( self.team != "spectator" )
	{
		self ThermalVisionFOFOverlayOff();
		self ControlsUnlink();
		self CameraUnlink();	

		if ( getDvarInt( "camera_thirdPerson" ) )
			self setThirdPersonDOF( true );
	}
	self clearUsingRemote();
	
	level.remoteMissileInProgress = undefined;
}


Rocket_CleanupOnDeath()
{
	entityNumber = self getEntityNumber();
	level.rockets[ entityNumber ] = self;
	self waittill( "death" );	
	
	level.rockets[ entityNumber ] = undefined;
}


Player_CleanupOnGameEnded( rocket )
{
	rocket endon ( "death" );
	self endon ( "death" );
	
	level waittill ( "game_ended" );
	
	self ThermalVisionFOFOverlayOff();
	self ControlsUnlink();
	self CameraUnlink();	

	if ( getDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( true );
}
