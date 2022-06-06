credits.queue = {}

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getData( steamID64, callback )
	credits.db.query( credits.db.queries.getData:format( steamID64 ), function( query, data )
		local data = query:getNextResults()

		if ( not data[ 1 ] ) then
			credits.db.query( credits.db.queries.insertUser:format( steamID64, 0 ), function( query )
				callback( 0, {} )
			end )
		else
			local credits = data[ 1 ].credits
			query:getNextResults()
			
			if ( callback ) then
				callback( credits, query:getData() )
			end
		end
	end )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.setCredits( steamID64, int, callback )
	credits.db.query( credits.db.queries.setCredits:format( int, steamID64 ), function()
		if ( callback ) then
			callback()
		end
	end )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getCredits( steamID64, callback )
	credits.db.query( credits.db.queries.getCredits:format( steamID64 ), function( query, data )
		callback( data[ 1 ].credits )
	end )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.newPackage( uniqueid, info, callback )
	assert( credits.packages, "Packages aren't initialized yet; can't create new one." )

	uniqueid = uniqueid:lower()

	if ( credits.getPackage( uniqueid ) ) then
		return
	end

	local duration = ( info.duration == 0 ) and nil or info.duration

	local JSON = credits.db.conn:escape( util.TableToJSON( info.vars or {} ) )
	local description = info.description and credits.db.conn:escape( info.description ) or ""
	local upgradeFrom = info.upgradeFrom and credits.db.conn:escape( util.TableToJSON( info.upgradeFrom ) )
	local image = info.image and ( istable( info.image ) and credits.db.conn:escape( util.TableToJSON( info.image ) ) or info.image )
		image = image and "'" .. image .. "'"

	credits.db.query( credits.db.queries.insertPackage:format( uniqueid, info.name, info.category, description, info.credits, info.type, upgradeFrom or "null", info.buyOnce or "null", info.order or "null", image or "null", JSON, info.duration or "null" ) .. credits.db.queries.getMaxID, function( query )

		local id = query:getNextResults()[ 1 ][ "id" ]

		credits.packages[ id ] = {
			[ "id" ]			= id,
			[ "uniqueid" ] 		= uniqueid,
			[ "name" ] 			= info.name,
			[ "category" ] 		= info.category,
			[ "description" ]	= info.description or "",
			[ "credits" ] 		= info.credits,
			[ "type" ] 			= info.type,
			[ "upgradeFrom" ]	= info.upgradeFrom,
			[ "buyOnce" ]		= info.buyOnce and 1 or 0,
			[ "order" ]			= info.order or 0,
			[ "image" ]			= info.image,
			[ "vars" ] 			= info.vars,
			[ "duration" ] 		= info.duration,
			[ "timeScale" ]     = info.timeScale,
			[ "timeFree" ]      = info.timeFree,
			[ "disabled" ]		= 0
		}

		credits.net.newPackage( credits.packages[ id ] )

		if ( callback ) then
			callback( credits.packages[ id ] )
		end
	end )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.setDiscount( packageid, percentage, callback )
	assert( credits.packages, "Packages aren't initialized yet; can't set discount of " .. packageid )

	local package = credits.getPackage( packageid )

	if ( package ) then
		credits.db.query( credits.db.queries.updateDiscount:format( percentage, package.uniqueid ), function()
			package.discount = percentage

			credits.net.updatePackage( package, "discount" )
			callback( package )
		end )
	end
end


