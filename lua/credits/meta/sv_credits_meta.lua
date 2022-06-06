local PLAYER = FindMetaTable( "Player" )

function PLAYER:SetCredits( int, callback )
	credits.setCredits( self:SteamID64(), int, function()
		if ( IsValid( self ) ) then
			self.credits.amount = int
			credits.net.sendCredits( self )

			if ( callback ) then
				callback()
			end
		else
			callback( "disconnected" )
		end
	end )
end