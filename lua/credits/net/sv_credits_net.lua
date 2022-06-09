net.addStrings(
	"credits.clientReady",
	"credits.sendCredits",
	"credits.sendPackages",
	"credits.sendTransactions",
	"credits.sendTransaction",
	"credits.updateTransaction",
	"credits.playerTransaction",
	"credits.sendPackages",
	"credits.requestData",
	"credits.requestCredits",
	"credits.newPackage",
	"credits.updatePackage",
	"credits.oneTimeNotification"
)

--[[
	Name: sendCredits
	Desc: to let the client know how many credits they have.
	Params: <entity> Player
	Returns: nil
]]--

function credits.net.sendCredits( pl )
	pl:GetCredits( function( amount, error )
		if ( IsValid( pl ) and !error ) then
			net.Start( "credits.sendCredits" )
				net.WriteInt( amount, 32 )
			net.Send( pl )
		end
	end )
end

--[[
	Name: sendPackages
	Desc: to give the client package data.
	Params: <entity> Player
	Returns: nil
]]--

function credits.net.sendPackages( pl )
	net.streamTable( "credits.sendPackages", credits.packages, pl )
end

--[[
	Name: newPackage
	Desc: to send players a newly made package, so that they have an updated list.
	Params: <table> Package
	Returns: nil
]]--

function credits.net.newPackage( package )
	net.Start( "credits.newPackage" )
		net.WriteTable( package )
	net.Broadcast()
end

--[[
	Name: updatePackage
	Desc: to send players updates on packages so they they have an updated list.
	Params: <table> Package, <string> Key ( to access the provided package )
	Returns: nil
]]--

function credits.net.updatePackage( package, key )
	net.Start( "credits.updatePackage" )
		net.WriteString( package.uniqueid )
		net.WriteString( key )
		net.WriteType( package[ key ] )
	net.Broadcast()
end

--[[
	Name: sendTransactions
	Desc: to give the client transaction data.
	Params: <entity> Player
	Returns: nil
]]--

function credits.net.sendTransactions( pl )
	net.streamTable( "credits.sendTransactions", pl:GetCreditTransactions(), pl )
end

--[[
	Name: sendTransaction
	Desc: to send a player data on their transaction.
	Params: <entity> Player, <table> Transaction
	Returns: nil
]]--

function credits.net.sendTransaction( pl, transaction )
	net.Start( "credits.sendTransaction" )
		net.WriteTable( transaction )
	net.Send( pl )
end

--[[
	Name: updateTransaction
	Desc: to update a transaction's data.
	Params: <entity> Player, <table> Package
	Returns: nil

	Currently Unused
]]--

function credits.net.updateTransaction( pl, transaction, key )
	net.Start( "credits.updateTransaction" )
		net.WriteUInt( transaction.id, 32 )
		net.WriteString( key )
		net.WriteType( transaction[key] )
	net.Send( pl )
end

--[[
	Name: oneTimeNotification
	Desc: to let a player know that their transaction had a one time use and that it was used.
	Params: <entity> Player, <int> Transaction ID
	Returns: nil
]]--

function credits.net.oneTimeNotification( pl, transactionid )
	net.Start( "credits.playerTransaction" )
		net.WriteUInt( transactionid, 12 )
	net.Send( pl )
end

net.Receive( "credits.clientReady", function( len, pl )
	if ( not pl.credits ) then
		credits.initializePlayer( pl )
	end
end )

net.Receive( "credits.requestData", function( len, pl )
	if ( not pl.creditDataSent ) then
		pl.creditDataSent = true

		credits.net.sendPackages( pl )
		credits.net.sendTransactions( pl )
	end
end )

net.CooledReceiver( "credits.requestCredits", 1, function( len, pl )
	credits.net.sendCredits(pl)
end )

net.CooledReceiver( "credits.playerTransaction", 2, function( len, pl )
	local packageid = net.ReadString()

	if ( packageid ) then
		local package = credits.getPackage( packageid )

		credits.transact( pl, packageid, true, function( status )
			if ( status == 404 ) then
				da.sendmsg( pl, "You need an account on our website to make any transactions." )
			elseif ( status == "cant_afford" ) then
				-- Send them a lil message because they couldn't have gotten here without running clientside-lua
				da.sendmsg( pl, "You can't afford this package, how'd you get here?" )
			else
				pl:Message( "Hey, thanks for buying #!" )
					:Insert( DA_COLOR, package.name )
					:Send()
			end
		end )
	end
end )