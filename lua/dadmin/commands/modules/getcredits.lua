da.commands:Command( "getcredits" )
	:Desc( "Show you a player's credits" )
	:Category( "Misc" )
	:Weight( da.cfg.SuperAdminWeight )
	:Args( { DA_STRING, "Target", true } )
	:Callback( function( cmd, pl, args, suppress )
		local targ = da.FindPlayer( args[ 1 ] )

		if ( IsValid( targ ) ) then
			pl:Message( "# has # credits." )
				:Insert( targ )
				:Insert( tostring( targ:GetCredits() ):Comma() )
				:Send()
		else
			local id64 = util.SteamIDTo64( args[ 1 ] )

			if ( id64 != "0" ) then
				credits.getData( id64, function( creditAmount, transactions )
					if ( creditAmount ) then
						if ( IsValid( pl ) ) then
							pl:Message( "# has # credits." )
								:Insert( args[ 1 ] )
								:Insert( tostring( creditAmount ):Comma() )
								:Send()
						end
					else
						da.sendcmderr(pl, cmd, "Something went wrong! Contact a developer.")
					end
				end )
			else
				da.sendcmderr(pl, cmd, "Invalid target \"" .. args[ 1 ] .. "\".")
			end
		end
	end )