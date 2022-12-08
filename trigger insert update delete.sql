CREATE OR REPLACE FUNCTION rentalChanges()
RETURNS TRIGGER LANGUAGE plpgsql
AS $$
	DECLARE
		v_membername VARCHAR(100);
		v_dvdtitle VARCHAR(100);
		v_genreid INTEGER;
		v_genre VARCHAR(50);
		v_ratingid INTEGER;
		v_rating VARCHAR(5);
		v_rentedcount INTEGER;
    BEGIN
		IF TG_OP = 'INSERT' THEN
			SELECT memberfirstname || ' ' || memberlastname
			INTO v_membername
			FROM Member
			WHERE NEW.memberid = Member.memberid

			SELECT dvdtitle, genreid, ratingid
			INTO v_dvdtitle, v_genreid, v_ratingid
			FROM Dvd
			WHERE NEW.dvdid = Dvd.dvdid

			SELECT genrename
			INTO v_genre
			FROM Genre
			WHERE v_genreid = Genre.genreid

			SELECT ratingname
			INTO v_rating
			FROM Rating
			WHERE v_ratingid = Rating.ratingid
			
			SELECT COUNT(rentalid)
			INTO v_rentedcount
			FROM Rental
			WHERE memberid = NEW.memberid

			INSERT INTO RentalHistory(membername, dvdtitle, genre, rating, rentedcount)
			VALUES 
				(v_membername, v_dvdtitle, v_genre, v_rating, v_rentedcount);
		ELSIF TG_OP = 'UPDATE' THEN

		ELSIF TG_OP = 'DELETE' THEN

		END IF;
	END;
$$;

CREATE TRIGGER rentalChanges
BEFORE DELETE ON Rental
FOR EACH ROW 
EXECUTE PROCEDURE rentalChanges();