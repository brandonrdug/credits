local PLAYER = FindMetaTable( "Player" )

function PLAYER:GetCredits( callback )
	credits.getCredits( self:SteamID64(), callback )
end

function PLAYER:SetCredits( int, callback )
	credits.setCredits( self:SteamID64(), int, function( error )
		if ( error ) then
			if ( callback ) then
				callback( error )
			end
			
			return
		end

		if ( IsValid( self ) ) then
			credits.net.sendCredits( self )

			if ( callback ) then
				callback()
			end
		else
			callback( "disconnected" )
		end
	end )
end