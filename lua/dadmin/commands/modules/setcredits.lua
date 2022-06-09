da.commands:Command( "setcredits" )
	:Desc( "Set a player's credits" )
	:Category( "Misc" )
	:Weight( da.cfg.SuperAdminWeight )
	:CheckWeight( true )
	:Args( { DA_STRING, "Name/SteamID", true }, { DA_NUMBER, "Amount", true } )
	:Callback( function( cmd, pl, args, suppress )
		local plID = pl:SteamID()

		local targ = da.FindPlayer( args[ 1 ] )
		local targID

		if ( IsValid( targ ) ) then
			targID = targ:SteamID()

			targ:SetCredits( args[ 2 ], function( error )
				if ( error ) then
					if ( IsValid( pl ) ) then
						pl:Message( "# does not have an account on our website. Have them make one and then try again." )
							:Insert( IsValid( targ ) and targ or targID )
							:Send()
					end
					
					return
				end

				if ( IsValid( pl ) ) then
					pl:Message( "You set #'s credits to #." )
						:Insert( IsValid( targ ) and targ or targID )
						:Insert( tostring( args[ 2 ] ):Comma() )
						:Send()
				end
				
				if ( IsValid( targ ) and not suppress ) then
					targ:Message( "# set your credits to #." )
						:Insert( IsValid( pl ) and pl or plID )
						:Insert( tostring( args[ 2 ] ):Comma() )
						:Send()
				end
			end )
		else
			local id64 = util.SteamIDTo64( args[ 1 ] )

			if ( id64 != "0" ) then
				credits.getData( id64, function( creditAmount, transactions, error )
					if ( creditAmount ) then
						credits.setCredits( id64, args[ 2 ], function()
							if ( IsValid( pl ) ) then
								pl:Message( "You set #'s credits to #." )
									:Insert( args[ 1 ] )
									:Insert( tostring( args[ 2 ] ):Comma() )
									:Send()
							end
						end )
					else if ( error == 404 ) then
						da.sendcmderr( pl, cmd, "User doesn't have an account on the website. Have them make one and try again." )
					else
						da.sendcmderr( pl, cmd, "Something went wrong! Contact a developer." )
					end
				end )
			else
				da.sendcmderr( pl, cmd, "Invalid target \"" .. args[ 1 ] .. "\"." )
			end
		end
	end )