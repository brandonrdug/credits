da.commands:Command( "forcetransact" )
	:Desc( "Force a transaction on a player." )
	:Category( "Misc" )
	:Weight( da.cfg.SuperAdminWeight )
	:CheckWeight( true )
	:Args( { DA_PLAYER, "Target", true }, { DA_STRING, "Package", true }, { DA_NUMBER, "Charge", false } )
	:Callback( function( cmd, pl, args, suppress )
		local plID = pl:SteamID()
		local targID = args[ 1 ]:SteamID()

		local packageName = args[ 2 ]:lower()

		local package = credits.getPackage( packageName )

		if ( not package ) then
			da.sendmsg( pl, "Package doesn't exist." )
			return
		end

		if ( package.disabled == 1 ) then
			da.sendmsg( pl, "Package is disabled." )
			return
		end

		credits.transact( args[ 1 ], packageName, args[ 3 ] or false, function()
			if ( IsValid( pl ) ) then
				pl:Message( "You ran a transaction on # for #." )
					:Insert( IsValid( args[ 1 ] ) and args[ 1 ] or targID )
					:Insert( package.name )
					:Send()
			end
			
			if ( IsValid( args[ 1 ] ) and not suppress ) then
				args[ 1 ]:Message( "# ran a transaction on you for #." )
					:Insert( IsValid( pl ) and pl or plID )
					:Insert( package.name )
					:Send()
			end
		end )
	end )