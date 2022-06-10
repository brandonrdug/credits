-- credits.queue = {}
credits.packages = {}


// CURRENTLY ON THIS ~!@@# $@Q#$ WEFDFDF GDFG DFGGDFDFG DFGGDF XCVDFGDFGS DF DFFG 
function credits.getData( steamID64, callback )
	credits.db.query( credits.db.queries.getData:format( steamID64 ), function( query, data )
		data = query:getNextResults()

		if ( !data or !data[ 1 ] ) then
			if ( callback ) then
				callback( nil, nil, 404 )
			end
			
			return
		end

		local credits = data[ 1 ].credits
		query:getNextResults()
		
		if ( callback ) then
			callback( credits, query:getData() )
		end
	end )
end

function credits.getCredits( steamID64, callback )
	credits.db.query( credits.db.queries.getCredits:format( steamID64 ), function( query, data )
		if (data[ 1 ]) then
			callback( data[ 1 ].credits )
		else
			callback( nil, 404 )
		end
	end )
end

// @ alter to be an api call
// done
function credits.setCredits( steamID64, int, callback, adminID64 )
	credits.getCredits( steamID64, function( amount, error )
		if ( error ) then
			return callback( error )
		end

		HTTP( function() end, function( code, body, headers )
			if ( code == 404 ) then
				return callback(code)
			end

			callback()
		end, "PUT", "https://hubtesting.exhibitionrp.com/api/store/addcredits", {}, {
			["Authorization"] = "f=(ZlHj/wIK@^p>j%<;$,Q_H#c]pXw*^ilHnmHAVwy1+ppy_yntse+HRlR[pvz"
		}, util.TableToJSON( { 
			["steamid"] = steamID64,
			["credits"] = int - amount,
			["adminid"] = adminID64
		} ), "application/json" )
	end )
end

// @ cut
// edited
function credits.newPackage( uniqueid, info )
	uniqueid = uniqueid:lower()

	if ( credits.getPackage( uniqueid ) ) then
		return
	end

	-- local duration = ( info.duration == 0 ) and nil or info.duration

	-- local JSON = credits.db.conn:escape( util.TableToJSON( info.vars or {} ) )
	-- local description = info.description and credits.db.conn:escape( info.description ) or ""
	-- local upgradeFrom = info.upgradeFrom and credits.db.conn:escape( util.TableToJSON( info.upgradeFrom ) )
	-- local image = info.image and ( istable( info.image ) and credits.db.conn:escape( util.TableToJSON( info.image ) ) or info.image )
		-- image = image and "'" .. image .. "'"

	-- credits.db.query( credits.db.queries.insertPackage:format( uniqueid, info.name, info.category, description, info.credits, info.type, upgradeFrom or "null", info.buyOnce or "null", info.order or "null", image or "null", JSON, info.duration or "null" ) .. credits.db.queries.getMaxID, function( query )

	-- local id = query:getNextResults()[ 1 ][ "id" ]
	local id = #credits.packages + 1
	
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

		// @ previously callback was an arg
		-- if ( callback ) then
		-- 	callback( credits.packages[ id ] )
		-- end
	-- end )
end

// @ cut

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

// @ adjust

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

// @ adjust for asynchronous checks on credits

function credits.transact( pl, packageID, charge, callback )
	-- assert( pl.credits, pl:NameID() .. " is not initialized." )

	local package = credits.getPackage( packageID )
	assert( package.disabled == 0, "This package is disabled, how'd they get to buying this?" )

	pl:GetCredits( function( amount, error )
		if ( error ) then
			return callback and callback( error )
		end

		if ( package.buyOnce == 1 ) then
			local transactions = pl:GetCreditTransactions( packageID )

			if ( transactions[ 1 ] ) then
				return ErrorNoHalt( pl, " tried buying " .. packageID .. " a second time. How'd we get here?" )
			end
		end

		local price = 0
		local upgrading, upgradingFrom

		if ( charge ) then
			price, upgrading, upgradingFrom = credits.getPriceWithPlayer( package, pl )
		end

		if ( amount < price ) then
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

				// @add to callback
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

		local time = os.time()

		credits.db.query( credits.db.queries.setCredits:format( amount, pl:SteamID64() ) .. credits.db.queries.insertTransaction:format( duration or "null", pl:SteamID64(), package.uniqueid, -price, package.type, credits.db.conn:escape( util.TableToJSON( package.vars ) ), time ) .. "SELECT LAST_INSERT_ID() AS `id` FROM `transactions`; SELECT `expireTime` AS `expireTime` FROM `transactions` WHERE `id` = ( SELECT LAST_INSERT_ID() )", function( query )
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

				da.amsg( "Someone bought something! thanks # for buying #!" )
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
	end )
end

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

// initialize players

-- credits.db.query( "SELECT * FROM `packages`", function( query, packages )
-- 	// @ cut
-- 	for k, v in pairs( packages ) do
-- 		v.vars = v.vars and util.JSONToTable( v.vars )
-- 		v.upgradeFrom = v.upgradeFrom and util.JSONToTable( v.upgradeFrom )
		
-- 		-- if v.image == a url instead of a table, JSONToTable will return nil and we can correct for that
-- 		local JtT = v.image and util.JSONToTable( v.image )
-- 			v.image = v.image and ( JtT or v.image )
-- 	end

-- 	credits.packages = packages

-- 	for k, v in ipairs( credits.queue ) do
-- 		if ( IsValid( v ) ) then
-- 			credits.InitializePlayer( v )
-- 		end
-- 	end

-- 	credits.queue = nil

-- 	hook.Run( "creditPackagesLoaded" )
-- end )

function credits.initializePlayer( pl )
	// insert into queue for initialization
	// @ cut
	-- if ( not credits.packages ) then
	-- 	table.insert( credits.queue, pl )
	-- 	return
	-- end

	credits.getData( pl:SteamID64(), function( creditAmount, transactions, error )		
		if ( IsValid( pl ) ) then
			if ( error ) then
				creditAmount = 0
				transactions = {}
			end

			pl.credits = { [ "transactions" ] = {} }

			for k, v in ipairs( transactions ) do
				pl.credits.transactions[ v.id ] = v
			end

			// @ cut to only request when opening f4
			// credits.net.sendCredits( pl )

			-- run player inits for package prereqs
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
