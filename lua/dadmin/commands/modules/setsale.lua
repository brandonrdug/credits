da.commands:Command( "setsale" )
	:Desc( "Sets a sale for the credit store." )
	:Category( "Misc" )
	:Weight( da.cfg.SuperAdminWeight )
	:Args( { DA_NUMBER, "Percentage", true } )
	:Callback( function( cmd, pl, args, suppress )
		local percentage = math.Clamp( args[ 1 ], 0, 100 ) / 100

		credits.setSale( percentage )

		if ( percentage > 0 ) then
			da.amsg( "# started a sale for #% off!" )
				:Insert( pl )
				:Insert( percentage * 100 )
				:Send()
		else
			da.amsg( "# ended the current sale." )
				:Insert( pl )
				:Send()
		end
	end )