DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
ALTER USER postgres WITH PASSWORD '1321';

--GOOD
CREATE  TABLE locations (
            country              varchar   ,
            city                 varchar   ,
            location_id          SERIAL	   ,
            CONSTRAINT pk_location PRIMARY KEY ( location_id ),
            CONSTRAINT un_location UNIQUE (country, city)
);
CREATE RULE no_delete_locations AS ON DELETE TO locations
    DO INSTEAD NOTHING;
CREATE RULE no_update_locations AS ON UPDATE TO locations
    DO INSTEAD NOTHING;
----

--GOOD
CREATE TYPE genders AS ENUM (
    'Male',
    'Female',
    'Unspecified'
);
----

--GOOD
CREATE TYPE relationshipstatus AS ENUM (
    'Married',
    'Single',
    'Engaged',
    'In a civil partnership',
    'In a domestic partnership',
    'In an open relationship',
    'It is complicated',
    'Separated',
    'Divorced',
    'Widowed'
);
----

--GOOD
CREATE  TABLE users (
            first_name           varchar(100)  NOT NULL ,
            last_name            varchar(100)  NOT NULL ,
            birthday             date NOT NULL ,
            email                varchar(254)  NOT NULL ,
            relationship_status  relationshipstatus  NOT NULL ,
            gender               genders  NOT NULL ,
            user_password 		 varchar(50) NOT NULL,
            user_location_id  	 integer   ,
            picture_url 		 varchar(255),
            user_id              SERIAL ,
            CONSTRAINT pk_user PRIMARY KEY ( user_id ),
            CONSTRAINT un_email UNIQUE ( email ),
            CONSTRAINT fk_user_location FOREIGN KEY ( user_location_id ) REFERENCES locations( location_id ) ON DELETE SET NULL ON UPDATE CASCADE,
            CONSTRAINT ch_user_birthday CHECK ((now() - (birthday)::timestamp with time zone) >= '13 years'::interval year)
);
CREATE FUNCTION check_password(
    _email varchar,
    _user_password varchar
)
    RETURNS BOOLEAN AS
$$
BEGIN
    RETURN EXISTS (SELECT * FROM users WHERE users.email = _email AND users.user_password = _user_password);
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION check_email(
    _email varchar
)
    RETURNS BOOLEAN AS
$$
BEGIN
    RETURN EXISTS (SELECT * FROM users WHERE users.email = _email);
END;
$$
LANGUAGE plpgsql;
----

