CREATE TYPE my_type AS (left_out int, left_month int);

CREATE OR REPLACE FUNCTION how_many_more(customer_id IN INTEGER)
RETURNS my_type 
AS $$
	DECLARE
		row RECORD;
		row2 RECORD;
		membership_type_id NUMERIC;
		dvds_left_this_month INTEGER;
		dvd_count INTEGER;
		
		v_left_out INTEGER;
		v_left_month INTEGER;
		mt my_type;
	BEGIN
		-- grab membership type id
		SELECT membershipid 
		INTO membership_type_id
		FROM Member 
		WHERE memberid = customer_id;
		
		-- grab the 2 types of limitations
		SELECT membershiplimitpermonth, "DVDAtTime"
		INTO row
		FROM Membership
		WHERE membershipid = membership_type_id;
		
		-- grab how many dvds they currently have out
		SELECT Count(rentalid)
		INTO dvd_count
		FROM rental 
		WHERE memberid = customer_id
		AND RentalReturnedDate IS NULL;
		
		-- Determine how many movies they can have out currently
		SELECT row."DVDAtTime" - dvd_count INTO v_left_out;
		
	    -- Determine how many movies they can have this month
		SELECT COUNT(*)
		INTO v_left_month
		FROM rental 
		WHERE memberid = customer_id
		AND to_char(CURRENT_DATE, 'mm') = to_char(rentalshippeddate, 'mm');
		
		SELECT row.membershiplimitpermonth - v_left_month INTO v_left_month;
		
		mt.left_out:= v_left_out;
		mt.left_month:= v_left_month;
		RETURN mt;
	END;
$$ LANGUAGE plpgsql;
SELECT * FROM how_many_more(1);
