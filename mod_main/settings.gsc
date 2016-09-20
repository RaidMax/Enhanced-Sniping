LoadGameSettings()
{
	LocalGameSettings = [];

	LocalGameSettings["EnableWarmUpRound"] 	 			= false;
	LocalGameSettings["EnableRoundStartTimer"]  	= true;
	LocalGameSettings["EnableAimRestriction"]			= true;
	LocalGameSettings["EnableOSD"]   							= true;
	LocalGameSettings["EnableFrameRateIncrease"]	= true;
	LocalGameSettings["EnableFallDamage"]					= false;
	LocalGameSettings["GameplayStyle"]		 				= "SD";
	LocalGameSettings["SpawnAdvertisement"]  			= "Welcome to Enhanced Sniping!" + level.Version;
	LocalGameSettings["ObjectiveHintAllies"]    	= "Eliminate all enemies!";
	LocalGameSettings["ObjectiveHintAxis"]				= "Leave no prisoners!";
	LocalGameSettings["PlayerMaxHealth"]					= 20; // I guess we want 1 shot for snipers...
	LocalGameSettings["GameSpeed"]								= 190;

	LocalGameSettings["DEV"]											= true;

	// Loadout Settings
	LocalGameSettings["PrimaryWeapon"] 				= "cheytac_fmj_xmags_mp";
	LocalGameSettings["SecondaryWeapon"]			= "beretta_tactical_mp";

	// Gamestyle Settings

	if ( LocalGameSettings["GameplayStyle"] == "SD" )
	{
		LocalGameSettings["TimePerRound"]							= 3;
		LocalGameSettings["WinLimit"]									= 10;
		LocalGameSettings["RoundStartTimerLength"]  	= 5;
		LocalGameSettings["WarmUpRoundTimerLength"]  	= 60;
	}

	// Killstreak Settings ( should we provide custom? )

	LocalGameSettings["KillStreak"][0] 			= "uav";
	LocalGameSettings["KillStreak"][1]			= "predator_missile";
	LocalGameSettings["KillStreak"][2]			= "nuke";

	return LocalGameSettings;
}
