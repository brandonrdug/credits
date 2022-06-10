da.commands:Command( "getcredits" )
	:Desc( "Show you a player's credits" )
	:Category( "Misc" )
	:Weight( da.cfg.SuperAdminWeight )
	:Args( { DA_STRING, "Target", true } )
	:Callback( function( cmd, pl, args, suppress )
		local targ = da.FindPlayer( args[ 1 ] )

		if ( IsValid( targ ) ) then
			targ:GetCredits( function( amount, error )
				if ( error ) then
					if ( IsValid( pl ) ) then
						pl:Message( "# hasn't signed in  on our website, so they don't have any credits." )
							:Insert( IsValid( targ ) and targ or targID )
							:Send()
					end
					
					return
				end

				pl:Message( "# has # credits." )
					:Insert( targ )
					:Insert( tostring( amount ):Comma() )
					:Send()
			end )
		else
			local id64 = util.SteamIDTo64( args[ 1 ] )

			if ( id64 != "0" ) then
				credits.getData( id64, function( creditAmount, transactions, error )
					if ( creditAmount ) then
						if ( IsValid( pl ) ) then
							pl:Message( "# has # credits." )
								:Insert( args[ 1 ] )
								:Insert( tostring( creditAmount ):Comma() )
								:Send()
						end
					elseif ( error == 404 ) then
						da.sendcmderr( pl, cmd, "User hasn't signed in on our website, so they don't have any credits." )
					else
						da.sendcmderr( pl, cmd, "Something went wrong! Contact a developer." )
					end
				end )
			else
				da.sendcmderr(pl, cmd, "Invalid target \"" .. args[ 1 ] .. "\".")
			end
		end
	end )