require( "mysqloo" )

credits.db.conn = credits.db.conn or mysqloo.connect( unpack( credits.config.get( "MySQL Connection Info" ) ) )

function credits.db.conn:onConnectionFailed( err )
	error( "credits connection failed:\n\t" .. err )
end

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
		`updatedAt` int			DEFAULT NULL,
		`expireTime` int		DEFAULT NULL,
		`disabled` bool			DEFAULT 0,
		`server` tinytext		NOT NULL,
		PRIMARY KEY( `id` )
	)
]] )

credits.db.queries = {
	getCredits = [[
		SELECT `credits`
			FROM `Users`
			WHERE `steamid` = '%s';
	]],
	getTransactions = [[
		SELECT * FROM `CreditTransactions`
			WHERE `steamID64` = '%s'
			AND `server` = ']] .. credits.config.get( "server" ) .. "';",
	insertTransaction = [[
		SET @duration = %s;
		INSERT INTO `CreditTransactions` ( `steamID64`, `package`, `credits`, `type`, `vars`, `time`, `expireTime`, `server` )
			VALUES ( '%s', '%s', %s, '%s', '%s', UNIX_TIMESTAMP(), IF( @duration, @duration + UNIX_TIMESTAMP(), null ), ']] .. credits.config.get( "server" ) .. "');",
	disableTransactionByPackage = [[
		UPDATE `CreditTransactions` 
			SET `disabled` = 1,
				`updatedAt` = UNIX_TIMESTAMP()
			WHERE `steamID64` = '%s'
				AND `package` = '%s'
				AND `server` = ']] .. credits.config.get( "server" ) .. "';",
}