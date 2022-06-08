da.commands:Command( "addcredits" )
	:Desc( "Add to a player's credits" )
	:Category( "Misc" )
	:Weight( da.cfg.SuperAdminWeight )
	:CheckWeight( true )
	:Args( { DA_STRING, "Name/SteamID", true }, { DA_NUMBER, "Amount", true } )
	:Callback( function( cmd, pl, args, suppress )
		local plID = pl:SteamID()
		
		local targ = da.FindPlayer( args[ 1 ] )

		if ( IsValid( targ ) ) then
			local targID = targ:SteamID()

			if ( targ.credits ) then
				targ:SetCredits( targ:GetCredits() + args[ 2 ], function()
					if ( IsValid( pl ) ) then
						pl:Message( "You gave # # credits." )
							:Insert( IsValid( targ ) and targ or targID )
							:Insert( tostring( args[ 2 ] ):Comma() )
							:Send()
					end

					if ( IsValid( targ ) and not suppress ) then
						targ:Message( "# gave you # credits." )
							:Insert( IsValid( pl ) and pl or plID )
							:Insert( tostring( args[ 2 ] ):Comma() )
							:Send()
					end
				end )
			else
				// in case their data hasn't loaded for whatever reason; initialize and update client
				local id64 = targ:SteamID64()

				credits.getData( id64, function( creditAmount, transactions )
					if ( creditAmount ) then
						credits.setCredits( id64, creditAmount + args[ 2 ], function()
							if ( IsValid( targ ) and targ.credits ) then
								targ.credits.amount = int
								credits.net.sendCredits( targ )
							end
						end, pl and pl:SteamID64() )
					else
						da.sendcmderr(pl, cmd, "Something went wrong! Contact a developer.")
					end
				end )
			end
		else
			local id64 = util.SteamIDTo64( args[ 1 ] )

			if ( id64 != "0" ) then
				credits.getData( id64, function( creditAmount, transactions )
					if ( creditAmount ) then
						local sum = creditAmount + args[ 2 ]

						credits.setCredits( id64, sum, function()
							if ( IsValid( pl ) ) then
								pl:Message( "You set #'s credits to #." )
									:Insert( args[ 1 ] )
									:Insert( tostring( args[ 2 ] ):Comma() )
									:Send()
							end
						end, pl and pl:SteamID64() )
					else
						da.sendcmderr(pl, cmd, "Something went wrong! Contact a developer.")
					end
				end )
			else
				da.sendcmderr(pl, cmd, "Invalid target \"" .. args[ 1 ] .. "\".")
			end
		end
	end )