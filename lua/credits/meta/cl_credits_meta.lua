local PLAYER = FindMetaTable( "Player" )

function PLAYER:GetCredits()
	return self.credits and self.credits.amount or 0
end