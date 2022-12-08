CREATE OR REPLACE PROCEDURE return_dvd(rental_id IN INTEGER, is_lost IN BOOL)
AS $$
	DECLARE
		row RECORD;
		limits my_type;
		customer_id INTEGER;
		next_dvdid INTEGER;
		membership_id NUMERIC;
		price DECIMAL;
	BEGIN
		-- grab customer and dvd id
		SELECT memberid, dvdid
		INTO row
		FROM rental
		WHERE rentalid = rental_id;
		
		-- Charge if lost
		IF is_lost THEN
		    -- what type of member are they?
			SELECT membershipid
			INTO membership_id
			FROM member
			WHERE memberid = row.memberid;
			
			-- how much are those types of members charged for lost dvds?
			SELECT membershipdvdlostprice
			INTO price
			FROM membership
			WHERE membershipid = membership_id;
			
			-- charge them accordingly
			INSERT INTO payment(paymentid, memberid, amountpaid, amountpaiddate, amountpaiduntildate)
			VALUES (nextval('paymentSequence'), row.memberid, price, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month');
			
			-- update dvd quantities
			UPDATE dvd
			SET dvdquantityonrent = dvdquantityonrent - 1, dvdlostquantity = dvdlostquantity + 1
			WHERE dvdid = row.dvdid;
		ELSE
			-- update dvd quantities
			UPDATE dvd
			SET dvdquantityonrent = dvdquantityonrent - 1, dvdquantityonhand = dvdquantityonhand + 1
			WHERE dvdid = row.dvdid;
			
			-- check rental back in
			UPDATE rental
			SET rentalreturneddate = CURRENT_DATE
			WHERE rentalid = rental_id;
		END IF;
		
		-- grab how many additional dvds can be rented
		SELECT * FROM how_many_more(row.memberid::INTEGER) INTO limits;
		
		-- If they have not hit a limit
		IF limits.left_out > 0 AND limits.left_month > 0 THEN
			-- grab next dvd
			SELECT next_dvd(row.memberid::INTEGER) INTO next_dvdid;

			-- create new rental
			INSERT INTO rental(rentalid, memberid, dvdid, rentalrequestdate, rentalshippeddate, rentalreturneddate)
			VALUES (nextval('rentalsequence'), row.memberid, next_dvdid, CURRENT_DATE, CURRENT_DATE, NULL);

			-- update next dvd quantities
			UPDATE dvd
			SET dvdquantityonrent = dvdquantityonrent + 1, dvdquantityonhand = dvdquantityonhand - 1
			WHERE dvdid = next_dvdid;
		END IF;
	END;
$$ LANGUAGE plpgsql;