--GOOD
CREATE  TABLE friendship (
            friend1              integer  NOT NULL ,
            friend2              integer  NOT NULL ,
            date_from            timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            CONSTRAINT pk_friendship PRIMARY KEY ( friend1, friend2 ),
            CONSTRAINT fk_friendship_user1 FOREIGN KEY ( friend1 ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_friendship_user2 FOREIGN KEY ( friend2 ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT ch_friendship CHECK (friend1 <> friend2)
);
CREATE RULE no_update_friendship AS ON UPDATE TO friendship
    DO INSTEAD NOTHING;
CREATE RULE check_delete_friendship AS ON DELETE TO friendship
    DO ALSO DELETE FROM friendship kek WHERE kek.friend2 = OLD.friend1 AND kek.friend1 = OLD.friend2;
CREATE RULE check_insert_friendship AS ON INSERT TO friendship
    DO ALSO INSERT INTO friendship VALUES (NEW.friend2, NEW.friend1, NEW.date_from);
----

--GOOD
CREATE  TABLE friend_request (
            from_whom            integer  NOT NULL ,
            to_whom              integer  NOT NULL ,
            request_date         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            CONSTRAINT pk_friendrequest PRIMARY KEY ( from_whom, to_whom ),
            CONSTRAINT fk_friendrequest_user1 FOREIGN KEY ( from_whom ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_friendrequest_user2 FOREIGN KEY ( to_whom ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT ch_friendrequest CHECK (from_whom <> to_whom)
);
CREATE RULE no_update_friend_request AS ON UPDATE TO friend_request
    DO INSTEAD NOTHING;

CREATE OR REPLACE FUNCTION check_friend_request()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS
        (
            SELECT * FROM friendship kek
            WHERE (NEW.from_whom =  kek.friend1 AND NEW.to_whom = kek.friend2)
               OR (NEW.from_whom = kek.friend2 AND NEW.to_whom = kek.friend1)
        ) THEN
        NEW = NULL;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER check_insert_friend_request BEFORE INSERT ON friend_request
    FOR EACH ROW EXECUTE PROCEDURE check_friend_request();

CREATE OR REPLACE FUNCTION add_friend_request()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS
        (
            SELECT * FROM friend_request kek
            WHERE NEW.from_whom = kek.to_whom
              AND NEW.to_whom = kek.from_whom
        ) THEN
        DELETE FROM friend_request
        WHERE NEW.from_whom = kek.to_whom AND NEW.to_whom = kek.from_whom;
        INSERT INTO friendship
        VALUES (NEW.from_whom, NEW.to_whom);
        NEW = NULL;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;
CREATE TRIGGER insert_friend_request BEFORE INSERT ON friend_request
    FOR EACH ROW EXECUTE PROCEDURE add_friend_request();
----

--GOOD
CREATE  TABLE message (
            user_from            integer  NOT NULL ,
            user_to              integer  NOT NULL ,
            message_text         varchar(250)  NOT NULL ,
            message_date         timestamp DEFAULT CURRENT_DATE NOT NULL ,
            message_id           SERIAL ,
            CONSTRAINT pk_message_id PRIMARY KEY ( message_id ),
            CONSTRAINT fk_message_user1 FOREIGN KEY ( user_from ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_message_user2 FOREIGN KEY ( user_to ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT ch_message CHECK (user_from <> user_to)
);
----

--GOOD
CREATE  TABLE posts (
            user_id 			 integer NOT NULL,
            post_text         	 varchar(250)  NOT NULL ,
            post_date            timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            reposted_from        integer   ,
            post_id              SERIAL ,
            CONSTRAINT pk_post_id PRIMARY KEY ( post_id ),
            CONSTRAINT fk_repost FOREIGN KEY ( reposted_from ) REFERENCES posts( post_id ) ON DELETE SET NULL ON UPDATE CASCADE,
            CONSTRAINT fk_user_id FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE VIEW get_all_posts AS SELECT * FROM posts;

CREATE FUNCTION get_user_posts(
    id integer
)
    RETURNS TABLE(
        user_id integer,
        post_test varchar(250),
        post_date timestamp,
        reposted_from integer,
        post_id integer
    )
AS
$$
BEGIN
    RETURN QUERY (SELECT * FROM posts WHERE posts.user_id = id);
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION get_number_of_reposts_on_post(
    id integer
)
    RETURNS INTEGER
AS
$$
BEGIN
    RETURN (SELECT COUNT(*) FROM posts WHERE reposted_from = id);
END;
$$
LANGUAGE plpgsql;
----

--GOOD
CREATE  TABLE like_sign (
            post_id              integer  NOT NULL ,
            user_id              integer  NOT NULL ,
            CONSTRAINT pk_like_sign PRIMARY KEY ( post_id, user_id ),
            CONSTRAINT fk_like_sign_user_id FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_like_sign_post_id FOREIGN KEY ( post_id ) REFERENCES posts( post_id ) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE FUNCTION get_number_of_likes_on_post(
    id integer
)
    RETURNS INTEGER
AS
$$
BEGIN
    RETURN (SELECT COUNT(*) FROM like_sign WHERE post_id = id);
END;
$$
LANGUAGE plpgsql;
----

--GOOD
CREATE TYPE facility_types AS ENUM (
    'School',
    'University',
    'Work'
);
----

--GOOD
CREATE  TABLE facility (
            facility_name        varchar(100)  NOT NULL ,
            facility_location    integer NOT NULL,
            facility_type	     facility_types NOT NULL,
            facility_id          SERIAL ,
            CONSTRAINT pk_facility_id PRIMARY KEY ( facility_id ),
            CONSTRAINT fk_facility_location FOREIGN KEY ( facility_location ) REFERENCES locations( location_id ),
            CONSTRAINT un_facility UNIQUE(facility_name, facility_location, facility_type)
);
----

--GOOD
CREATE  TABLE user_facility (
            user_id              integer  NOT NULL ,
            facility_id          integer  NOT NULL ,
            date_from            timestamp  NOT NULL ,
            date_to              timestamp   ,
            description          varchar(100),
            CONSTRAINT pk_user_facility PRIMARY KEY ( user_id, facility_id, date_from ),
            CONSTRAINT fk_user_facility_user_id FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
            CONSTRAINT fk_user_facility_facility_id FOREIGN KEY ( facility_id ) REFERENCES facility( facility_id ),
            CONSTRAINT ch_date CHECK ((date_to IS NULL) OR (date_to >= date_from))
);
----

--SUMMARY: PERFECT TABLE :3
