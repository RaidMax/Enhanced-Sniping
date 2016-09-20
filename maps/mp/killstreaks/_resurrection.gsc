#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

seeIfKillstreakOwed()
{
	if (self.pers["cur_kill_streak"] == 4 && !self.pers["resurrection_earned"])
	{
		notifyData = spawnStruct();
		notifyData.titleText = "4 Kill Streak!";
		notifyData.notifyText = "Press [{+actionslot 3}] for Resurrection Stone.";
		notifyData.sound = "mp_challenge_complete";
		notifyData.iconName = "cardicon_sniper";

		self thread maps\mp\gametypes\_hud_message::notifyMessage(notifyData);
		
		notifyData = undefined;
				
		self.pers["resurrection_earned"] = true;
		self thread killstreak_give("resurrection_stone");
	}
}

player_waitkillstreak()
{
	self endon("disconnect");
	self endon("death");
	self endon("killstreak_finished");
	
	self notifyOnPlayerCommand("killstreak", "+actionslot 3");
	
	while ( isAlive(self) )
	{
		self waittill("killstreak");
		if(level.aliveCount[self.team] == level.teamCount[self.team])
			self iprintlnbold("Your whole team is still alive!");
		else
			break;
		wait (1);
	}
		
	self notify("killstreak_press");
}

killstreak_give(killstreak)
{
	self endon("disconnect");
	self endon("death");
	self endon("killstreak_finished");
	
	if (!self.pers["resurrection_given"])
		self iprintlnbold("You earned a resurrection! Press ^1[{+actionslot 3}] ^7to activate");
	
	self thread player_waitkillstreak();
	
	self waittill ("killstreak_press");
	
	wait (0.2);
	self freezeControlsWrapper( true );
	
	self.spacer = createIcon( "black", 200, 70 );
	self.spacer setPoint( "CENTER", "CENTER", 0, 0 );
	self.spacer.alpha = 0.5;
	self.spacer.hidewheninmenu = 1;
	
	self.targetselector = createFontString( "hudbig", 0.8 );
	self.targetselector setPoint( "CENTER", "CENTER", 0, 0 );
	self.targetselector setText( "NONE" );
	self.targetselector.hidewheninmenu = 1;
	
	self.targetselectorTitle = createFontString( "hudbig", .5 );
	self.targetselectorTitle setPoint( "CENTER", "CENTER", 0, -25 );
	self.targetselectorTitle setText( "Pick A Player to Revive" );
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
	
	self thread destroy_overlay();
	playerWaitSelection();
}

playerWaitSelection()
{
	self endon("disconnect");
	self endon("death");
	self endon("killstreak_finished");
	
	self notifyOnPlayerCommand( "left", "+attack" );
	self notifyOnPlayerCommand( "right", "+toggleads_throw" );
	self notifyOnPlayerCommand( "right_alt", "+speed_throw" );
	
	if (!isDefined(self.currentpicked))
		self.currentpicked = self;
		
	self.count = 0;
	
	while(true)
	{
		response = waittill_any_return("left", "right", "right_alt");
		
		if (response == "left" && self.currentpicked != self)
		{
			self.pers["resurrection_given"] = true;
			player_revive(self.currentpicked);
		}
			
		else
			player_cycle();			
	}
}

destroy_overlay()
{
	self endon("destroy_finished");
	self waittill_any("killstreak_finished", "death", "disconnect", "round_win", "game_over");
	
	self.spacer destroyElem();
	self.targetselector destroyElem();
	self.targetselectorTitle destroyElem();
	self.targetTitle destroyElem();
	self.selectIcon destroyElem();
	
	wait (0.3);
	
	self freezeControlsWrapper( false );
	
	self notify("destroy_finished");
}

player_cycle()
{
	self endon("killstreak_finished");
	self endon("death");
	self endon("disconnect");
	
	while (true)
	{
		selected = level.players[self.count % level.players.size];
		
		if (!isAlive(selected) && selected.team == self.team && selected != self)
		{
			self.currentpicked = selected;
			self.targetselector setText(selected.name);		
			self.count++;
			break;
		}
		
		self.count++;
	}
}

player_revive(selection)
{
	if (!isAlive(selection))
	{
		iprintlnbold( "^1" + self.name + " ^7is reviving ^5" + selection.name );
		selection PlayLocalSound( "javelin_clu_lock" );
		selection.isRevive = true;
		wait ( 1 );
		selection PlayLocalSound( "ui_camera_whoosh_in" );
		selection VisionSetNakedForPlayer( "coup_sunblind", 0 );	
		selection maps\mp\gametypes\_playerlogic::spawnPlayer();
		selection VisionSetNakedForPlayer( getDvar("mapname"), 2.3 );
		selection.isRevive = false;
		self.pers["resurrection_earned"] = false;
		self.pers["resurrection_given"] = false;
		self notify("killstreak_finished");
	}
	
	else
		self iprintlnbold(selection.name + " is already alive!");
}	