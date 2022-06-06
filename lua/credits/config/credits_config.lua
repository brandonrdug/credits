credits.config--.set( "Debug Mode", false )
	.set( "donateURL", "" )
	.set( "categories", {
		[ "Ranks" ] = 1,
		[ "Moola" ] = 2,
		[ "Weapons" ] = 3,
		[ "Permanent Weapons" ] = 4,
		[ "Upgraded Weapons" ] = 5,
		[ "Ammo" ] = 6,
		[ "Permanent Ammo" ] = 7,
		[ "Miscellaneous" ] = 8
	} )
	.set( "packageTypes", {
		[ "group" ] = {
			[ "inputs" ] = {
				"groupid"
			},
			[ "action" ] = function( pl, transaction )
				da.groups.SetPlayerGroup( pl, transaction.vars.groupid, transaction.vars.duration, transaction.duration and pl:GetUserGroup(), "user" )
			end
		},

		[ "secgroup" ] = {
			[ "inputs" ] = {
				"groupid"
			},
			[ "action" ] = function( pl, transaction )
				da.groups.SetPlayerSecondaryGroup( pl, transaction.vars.groupid, transaction.vars.duration, transaction.duration and pl:GetUserGroup(), "user" )
			end
		},

		[ "money" ] = {
			[ "inputs" ] = {
				"amount"
			},
			[ "action" ] = function( pl, transaction )
				pl:addMoney( transaction.vars.money )
			end
		},

		[ "weapon" ] = {
			[ "inputs" ] = {
				"weapon"
			},
			[ "playerInit" ] = function( pl )
				pl.credits.weapons = {}
			end,
			[ "action" ] = function( pl, transaction )
				if ( not transaction.vars.runOnce ) then
					table.insert( pl.credits.weapons, transaction )
				end

				pl:Give( transaction.vars.weapon )
			end
		},

		[ "upgradedWeapon" ] = {
			[ "inputs" ] = {
				"weapon",
				"cosmeticName",
				"damageIncreasePercentage",
				"bulletTracer",
				"material"
			},
			[ "playerInit" ] = function( pl )
				pl.credits.upgradedWeapons = {}
			end,
			[ "action" ] = function( pl, transaction )
				if ( transaction.vars.runOnce ) then
					transaction.vars.used = false
				end

				pl.credits.upgradedWeapons[ transaction.vars.weapon ] = transaction

				local weapon = pl:GetWeapon( transaction.vars.weapon )

				if ( weapon ) then
					credits.upgradeWeapon( weapon, transaction )
				end
			end
		},

		[ "ammo" ] = {
			[ "inputs" ] = {
				"ammoAmount",
				"ammoType"
			},
			[ "playerInit" ] = function( pl )
				pl.credits.ammo = {}
			end,
			[ "action" ] = function( pl, transaction )
				if ( not transaction.vars.runOnce ) then
					table.insert( pl.credits.ammo, transaction )
				end

				pl:GiveAmmo( transaction.vars.ammoAmount, transaction.vars.ammoType )
			end
		},

		[ "props" ] = {
			[ "inputs" ] = {
				"amount"
			},
			[ "playerInit" ] = function( pl )
				pl.credits.propCount = 0
			end,
			[ "action" ] = function( pl, transaction )
				pl.credits.propCount = pl.credits.propCount + transaction.vars.amount
				credits.net.updatePropCount( pl )
			end
		},

		[ "command" ] = {
			[ "inputs" ] = {
				"command"
			},
			[ "action" ] = function( pl, package )
				RunConsoleCommand( unpack( string.Explode( " ", package.vars.command:Replace( "{SteamID}", pl:SteamID() ):Replace( "{SteamID64}", pl:SteamID64() ):Replace( "{Name}", pl:Name() ) ) ) )
			end
		},
	} )

hook( "creditPackagesLoaded", "credits", function()
	credits.newPackage( "cash_event", { 
		name = "Printer Event",
		category = "Moola",
		description = "All printers give x2 money for 1 hour",
		credits = 1500,
		type = "command",
		image = "/url.png",
		vars = {
			command = "events_printer 60",
			runOnce = true
		}
	} )
	
	credits.newPackage( "cash_10k", { 
		name = "$10,000 Cash",
		category = "Moola",
		description = "Instantly gives you $10,000.",
		credits = 150,
		type = "money",
		image = "/url.png",
		vars = {
			money = 10000,
			runOnce = true
		}
	} )

	credits.newPackage( "group_vip", { 
		name = "VIP",
		category = "Ranks",
		image = {
			src = "",
			width = "100%",
			height = "100%"
		},
		description = "Gives you VIP",
		credits = 1000,
		buyOnce = true,
		type = "group",
		vars = {
			groupid = "vip",
			money = 50000,
			runOnce = true,
		}
	} )

	credits.newPackage( "permwep_hook", { 
		name = "Permanent Grappling Hook",
		category = "Permanent Weapons",
		description = "Permanently receive a Grappling Hook every time you spawn.",
		credits = 1000,
		buyOnce = true,
		type = "weapon",
		vars = {
			weapon = "realistic_hook",
		}
	} )
	
	credits.newPackage( "permwep_machete", { 
		name = "Permanent Machete",
		category = "Permanent Weapons",
		description = "Permanently receive a Machete every time you spawn.",
		credits = 700,
		buyOnce = true,
		type = "weapon",
		vars = {
			weapon = "m9k_machete",
		}
	} )

	credits.newPackage( "permwep_crowbar", { 
		name = "Permanent Crowbar",
		category = "Permanent Weapons",
		description = "Permanently receive a Crowbar every time you spawn.",
		credits = 750,
		buyOnce = true,
		type = "weapon",
		vars = {
			weapon = "weapon_crowbar",
		}
	} )
	credits.newPackage( "permammo_rifle", { 
		name = "Permanent Rifle Ammo",
		category = "Permanent Ammo",
		description = "Permanently receive +120 rifle rounds when you spawn.",
		credits = 500,
		buyOnce = true,
		type = "ammo",
		vars = {
			ammoAmount = 120,
			ammoType = "ar2",
		}
	} )

	credits.newPackage( "propcount_50", { 
		name = "Permanent +50 Prop Limit",
		category = "Miscellaneous",
		description = "Increases your prop limit by 50 permanently.",
		credits = 3000,
		type = "props",
		buyOnce = true,
		vars = {
			amount = 50,
			model = "models/props_interiors/Furniture_chair03a.mdl"
		}
	} )
end )
