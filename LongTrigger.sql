CREATE OR REPLACE FUNCTION rentalChanges()
RETURNS TRIGGER LANGUAGE plpgsql
AS $$
	DECLARE
		v_old_membername VARCHAR(100);
		v_old_dvdtitle VARCHAR(100);
		v_old_rentedcount INTEGER;
		v_new_membername VARCHAR(100);
		v_new_dvdtitle VARCHAR(100);
		v_new_genreid INTEGER;
		v_new_genre VARCHAR(50);
		v_new_ratingid INTEGER;
		v_new_rating VARCHAR(5);
		v_new_rentedcount INTEGER;
    BEGIN
		IF TG_OP = 'INSERT' THEN
			--Grab Member name from member table
			SELECT memberfirstname || ' ' || memberlastname
			INTO v_new_membername
			FROM Member
			WHERE NEW.memberid = Member.memberid;
			
			--Grab relevant columns from dvd table based on dvdid
			SELECT dvdtitle, genreid, ratingid
			INTO v_new_dvdtitle, v_new_genreid, v_new_ratingid
			FROM Dvd
			WHERE NEW.dvdid = Dvd.dvdid;

			-- Grab genre name
			SELECT genrename
			INTO v_new_genre
			FROM Genre
			WHERE v_new_genreid = Genre.genreid;
			
			-- Grab rating name
			SELECT ratingname
			INTO v_new_rating
			FROM Rating
			WHERE v_new_ratingid = Rating.ratingid;
			
			-- Don't need a group by here to grab the count of rows that = a memberid
			SELECT COUNT(rentalid)
			INTO v_new_rentedcount
			FROM Rental
			WHERE NEW.memberid = Rental.memberid;
			
			-- Add to RentalHistory
			INSERT INTO RentalHistory(membername, dvdtitle, genre, rating, rentedcount)
			VALUES (v_new_membername, v_new_dvdtitle, v_new_genre, v_new_rating, v_new_rentedcount);
			
		ELSIF TG_OP = 'UPDATE' THEN
		    /*
            TODO: Scope out all the different cases where we need to determine
            what the new totals are for which customer-dvd combinations.
            */
			-- Grab OLD MemberName for rentalHistory table old row location
			SELECT memberfirstname || ' ' || memberlastname
			INTO v_old_membername
			FROM Member
			WHERE OLD.memberid = Member.memberid;
			
			-- Grab OLD DvdTitle for rentalHistory table old row location
			SELECT dvdtitle
			INTO v_old_dvdtitle
			FROM Dvd
			WHERE OLD.dvdid = Dvd.dvdid;
			
			IF OLD.memberid != NEW.memberid THEN
			    IF OLD.dvdid != NEW.dvdid THEN
			        RAISE EXCEPTION USING MESSAGE = 'Cannot update both member and dvd at once',
		            ERRCODE = 57014; -- query_canceled = 57014
			    ELSE
                    --Grab Member names from member table
                    SELECT memberfirstname || ' ' || memberlastname
                    INTO v_new_membername
                    FROM Member
                    WHERE NEW.memberid = Member.memberid;

                    --IF EXISTS(SELECT 1 FROM RentalHistory WHERE )
                    UPDATE RentalHistory
                    SET membername=v_new_membername
                    WHERE membername = v_old_membername AND dvdtitle = v_old_dvdtitle;
                END IF;

			ELSIF OLD.dvdid != NEW.dvdid THEN
				--Grab relevant columns from dvd table based on dvdid
				SELECT dvdtitle, genreid, ratingid
				INTO v_new_dvdtitle, v_new_genreid, v_new_ratingid
				FROM Dvd
				WHERE NEW.dvdid = Dvd.dvdid;

				-- Grab genre name
				SELECT genrename
				INTO v_new_genre
				FROM Genre
				WHERE v_new_genreid = Genre.genreid;

				-- Grab rating name
				SELECT ratingname
				INTO v_new_rating
				FROM Rating
				WHERE v_new_ratingid = Rating.ratingid;

                -- Don't need a group by here to grab the count of rows that = a memberid
                SELECT COUNT(rentalid)
                INTO v_new_rentedcount
                FROM Rental
                WHERE NEW.memberid = Rental.memberid;

                UPDATE RentalHistory
                SET dvdtitle=v_new_dvdtitle
                WHERE membername = v_old_membername AND dvdtitle = v_old_dvdtitle;
			END IF;

		ELSIF TG_OP = 'DELETE' THEN
            -- Grab OLD MemberName for rentalHistory table old row location
			SELECT memberfirstname || ' ' || memberlastname
			INTO v_old_membername
			FROM Member
			WHERE OLD.memberid = Member.memberid;

			-- Grab OLD DvdTitle for rentalHistory table old row location
			SELECT dvdtitle
			INTO v_old_dvdtitle
			FROM Dvd
			WHERE OLD.dvdid = Dvd.dvdid;

            UPDATE RentalHistory
            SET rentedcount = rentedcount - 1
            WHERE membername = v_old_membername AND dvdtitle = v_old_dvdtitle;
		END IF;
	END;
$$;

CREATE TRIGGER rentalChanges
BEFORE DELETE ON Rental
FOR EACH ROW 
EXECUTE PROCEDURE rentalChanges();

