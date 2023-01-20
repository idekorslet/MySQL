DELIMITER $$
DROP PROCEDURE IF EXISTS `CREATE_PIVOT_TABLE`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CREATE_PIVOT_TABLE`(IN `selectedMonth` TINYINT)
	MODIFIES SQL DATA 
BEGIN
	SELECT GROUP_CONCAT(CONCAT("`", kategori, "`", " varchar(60)") SEPARATOR ",") as kategori_list         
	INTO @nama_kategori FROM
	(
		SELECT kategori FROM `transaksi` 
		WHERE MONTH(waktu_transaksi) = `selectedMonth`
		GROUP BY kategori
		ORDER BY kategori
	) AS daftar_kategori;
        
	DROP TABLE IF EXISTS `coba`.`pivot_temp`;

	SET @sql = CONCAT('CREATE TABLE `coba`.`pivot_temp` (`Tanggal` DATE NULL DEFAULT "2000-01-01", ', @nama_kategori, ', 
	`Total Produk Terjual` INT) ENGINE=InnoDB;');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET @sql = NULL;
    SET @nama_kategori = NULL;
END$$
DELIMITER ;