-- deprecated
function credits.setGlobalDiscount( percentage )
	assert( credits.packages, "Packages aren't initialized yet; can't set discount" )

	for k, v in ipairs( credits.packages ) do
		v.discount = percentage
		credits.net.updatePackage( v, "discount" )
	end
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.setSale( percentage )
	assert( credits.packages, "Packages aren't initialized yet; can't set discount" )

	if ( percentage <= 0 ) then
		percentage = "NULL"
	end

	for k, v in ipairs( credits.packages ) do
		credits.db.query( credits.db.queries.updateDiscount:format( percentage, '"' .. v.id .. '"' ), function()
			v.discount = ( percentage != "NULL" and percentage ) or nil
			credits.net.updatePackage( v, "discount" )
		end )
	end
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getActiveTransactionsByPackage( steamid64, packageid, callback )
	credits.db.query( credits.db.queries.getActiveTransactionsByPackage:format( steamid64, packageid ), function( query, data )
		if ( callback ) then
			callback( data )
		end
	end )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.transact( pl, packageID, charge, callback )
	assert( pl.credits, pl:NameID() .. " is not initialized." )

	local package = credits.getPackage( packageID )
	assert( package.disabled == 0, "This package is disabled, how'd they get to buying this?" )

	if ( package.buyOnce == 1 ) then
		local transactions = pl:GetCreditTransactions( packageID )

		if ( transactions[ 1 ] ) then
			ErrorNoHalt( pl, " tried buying " .. packageID .. " a second time. How'd we get here?" )			

			return
		end
	end

	local price = 0
	local upgrading, upgradingFrom

	if ( charge ) then
		price, upgrading, upgradingFrom = credits.getPriceWithPlayer( package, pl )
	end

	if ( pl:GetCredits() < price ) then
		if ( callback ) then
			callback( "cant_afford" )
		end

		return
	end

	local duration = package.duration

	if ( duration and package.buyOnce == 1 ) then
		local activeTransactions = pl:GetActiveTransactions( packageID )
		
		if ( activeTransactions[ 1 ] ) then
			-- Link time between last transaction and this one, then disable last one
			duration = duration + ( transaction.expireTime - os.time() )

			credits.db.query( credits.db.queries.disableTransactionByPackage:format( pl:SteamID64(), packageID ) )

			activeTransactions[ 1 ].disabled = 1
			credits.net.updateTransaction( pl, activeTransactions[ 1 ], "disabled" )
		end
	end

	if ( upgrading ) then
		for k, v in ipairs( upgradingFrom ) do
			-- Disable the old transactions if upgrading
			credits.db.query( credits.db.queries.disableTransactionByPackage:format( pl:SteamID64(), package.upgradeFrom ) )

			v.disabled = 1
			credits.net.updateTransaction( pl, v, "disabled" )
		end
	end

	-- Keep the player from spamming transactions since it takes time before their credits are reduced
	pl.credits.amount = pl:GetCredits() - price

	local time = os.time()

	credits.db.query( credits.db.queries.setCredits:format( pl:GetCredits(), pl:SteamID64() ) .. credits.db.queries.insertTransaction:format( duration or "null", pl:SteamID64(), package.uniqueid, -price, package.type, credits.db.conn:escape( util.TableToJSON( package.vars ) ), time ) .. "SELECT MAX( `id` ) AS `id` FROM `transactions`; SELECT `expireTime` AS `expireTime` FROM `transactions` WHERE `id` = ( SELECT MAX( `id` ) FROM `transactions` )", function( query )
		if ( IsValid( pl ) ) then
			-- Skip the results from setting credits and setting a variable in sql
			query:getNextResults()
				query:getNextResults()
			local id = query:getNextResults()[ 1 ][ "id" ]

			pl:GetCreditTransactions()[ id ] = {
				[ "id" ] 			= id,
				[ "steamID64" ] 	= pl:SteamID64(),
				[ "package" ] 		= package.uniqueid,
				[ "credits" ] 		= -price,
				[ "activated" ] 	= 0,
				[ "type" ]			= package.type,
				[ "vars" ]			= package.vars,
				[ "time" ] 			= time,
				[ "expireTime" ]	= query:getNextResults()[ 1 ][ "expireTime" ],
				[ "disabled" ]		= 0
			}

			credits.net.sendCredits( pl )
			credits.net.sendTransaction( pl, pl:GetCreditTransactions()[ id ] )

			hook.Run( "packageBought", pl, package, pl:GetCreditTransactions()[ id ] )

			da.amsg( "lol some nerd just wasted money again! thanks # for buying #!" )
				:Insert( pl )
				:Insert( DA_COLOR, package.name )
				:Send()

			credits.runAction( pl, id )

			if ( callback ) then
				callback()
			end
		else
			if ( callback ) then
				callback( "disconnected" )
			end
		end
	end )
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.runAction( pl, transactionid, callback )
	local transaction = pl:GetCreditTransactions()[ transactionid ]
	local package = credits.getPackage( transaction.package )
	local type = credits.config.get( "packageTypes" )[ transaction.type ]

	if ( transaction.disabled == 0 ) then
		if ( transaction.activated == 0 ) then
			if ( not credits.isExpired( transaction ) ) then
				credits.db.query( "UPDATE `transactions` SET `activated` = 1, `vars` = '" .. credits.db.conn:escape( util.TableToJSON( transaction.vars ) ) .. "' WHERE `steamID64` = '" .. pl:SteamID64() .. "' AND `id` = " .. transaction.id, function( query )
					if ( IsValid( pl ) ) then
						type.action( pl, transaction )

						transaction.activated = 1
						credits.net.updateTransaction( pl, transaction, "activated" )

						if ( transaction.vars.runOnce ) then
							credits.net.oneTimeNotification( pl, transactionid )
						end

						if ( callback ) then
							callback()
						end
					else
						if ( callback ) then
							callback( "disconnected" )
						end
					end
				end )
			else
				if ( callback ) then
					callback( "package_expired" )
				end
			end
		else
			if ( not transaction.vars.runOnce ) then
				if ( not credits.isExpired( transaction ) ) then
					type.action( pl, transaction )
					
					if ( callback ) then
						callback()
					end
				else
					if ( callback ) then
						callback( "package_expired" )
					end
				end
			end
		end
	end
