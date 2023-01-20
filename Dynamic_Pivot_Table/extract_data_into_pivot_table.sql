DELIMITER $$
DROP PROCEDURE IF EXISTS `EXTRACT_DATA_TO_PIVOT_TABLE`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EXTRACT_DATA_TO_PIVOT_TABLE`(IN `selectedMonth` TINYINT) 
	MODIFIES SQL DATA 
BEGIN 
	DECLARE done INT DEFAULT FALSE;
	DECLARE kategori_produk VARCHAR(60);
	DECLARE jlh, total_per_date INT DEFAULT 0;
    DECLARE cur_date, last_date date DEFAULT "2000-01-01";
    
  DECLARE cur1 CURSOR FOR SELECT tanggal_transaksi, kategori, jumlah_terjual_perhari FROM    
  (
      SELECT date(waktu_transaksi) as tanggal_transaksi, kategori, SUM(jumlah) as jumlah_terjual_perhari 
     FROM `transaksi` WHERE MONTH(waktu_transaksi) = `selectedMonth`
     GROUP BY tanggal_transaksi, kategori 
     ORDER BY tanggal_transaksi, kategori 
   ) AS sorted_data;
   
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  
   
   	SET @counter = 0;
   	SET @column_syntax = "";
	SET @values_syntax = "";
  	SET @col_name = "";
  	SET @sql = "";
    
    SELECT count(tanggal_transaksi) INTO @total_data FROM 
    (
    	SELECT date(waktu_transaksi) as tanggal_transaksi
     	FROM `transaksi` WHERE MONTH(waktu_transaksi) = `selectedMonth`
     	GROUP BY tanggal_transaksi, kategori 
     	ORDER BY tanggal_transaksi, kategori 
     ) as data_count;
    
    OPEN cur1;
    	cur1_loop: LOOP
        	FETCH cur1 INTO cur_date, kategori_produk, jlh;
            
            -- IF (cur_date != last_date AND @counter > 0) OR (cur_date = last_date AND @counter >= @total_data) THEN
	    IF (cur_date != last_date AND @counter > 0) OR (@counter >= @total_data) THEN
            	SET @column_syntax = CONCAT("`Tanggal`, ", @column_syntax, "`Total Produk Terjual`");
                
                SET @tgl = CONCAT("'", DATE(last_date), "'");
				SET @values_syntax = CONCAT(@tgl, ",", SUBSTRING(@values_syntax, 2), ",", total_per_date);
                
                SET @sql = CONCAT('INSERT INTO `pivot_temp` (', @column_syntax, ') VALUES (', @values_syntax, ')');
                
                PREPARE myquery FROM @sql;
				EXECUTE myquery;
				DEALLOCATE PREPARE myquery;
                
                SET @sql = "";
				SET @col_name = "";
				SET @column_syntax = "";
				SET @values_syntax = "";
				SET total_per_date = 0;
            END IF;
            
            SET last_date = cur_date;
      
      		SET @col_name = CONCAT("`", kategori_produk, "`,");
      		SET @column_syntax = CONCAT(@column_syntax, @col_name);
            SET @values_syntax = CONCAT(@values_syntax, ",", jlh);

      		SET total_per_date = total_per_date + jlh;
            SET @counter = @counter + 1;
        	
            IF done THEN
	    	SET @sql = "";
                LEAVE cur1_loop;
            END IF;
        END LOOP cur1_loop;
    CLOSE cur1;
   -- SELECT @sql INTO OUTFILE "D:\sql.txt"
   -- SELECT @counter
   
END$$
DELIMITER ;
