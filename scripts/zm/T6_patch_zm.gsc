#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_perks;

main()
{
	replaceFunc( common_scripts\utility::waittill_multiple, ::waittill_multiple_override );
}

init()
{
	level thread on_player_connect();
}

on_player_connect()
{
	while ( true )
	{
		level waittill( "connected", player );
		player thread give_all_perks();
	}
}

give_all_perks()
{
	self waittill( "spawned_player" );
	wait 3;
	self EnableInvulnerability();
	self.maxhealth = 1000000;
	self.health = 1000000;
	valid_perk_list = perk_list_zm();
	foreach ( perk in valid_perk_list )
	{
		self give_perk_zm( perk );
	}
	if ( !isDefined( level.zombies_disabled ) )
	{
		flag_clear( "spawn_zombies" );
		disablezombies( 1 );
		level.zombies_disabled = true;
	}
}

give_perk_zm( perkname )
{
	if ( !self hasPerk( perkname ) )
	{
		self give_perk( perkname, false );
	}
}

perk_list_zm()
{
	gametype = getDvar( "g_gametype" );
	switch ( level.script )
	{
		case "zm_transit":
			return array( "specialty_armorvest", "specialty_rof", "specialty_quickrevive", "specialty_fastreload", "specialty_longersprint", "specialty_scavenger" );
		case "zm_nuked":
			return array( "specialty_armorvest", "specialty_rof", "specialty_quickrevive", "specialty_fastreload" );
		case "zm_highrise":
			return array( "specialty_armorvest", "specialty_rof", "specialty_quickrevive", "specialty_fastreload", "specialty_additionalprimaryweapon", "specialty_finalstand" );
		case "zm_prison":
			if ( gametype == "zgrief" )
			{
				return array( "specialty_armorvest", "specialty_rof", "specialty_fastreload", "specialty_deadshot", "specialty_grenadepulldeath" );
			}
			else 
			{
				return array( "specialty_armorvest", "specialty_rof", "specialty_fastreload", "specialty_deadshot", "specialty_additionalprimaryweapon", "specialty_flakjacket" );
			}
		case "zm_buried":
			if ( gametype == "zgrief" )
			{
				return array( "specialty_armorvest", "specialty_rof", "specialty_quickrevive", "specialty_fastreload", "specialty_longersprint", "specialty_additionalprimaryweapon" );
			}
			else 
			{
				return array( "specialty_armorvest", "specialty_rof", "specialty_quickrevive", "specialty_fastreload", "specialty_longersprint", "specialty_additionalprimaryweapon", "specialty_nomotionsensor" );
			}
		case "zm_tomb":
			return level._random_perk_machine_perk_list;
	}
}

waittill_multiple_override( string1, string2, string3, string4, string5 )
{
	// Save some variables in ZM by not using endon( "death" ) for players
	// Players in ZM do not ever notify "death" so the endon is wasting variables
	if ( sessionModeIsZombiesGame() )
	{
		if ( isPlayer( self ) )
		{
			self endon( "disconnect" );
		}
		else 
		{
			self endon( "death" );
		}
	}
	else 
	{
		if ( isPlayer( self ) )
		{
			self endon( "disconnect" );
		}
		self endon( "death" );
	}
	ent = spawnstruct();
	ent.threads = 0;

	createnotifygroup( self, ent, "returned", string1, string2, string3, string4, string5 );

	while ( ent.threads )
	{
		ent waittill( "returned" );
		ent.threads--;
	}

	ent notify( "die" );
}

waittill_multiple_ents_override( ent1, string1, ent2, string2, ent3, string3, ent4, string4 )
{
	if ( !sessionModeIsZombiesGame() )
	{
		self endon( "death" );
	}
	if ( isPlayer( self ) )
	{
		self endon( "disconnect" );
	}
	ent = spawnstruct();
	ent.threads = 0;

	if ( isdefined( ent1 ) )
	{
		createnotifygroup( ent1, ent, "returned", string1 );
	}

	if ( isdefined( ent2 ) )
	{
		createnotifygroup( ent2, ent, "returned", string2 );
	}

	if ( isdefined( ent3 ) )
	{
		createnotifygroup( ent3, ent, "returned", string3 );
	}

	if ( isdefined( ent4 ) )
	{
		createnotifygroup( ent4, ent, "returned", string4 );
	}

	while ( ent.threads )
	{
		ent waittill( "returned" );

		ent.threads--;
	}

	ent notify( "die" );
}

waittill_any_return_override( string1, string2, string3, string4, string5, string6, string7 )
{
	ent = spawnstruct();
	createnotifygroup( self, ent, "returned", string1, string2, string3, string4, string5, string6, string7 );
	ent waittill( "returned", msg );
	ent notify( "die" );
	return msg;
}

waittill_any_timeout_override( n_timeout, string1, string2, string3, string4, string5 )
{
	if ( ( !isdefined( string1 ) || string1 != "death" ) && ( !isdefined( string2 ) || string2 != "death" ) && ( !isdefined( string3 ) || string3 != "death" ) && ( !isdefined( string4 ) || string4 != "death" ) && ( !isdefined( string5 ) || string5 != "death" ) )
		self endon( "death" );

	ent = spawnstruct();

	if ( isdefined( string1 ) )
		self thread waittill_string( string1, ent );

	if ( isdefined( string2 ) )
		self thread waittill_string( string2, ent );

	if ( isdefined( string3 ) )
		self thread waittill_string( string3, ent );

	if ( isdefined( string4 ) )
		self thread waittill_string( string4, ent );

	if ( isdefined( string5 ) )
		self thread waittill_string( string5, ent );

	ent thread _timeout( n_timeout );

	ent waittill( "returned", msg );

	ent notify( "die" );
	return msg;
}

dump_allocations_periodicly()
{
	wait 5;
	while ( true )
	{
		dumpAllocations( va( "minidumps/child-var-allocations-%s-%s.txt", getDvar( "net_port" ), getTimeStamp() ), 1 );
		stats = getusagestats();

		print( "Child var usage: " + stats.childvars + "/" + stats.maxchildvars );
		wait 60;
	}
}

init()
{
	level thread dump_allocations_periodicly();
}