end

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.getTransactions( steamID64, callback )
	credits.db.query( credits.db.queries.getTransactions:format( steamId64 ), function( query, data )
		callback( data )
	end )
end

--[[
	Initializing packages/players
]]--

credits.db.query( "SELECT * FROM `packages`", function( query, packages )
	for k, v in pairs( packages ) do
		v.vars = v.vars and util.JSONToTable( v.vars )
		v.upgradeFrom = v.upgradeFrom and util.JSONToTable( v.upgradeFrom )
		
		-- if v.image == a url instead of a table, JSONToTable will return nil and we can correct for that
		local JtT = v.image and util.JSONToTable( v.image )
			v.image = v.image and ( JtT or v.image )
	end

	credits.packages = packages

	for k, v in ipairs( credits.queue ) do
		if ( IsValid( v ) ) then
			credits.InitializePlayer( v )
		end
	end

	credits.queue = nil

	hook.Run( "creditPackagesLoaded" )
end )

--[[
	Name:
	Desc:
	Params:
	Returns:
]]--

function credits.initializePlayer( pl )
	if ( not credits.packages ) then
		table.insert( credits.queue, pl )
		return
	end

	credits.getData( pl:SteamID64(), function( creditAmount, transactions )		
		if ( IsValid( pl ) ) then
			pl.credits = {
				[ "amount" ]		= creditAmount,
				[ "transactions" ] 	= {}
			}

			for k, v in ipairs( transactions ) do
				pl.credits.transactions[ v.id ] = v
			end

			credits.net.sendCredits( pl )

			-- Flexibility to set up data in player tables in the config
			for k, v in pairs( credits.config.get( "packageTypes" ) ) do
				if ( v.playerInit ) then
					v.playerInit( pl )
				end
			end

			for _, transaction in pairs( pl:GetCreditTransactions() ) do
				transaction.vars = util.JSONToTable( transaction.vars )

				local package = credits.getPackage( transaction.package )

				if ( package ) then
					if ( transaction.disabled == 0 ) then
						credits.runAction( pl, transaction.id )
					end
				else
					ErrorNoHalt( "[credits] " .. pl:NameID() .. " runAction failed because of missing package '" .. transaction.package .. "'." )
				end
			end
		end
	end )
end
