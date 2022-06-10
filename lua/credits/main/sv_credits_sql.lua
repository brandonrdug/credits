require( "mysqloo" )

credits.db.conn = credits.db.conn or mysqloo.connect( unpack( credits.config.get( "MySQL Connection Info" ) ) )

function credits.db.conn:onConnectionFailed( err )
	error( "credits connection failed:\n\t" .. err )
end

--[[
	Name: query
	Desc: Runs a query with the provided string, and calls back with data returned from the query
	Params: <string> Query, <function> Function
	Returns: <query> Query
	Callback Args: <query> Query, <table> Data
]]--

function credits.db.query( queryStr, func )
	local query = credits.db.conn:query( queryStr )
	query.onSuccess = func

	query.onError = function( sql, err )
		error( "credits query failed:\n\t" .. err .. "\n\t" .. queryStr )
	end

	query:start()

	return query
end

if ( credits.db.conn:status() == mysqloo.DATABASE_NOT_CONNECTED ) then	
	credits.db.conn:connect()
end

// @outline
// remove users table
// remove packages table
// change transactions table to live in hub app, and make api calls instead
// add server column to transactions

-- CREATE TABLE IF NOT EXISTS `users` (
-- 	`steamID64` varchar(20)	NOT NULL,
-- 	`credits` int			NOT NULL DEFAULT 0
-- );

-- CREATE TABLE IF NOT EXISTS `packages` (
-- 	`id` int				NOT NULL AUTO_INCREMENT,
-- 	`uniqueid` tinytext 	NOT NULL,
-- 	`name` tinytext			NOT NULL,
-- 	`category` tinytext 	NOT NULL,
-- 	`description` text		NOT NULL,
-- 	`credits` int			NOT NULL,
-- 	`discount` float		DEFAULT NULL,
-- 	`type` tinytext			NOT NULL,
-- 	`duration` int			DEFAULT NULL,
-- 	`upgradeFrom` text		DEFAULT NULL,
-- 	`buyOnce` bool			DEFAULT 0,
-- 	`order` int				DEFAULT 0,
-- 	`image` text			DEFAULT NULL,
-- 	`vars` text				NOT NULL,
-- 	`disabled` bool			DEFAULT 0,
-- 	PRIMARY KEY ( `id` )
-- );

credits.db.query( [[
	CREATE TABLE IF NOT EXISTS `CreditTransactions` (
		`id` int				NOT NULL AUTO_INCREMENT,
		`steamID64` varchar(20)	NOT NULL,
		`package` tinytext		NOT NULL,
		`credits` int			NOT NULL,
		`activated` bool		DEFAULT 0,
		`type` tinytext			NOT NULL,
		`vars` text				NOT NULL,
		`time` int				NOT NULL,
		`updatedAt` int		DEFAULT NULL,
		`expireTime` int		DEFAULT NULL,
		`disabled` bool			DEFAULT 0,
		`server` tinytext		NOT NULL,
		PRIMARY KEY( `id` )
	)
]] )

credits.db.queries = {
	-- // cut
	-- insertUser = [[
	-- 	INSERT INTO `users`
	-- 		VALUES( '%s', %s );
	-- ]],
	// alter for hub table
	// make avoid transactions from other servers
	getData = [[
		SET @steamID64 = '%s';
		SELECT `credits` FROM `Users`
			WHERE `steamid` = @steamID64;
		SELECT * FROM `CreditTransactions`
			WHERE `steamID64` = @steamID64
				AND `server` = ']] .. credits.config.get( "server" ) .. "';",
	// alter as an api call
	-- setCredits = [[
	-- 	UPDATE `users`
	-- 		SET `credits` = %s
	-- 		WHERE `steamID64` = '%s';
	-- ]],
	getCredits = [[
		SELECT `credits`
			FROM `Users`
			WHERE `steamid` = '%s';
	]],
	-- // cut
	-- insertPackage = [[
	-- 	INSERT INTO `packages` ( `uniqueid`, `name`, `category`, `description`, `credits`, `type`, `upgradeFrom`, `buyOnce`, `order`, `image`, `vars`, `duration` )
	-- 		VALUES ( '%s', '%s', '%s', '%s', %s, '%s', '%s', %s, %s, %s, '%s', %s);
	-- ]],
	-- // cut
	-- getMaxID = "SELECT MAX( `id` ) AS `id` from `packages`;",
	-- // cut
	-- updateDiscount = [[
	-- 	UPDATE `packages`
	-- 		SET `discount` = %s
	-- 		WHERE `id` = %s;
	-- ]],
	// alter
	insertTransaction = [[
		SET @duration = %s;
		INSERT INTO `CreditTransactions` ( `steamID64`, `package`, `credits`, `type`, `vars`, `time`, `expireTime`, `server` )
			VALUES ( '%s', '%s', %s, '%s', '%s', UNIX_TIMESTAMP(), IF( @duration, @duration + UNIX_TIMESTAMP(), null '), ]] .. credits.config.get( "server" ) .. "');",
	disableTransactionByPackage = [[
		UPDATE `CreditTransactions` 
			SET `disabled` = 1,
				`updatedAt` = UNIX_TIMESTAMP()
			WHERE `steamID64` = '%s'
				AND `package` = '%s'
				AND `server` = ']] .. credits.config.get( "server" ) .. "';",
}