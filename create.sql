DROP SCHEMA IF EXISTS public CASCADE; --dont forget to comment this lines
CREATE SCHEMA public; --this
ALTER USER postgres WITH PASSWORD '1321'; --and this
----
CREATE  TABLE locations (
            country              varchar(100)   ,
            city                 varchar(100)   ,
            location_id          SERIAL	   ,
            CONSTRAINT pk_location PRIMARY KEY ( location_id ),
            CONSTRAINT un_location UNIQUE (country, city)
);
--CREATE INDEX locations_index_location ON locations(country, city);

CREATE RULE no_delete_locations AS ON DELETE TO locations
    DO INSTEAD NOTHING;
CREATE RULE no_update_locations AS ON UPDATE TO locations
    DO INSTEAD NOTHING;
----

----
CREATE TYPE genders AS ENUM (
    'Male',
    'Female',
    'Unspecified'
    );
----

----
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

----
CREATE  TABLE users (
            first_name           varchar(32)            NOT NULL ,
            last_name            varchar(32)            NOT NULL ,
            birthday             date                   NOT NULL ,
            email                varchar(100)           NOT NULL ,
            relationship_status  relationshipstatus     NOT NULL ,
            gender               genders                NOT NULL ,
            user_password 		 varchar(64)            NOT NULL ,
            user_location_id  	 integer DEFAULT NULL,
            picture_url 		 varchar(500) DEFAULT NULL,
            user_id              SERIAL ,
            CONSTRAINT pk_user PRIMARY KEY ( user_id ),
            CONSTRAINT un_email UNIQUE ( email ),
            CONSTRAINT fk_user_location FOREIGN KEY ( user_location_id ) REFERENCES locations( location_id ),
            CONSTRAINT ch_user_birthday CHECK ((now() - (birthday)::timestamp with time zone) >= '13 years'::interval year)
);
--CREATE INDEX users_index_name ON users(first_name, last_name);
--CREATE INDEX users_index_user_location_id ON users(user_location_id);

CREATE OR REPLACE FUNCTION no_update_user_id()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.user_id != OLD.user_id THEN
        NEW.user_id = OLD.user_id;
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;
CREATE TRIGGER no_update_user_id BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE no_update_user_id();

CREATE FUNCTION check_password(
    _email varchar,
    _user_password varchar
)
    RETURNS BOOLEAN AS
$$
BEGIN
    RETURN EXISTS (
        SELECT *
        FROM users
        WHERE users.email = _email AND users.user_password = _user_password
    );
END;
$$
    LANGUAGE plpgsql;

CREATE FUNCTION check_email(
    _email varchar
)
    RETURNS BOOLEAN AS
$$
BEGIN
    RETURN EXISTS (
        SELECT *
        FROM users
        WHERE users.email = _email
    );
END;
$$
    LANGUAGE plpgsql;
----

----
CREATE  TABLE friendship (
            friend1              integer                             NOT NULL ,
            friend2              integer                             NOT NULL ,
            date_from            timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            CONSTRAINT pk_friendship PRIMARY KEY ( friend1, friend2 ),
            CONSTRAINT fk_friendship_user1 FOREIGN KEY ( friend1 ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT fk_friendship_user2 FOREIGN KEY ( friend2 ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT ch_friendship CHECK (friend1 <> friend2)
);
--CREATE INDEX friendship_index_friend1 ON friendship(friend1);

CREATE RULE no_update_friendship AS ON UPDATE TO friendship
    DO INSTEAD NOTHING;

CREATE OR REPLACE FUNCTION check_delete_friendship()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (
            SELECT *
            FROM friendship f
            WHERE f.friend1 = OLD.friend2 AND f.friend2 = OLD.friend1
    ) THEN
        DELETE FROM friendship f WHERE f.friend1 = OLD.friend2 AND f.friend2 = OLD.friend1;
    END IF;
    RETURN NULL;
END;
$$
    LANGUAGE plpgsql;

CREATE TRIGGER check_delete_friendship AFTER DELETE ON friendship
    FOR EACH ROW EXECUTE PROCEDURE check_delete_friendship();

CREATE OR REPLACE FUNCTION check_insert_friendship()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NOT EXISTS (
            SELECT *
            FROM friendship f
            WHERE NEW.friend1 = f.friend2 AND NEW.friend2 = f.friend1
    ) THEN
        INSERT INTO friendship VALUES (NEW.friend2, NEW.friend1, NEW.date_from);
    END IF;
    RETURN NULL;
END;
$$
    LANGUAGE plpgsql;

CREATE TRIGGER check_insert_friendship AFTER INSERT ON friendship
    FOR EACH ROW EXECUTE PROCEDURE check_insert_friendship();

CREATE FUNCTION get_number_of_user_friends(id integer)
RETURNS integer
AS
$$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM friendship
        WHERE friend1 = id
    );
END;
$$
    LANGUAGE plpgsql;
----

----
CREATE  TABLE friend_request (
            from_whom            integer                             NOT NULL ,
            to_whom              integer                             NOT NULL ,
            request_date         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            CONSTRAINT pk_friendrequest PRIMARY KEY ( from_whom, to_whom ),
            CONSTRAINT fk_friendrequest_user1 FOREIGN KEY ( from_whom ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT fk_friendrequest_user2 FOREIGN KEY ( to_whom ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT ch_friendrequest CHECK (from_whom <> to_whom)
);
--CREATE INDEX friend_request_from_whom ON friend_request(from_whom);

CREATE RULE no_update_friend_request AS ON UPDATE TO friend_request
    DO INSTEAD NOTHING;

CREATE OR REPLACE FUNCTION add_friend_request()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS
        (
            SELECT *
            FROM friend_request kek
            WHERE NEW.from_whom = kek.to_whom AND NEW.to_whom = kek.from_whom
        ) THEN
        DELETE FROM friend_request kek
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

CREATE OR REPLACE FUNCTION check_friend_request()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS
           (
               SELECT *
               FROM friendship f
               WHERE NEW.from_whom =  f.friend1 AND NEW.to_whom = f.friend2
           )
        OR EXISTS
           (
               SELECT *
               FROM friend_request fr
               WHERE NEW.from_whom = fr.from_whom AND NEW.to_whom = fr.to_whom
           )
    THEN
        NEW = NULL;
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE TRIGGER check_insert_friend_request BEFORE INSERT ON friend_request
    FOR EACH ROW EXECUTE PROCEDURE check_friend_request();
----

----
CREATE  TABLE messages (
            user_from            integer                             NOT NULL ,
            user_to              integer                             NOT NULL ,
            message_text         varchar(250)                        NOT NULL ,
            message_date         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            message_id           SERIAL ,
            CONSTRAINT pk_message_id PRIMARY KEY ( message_id ),
            CONSTRAINT fk_message_user1 FOREIGN KEY ( user_from ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT fk_message_user2 FOREIGN KEY ( user_to ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT ch_message CHECK (user_from <> user_to)
);
--CREATE INDEX messages_index_user_to ON messages(user_to);
--CREATE INDEX messages_index_user_from ON messages(user_from);

CREATE RULE no_update_message AS ON UPDATE TO messages
    DO INSTEAD NOTHING;


CREATE FUNCTION get_latest_message(id1 integer, id2 integer) RETURNS integer AS
$$
BEGIN
    RETURN (SELECT ms.message_id FROM messages ms
            WHERE (ms.user_from = id1 AND ms.user_to = id2) OR (ms.user_from = id2 AND ms.user_to = id1) ORDER BY ms.message_date DESC LIMIT 1);
END;
$$
    LANGUAGE plpgsql;

----

----
CREATE  TABLE posts (
            user_id 			 integer                             NOT NULL,
            post_text         	 varchar(250)                        NOT NULL ,
            post_date            timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL ,
            reposted_from        integer   DEFAULT NULL,
            post_id              SERIAL ,
            CONSTRAINT pk_post_id PRIMARY KEY ( post_id ),
            CONSTRAINT fk_repost FOREIGN KEY ( reposted_from ) REFERENCES posts( post_id ) ON DELETE CASCADE,
            CONSTRAINT fk_user_id FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE
);
--CREATE INDEX posts_index_user_id ON posts(user_id);

CREATE RULE no_update_post AS ON UPDATE TO posts
    DO INSTEAD NOTHING;

CREATE OR REPLACE FUNCTION check_insert_post_date()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.reposted_from IS NOT NULL AND (
        SELECT posts.post_date
        FROM posts
        WHERE posts.post_id = NEW.reposted_from
    ) > NEW.post_date THEN
        NEW = NULL;
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

CREATE TRIGGER check_insert_post BEFORE INSERT ON posts
    FOR EACH ROW EXECUTE PROCEDURE check_insert_post_date();

CREATE FUNCTION get_number_of_user_posts(
    id integer
)
    RETURNS integer
AS
$$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM posts
        WHERE user_id = id
    );
END;
$$
    LANGUAGE plpgsql;

CREATE FUNCTION get_user_posts(
    id integer
)
RETURNS TABLE(
        user_id integer,
        post_text varchar(250),
        post_date timestamp,
        reposted_from integer,
        post_id integer
)
AS
$$
BEGIN
    RETURN QUERY (
        SELECT *
        FROM posts
        WHERE posts.user_id = id
    );
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
    RETURN (
        SELECT COUNT(*)
        FROM posts
        WHERE reposted_from = id
    );
END;
$$
    LANGUAGE plpgsql;

CREATE FUNCTION get_number_of_likes_on_post(
    id integer
)
    RETURNS INTEGER
AS
$$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM like_sign
        WHERE post_id = id
    );
END;
$$
    LANGUAGE plpgsql;


DROP VIEW IF EXISTS get_refactored_all_posts;
CREATE VIEW get_refactored_all_posts
AS SELECT pp.*, kek.first_name, kek.last_name, kek.birthday,
          kek.email, kek.relationship_status, kek.gender,
          kek.user_password, kek.user_location_id, kek.picture_url, kek.user_id as "kek.user_id",
          p.user_id as "p.user_id", p.post_text as "p.post_text",
          p.post_date as "p.post_date", p.reposted_from as "p.reposted_from", p.post_id as "p.post_id",
          us.first_name as "us.first_name", us.last_name as "us.lastname",
          us.birthday as "us.birthday", us.email as "us.email",
          us.relationship_status as "us.relationship_status",
          us.gender as "us.gender", us.user_password as "us.user_password",
          us.user_location_id as "us.user_location_id", us.picture_url as "us.picture_url",
          get_number_of_likes_on_post(pp.post_id) as post_likes,
          get_number_of_likes_on_post(p.post_id) as repost_likes
          FROM posts pp
          JOIN users kek ON pp.user_id = kek.user_id
          LEFT JOIN posts p ON pp.reposted_from = p.post_id
          LEFT JOIN users us ON p.user_id = us.user_id
          ORDER BY pp.post_date DESC;
SELECT * FROM get_refactored_all_posts;

----

----
CREATE  TABLE like_sign (
            post_id              integer                NOT NULL ,
            user_id              integer                NOT NULL ,
            CONSTRAINT pk_like_sign PRIMARY KEY ( post_id, user_id ),
            CONSTRAINT fk_like_sign_user_id FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT fk_like_sign_post_id FOREIGN KEY ( post_id ) REFERENCES posts( post_id ) ON DELETE CASCADE
);
--CREATE INDEX like_sign_index_post_id ON like_sign(post_id);

CREATE RULE no_update_like_sign AS ON UPDATE TO like_sign
    DO INSTEAD NOTHING;

----

----
CREATE TYPE facility_types AS ENUM (
    'School',
    'University',
    'Work'
    );
----

----
CREATE  TABLE facilities (
            facility_name        varchar(100)           NOT NULL,
            facility_location    integer                NOT NULL,
            facility_type	     facility_types         NOT NULL,
            facility_id          SERIAL,
            CONSTRAINT pk_facility_id PRIMARY KEY ( facility_id ),
            CONSTRAINT fk_facility_location FOREIGN KEY ( facility_location ) REFERENCES locations( location_id ),
            CONSTRAINT un_facility UNIQUE(facility_name, facility_location, facility_type)
);
--CREATE INDEX facilities_index_facility_type ON facilities(facility_type);
--CREATE INDEX facilities_index_facility_name ON facilities(facility_location);
--CREATE INDEX facilities_index_facility_location ON facilities(facility_location);

CREATE FUNCTION get_facilities_by_type(
    type facility_types
)
RETURNS TABLE(
        facility_name       varchar(100),
        facility_location   integer,
        facility_type       facility_types,
        facility_id         integer
)
AS
$$
BEGIN
    RETURN QUERY (
        SELECT *
        FROM facilities
        WHERE facilities.facility_type = type
    );
END;
$$
    LANGUAGE plpgsql;
----

----
CREATE  TABLE user_facilities (
            user_id              integer            NOT NULL,
            facility_id          integer            NOT NULL,
            date_from            timestamp          NOT NULL,
            date_to              timestamp DEFAULT NULL,
            description          varchar(100),
            CONSTRAINT pk_user_facility PRIMARY KEY ( user_id, facility_id, date_from ),
            CONSTRAINT fk_user_facility_user_id FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE,
            CONSTRAINT fk_user_facility_facility_id FOREIGN KEY ( facility_id ) REFERENCES facilities( facility_id ),
            CONSTRAINT ch_date CHECK ((date_to IS NULL) OR (date_to >= date_from))
);
--CREATE INDEX user_facilities_user_id ON user_facilities(user_id);

CREATE FUNCTION get_user_facilities(
    id integer
)
RETURNS TABLE(
        facility_name       integer,
        facility_type       facility_types,
        facility_country    varchar(100),
        facility_city       varchar(100),
        date_from           timestamp,
        date_to             timestamp,
        description         varchar(100)
)
AS
$$
BEGIN
    RETURN QUERY (
        SELECT f.facility_name, f.facility_type, l.country, l.city, uf.date_from, uf.date_to, uf.description
        FROM user_facilities uf
                 JOIN facilities f ON uf.facility_id = f.facility_id
                 JOIN locations l ON f.facility_location = l.location_id
        WHERE uf.user_id = id
    );
END;
$$
    LANGUAGE plpgsql;
----

CREATE FUNCTION check_user_filter(
    _user    record,
    fName    varchar,
    lName    varchar,
    _country varchar,
    _city    varchar
)
RETURNS boolean
AS
$$
BEGIN
    IF (_country IS NOT NULL AND _country != '') THEN
        IF NOT EXISTS (
                SELECT *
                FROM locations
                WHERE location_id = _user.user_location_id AND lower(country) LIKE '%'||lower(_country)||'%'
        )THEN
            RETURN FALSE;
        END IF;
    END IF;
    IF (_city IS NOT NULL AND _city != '') THEN
        IF NOT EXISTS(
                SELECT *
                FROM locations
                WHERE location_id = _user.user_location_id AND lower(city) LIKE '%'||lower(_city)||'%'
        ) THEN
            RETURN FALSE;
        END IF;
    END IF;
    IF (lower(_user.first_name) LIKE '%'||lower(fName)||'%')THEN NULL;ELSE RETURN FALSE;END IF;
    IF (lower(_user.last_name) LIKE '%'||lower(lName)||'%')THEN NULL;ELSE RETURN FALSE;END IF;
    RETURN TRUE;
END;
$$
    LANGUAGE plpgsql;

CREATE FUNCTION get_user_friends(
    id integer
) RETURNS TABLE (
        first_name           varchar(100),
        last_name            varchar(100),
        birthday             date,
        email                varchar(254),
        relationship_status  relationshipstatus,
        gender               genders ,
        user_password 		 varchar(50),
        user_location_id  	 integer,
        picture_url 		 varchar(255),
        user_id              integer
)
AS
$$
BEGIN
    RETURN QUERY (
        SELECT *
        FROM users
        WHERE (id, users.user_id) IN (SELECT friend1, friend2 FROM friendship));
END;
$$
    LANGUAGE plpgsql;

CREATE FUNCTION get_user_friends_with_user(
    id integer
) RETURNS TABLE (
                    first_name           varchar(100),
                    last_name            varchar(100),
                    birthday             date,
                    email                varchar(254),
                    relationship_status  relationshipstatus,
                    gender               genders ,
                    user_password 		 varchar(50),
                    user_location_id  	 integer,
                    picture_url 		 varchar(255),
                    user_id              integer
                )
AS
$$
BEGIN
    RETURN QUERY (
        SELECT *
        FROM users
        WHERE (id, users.user_id) IN (SELECT friend1, friend2 FROM friendship)
           OR users.user_id = id
    );
END;
$$
    LANGUAGE plpgsql;

CREATE FUNCTION check_facility_filter(
        _facility record,
        facName varchar,
        facType varchar
)
RETURNS boolean
AS
$$
BEGIN
    IF (lower(_facility.facility_name) LIKE '%'||lower(facName)||'%') THEN NULL;ELSE RETURN FALSE;END IF;
    IF (_facility.facility_type = facType::facility_types) THEN NULL;ELSE RETURN FALSE;END IF;
    RETURN TRUE;
END;
$$
    LANGUAGE plpgsql;

COPY locations (city, country) FROM stdin;
Tokyo	Japan
New York	United States
Mexico City	Mexico
Mumbai	India
São Paulo	Brazil
Delhi	India
Shanghai	China
Kolkata	India
Los Angeles	United States
Dhaka	Bangladesh
Buenos Aires	Argentina
Karachi	Pakistan
Cairo	Egypt
Rio de Janeiro	Brazil
Ōsaka	Japan
Beijing	China
Manila	Philippines
Moscow	Russia
Istanbul	Turkey
Paris	France
Seoul	Korea, South
Lagos	Nigeria
Jakarta	Indonesia
Guangzhou	China
Chicago	United States
London	United Kingdom
Lima	Peru
Tehran	Iran
Kinshasa	Congo (Kinshasa)
Bogotá	Colombia
Shenzhen	China
Wuhan	China
Hong Kong	Hong Kong
Tianjin	China
Chennai	India
Taipei	Taiwan
Bengalūru	India
Bangkok	Thailand
Lahore	Pakistan
Chongqing	China
Miami	United States
Hyderabad	India
Dallas	United States
Santiago	Chile
Philadelphia	United States
Belo Horizonte	Brazil
Madrid	Spain
Houston	United States
Ahmadābād	India
Ho Chi Minh City	Vietnam
Washington	United States
Atlanta	United States
Toronto	Canada
Singapore	Singapore
Luanda	Angola
Baghdad	Iraq
Barcelona	Spain
Hāora	India
Shenyang	China
Khartoum	Sudan
Pune	India
Boston	United States
Sydney	Australia
Saint Petersburg	Russia
Chittagong	Bangladesh
Dongguan	China
Riyadh	Saudi Arabia
Hanoi	Vietnam
Guadalajara	Mexico
Melbourne	Australia
Alexandria	Egypt
Chengdu	China
Rangoon	Burma
Phoenix	United States
Xi’an	China
Porto Alegre	Brazil
Sūrat	India
Hechi	China
Abidjan	Côte D’Ivoire
Brasília	Brazil
Ankara	Turkey
Monterrey	Mexico
Yokohama	Japan
Nanjing	China
Montréal	Canada
Guiyang	China
Recife	Brazil
Seattle	United States
Harbin	China
San Francisco	United States
Fortaleza	Brazil
Zhangzhou	China
Detroit	United States
Salvador	Brazil
Busan	Korea, South
Johannesburg	South Africa
Berlin	Germany
Algiers	Algeria
Rome	Italy
Pyongyang	Korea, North
Jinan	China
\.

SELECT * FROM locations;

COPY users(first_name, last_name, birthday, email, relationship_status, gender, user_password) FROM stdin(FORMAT CSV);
Isaiah,Morris,1983-11-16,isaiah.morris@fmail.com,Single,Male,cIsG5Pg3JM^T&I
Henry,Nguyen,1981-12-23,henry.nguyen@pmail.org,Separated,Male,yxrcZHCnBXwLQIt
Charlotte,Morgan,2002-12-03,charlotte.morgan@omail.org,In an open relationship,Female,rgKNlb0hSz31*#
Christian,Phillips,1987-08-21,christian.phillips@tmail.com,It is complicated,Male,cfZB3zClkMcp$
Alexander,Thomas,1976-07-10,alexander.thomas@omail.com,Married,Male,G%qtRIheE
Aria,Peterson,1995-06-28,aria.peterson@vmail.com,In a domestic partnership,Female,DdO6FjquM
Harper,Allen,1977-01-22,harper.allen@omail.net,Separated,Female,JA0r2Saz&zl
Gabriel,Howard,1976-01-22,gabriel.howard@zmail.com,In a civil partnership,Male,RISctd6gXg0YrQ
Violet,Sanders,1976-06-30,violet.sanders@jmail.org,Divorced,Female,dMiWElVvoG4n
Olivia,Perez,1983-12-11,olivia.perez@hmail.net,Single,Female,p9cmS4lR$PIRX
Aaliyah,Hill,1978-07-19,aaliyah.hill@amail.com,Divorced,Female,q0H7u*eRBpj7D
Allison,Gonzalez,2002-01-01,allison.gonzalez@bmail.org,In a civil partnership,Female,yn84njJJ7ps0G2F
Zoe,Miller,1993-12-16,zoe.miller@lmail.org,Separated,Female,%RZ*cFg$%YSeW
John,Parker,1998-05-15,john.parker@xmail.com,Single,Male,0j6M7XcK&G1F
Penelope,Wilson,1997-06-05,penelope.wilson@vmail.org,Single,Female,1K$s6ANy
Ryan,Foster,1999-10-18,ryan.foster@fmail.org,Single,Male,eV#HJAml$7Ts
Christopher,Ward,1986-04-22,christopher.ward@rmail.net,It is complicated,Male,8#0B&1dCc
Aiden,Cox,2000-04-03,aiden.cox@gmail.net,In a domestic partnership,Male,eb%xHMC15rHCm
Chloe,Cooper,1978-11-28,chloe.cooper@ymail.com,It is complicated,Female,f2Nibd6#K
Joseph,Lopez,1991-03-21,joseph.lopez@cmail.org,In a civil partnership,Male,G3kJVsTOI
Lillian,Turner,1983-11-17,lillian.turner@amail.com,In a civil partnership,Female,hvBOBLsz6nlrOfn
Owen,Scott,1996-08-04,owen.scott@umail.com,In a domestic partnership,Male,gYw5o6OyjdTRC1
Leah,Brooks,1976-09-03,leah.brooks@email.com,Married,Female,WZ3Z5O*7G7kn
Elijah,Hughes,2002-03-16,elijah.hughes@dmail.com,In an open relationship,Male,D#sNROpvMJicbP
Samantha,Rogers,1999-11-05,samantha.rogers@cmail.net,Widowed,Female,qqFok$Owo5S
Noah,Long,1984-11-30,noah.long@umail.com,Divorced,Male,57htx%jxOF4Hm
Nora,Bell,1997-06-26,nora.bell@hmail.org,Separated,Female,6Kq2^s*l1w
Lucas,Collins,2002-02-22,lucas.collins@qmail.net,Divorced,Male,YoUb9uwEf
Julian,Watson,1989-09-22,julian.watson@smail.org,Engaged,Male,$jMoeIL$1KcQ
Andrew,Brown,1992-09-03,andrew.brown@bmail.net,In a domestic partnership,Male,a$REmPKsO0E%$
Audrey,Morales,1990-10-29,audrey.morales@rmail.com,Single,Female,GT7eKjjqn8sW7V5
Benjamin,Cook,1978-08-13,benjamin.cook@ymail.org,Engaged,Male,s3WkNtZ^
Elizabeth,Lewis,2001-11-13,elizabeth.lewis@ymail.org,Separated,Female,3yNkwfbc758NEAC
Mason,King,1993-05-01,mason.king@imail.org,In a civil partnership,Male,OgXu8#1*9Hf%
Daniel,Clark,1994-10-25,daniel.clark@dmail.com,Divorced,Male,zq^^4^SCGPkS8
Carter,Kelly,2001-07-11,carter.kelly@vmail.net,In a civil partnership,Male,A9Hn^cu&tGCa
Addison,Stewart,1991-11-26,addison.stewart@omail.org,Divorced,Female,WWCsdyqqs
Paisley,Smith,1988-03-07,paisley.smith@fmail.com,Separated,Female,Td5TZYL7&5rv
Anthony,Young,1987-02-08,anthony.young@mmail.net,Engaged,Male,6Ue%mDpqCQ0Z1MP
David,Edwards,1990-01-29,david.edwards@wmail.net,In an open relationship,Male,SDthL5teF4q%#
Avery,Ortiz,1996-12-14,avery.ortiz@mmail.net,It is complicated,Female,KDNl3Ppu1cT&V
Madison,Roberts,1991-06-29,madison.roberts@kmail.net,It is complicated,Female,Ve$J$p%^I
Joshua,Adams,1985-01-19,joshua.adams@rmail.org,Widowed,Male,#WdRLZBwyx
Riley,Moore,2001-07-01,riley.moore@mmail.net,Single,Female,39G**Zb6^L18h
Hunter,Sanchez,1989-05-07,hunter.sanchez@nmail.com,In an open relationship,Male,t$VL7bA%GYLqM$
Sofia,Wright,1984-08-10,sofia.wright@smail.com,Married,Female,S$kJw2GH
Landon,Baker,1999-05-06,landon.baker@ymail.org,In a civil partnership,Male,0zsb#khiNc
Ethan,Richardson,1976-09-16,ethan.richardson@pmail.com,Divorced,Male,%lBPiXUZ
Jayden,Reed,1984-09-06,jayden.reed@pmail.net,Single,Male,OfzLVnn&cs2
Oliver,Ramirez,1987-04-21,oliver.ramirez@imail.com,In a civil partnership,Male,eS7IZAxBLQ1D%N
Logan,Anderson,1990-10-09,logan.anderson@ymail.com,Married,Male,tPx%&DcL
Ariana,Powell,1991-11-16,ariana.powell@mmail.net,It is complicated,Female,P$s1WB&l
Grayson,Nelson,1980-06-25,grayson.nelson@umail.net,In a domestic partnership,Male,zY3taZRWhVqKA
Samuel,Diaz,1998-12-20,samuel.diaz@cmail.org,In a civil partnership,Male,xfXyAWRXhG&Pjf4
Scarlett,Myers,1997-06-25,scarlett.myers@ymail.net,Married,Female,WDS7^rf1bRs
Natalie,Harris,1986-01-25,natalie.harris@qmail.com,Divorced,Female,$D1LSmtL
Emily,Campbell,1995-07-14,emily.campbell@hmail.net,Divorced,Female,53AMMNiKr4
Matthew,Gomez,1995-06-11,matthew.gomez@umail.com,It is complicated,Male,EZ49croVtBbx
Hannah,Price,1999-09-02,hannah.price@nmail.com,Engaged,Female,xLNqyC*q8JEL^$
Lily,Barnes,1976-03-14,lily.barnes@kmail.org,In a civil partnership,Female,ONWUBeGC6RFI
Liam,Wood,1983-04-11,liam.wood@amail.org,In a domestic partnership,Male,F%gr%Cs^$^
Ellie,Rivera,1985-09-28,ellie.rivera@imail.net,In a domestic partnership,Female,ev&4J9e1hUoB^K7
Emma,Flores,1991-10-21,emma.flores@vmail.com,Separated,Female,nYSWbn*^E8d6Skt
Victoria,Green,1995-07-01,victoria.green@email.com,Widowed,Female,a%80YQ^Of$Z
Brooklyn,Davis,2002-07-28,brooklyn.davis@amail.net,In an open relationship,Female,kJ$3$3z&Vzp
Mia,Bailey,1997-10-21,mia.bailey@wmail.net,Married,Female,bzxwxu1N0^J95
Amelia,Johnson,1994-04-24,amelia.johnson@vmail.org,Separated,Female,#rmNIJndI
Jack,Carter,1998-11-05,jack.carter@amail.net,Widowed,Male,AVEJ51LcaE
Wyatt,Jenkins,1998-05-10,wyatt.jenkins@pmail.org,Married,Male,7N%7Kvow
Zoey,Evans,1999-03-23,zoey.evans@ymail.org,Separated,Female,6ooirW%yde6t
Levi,Murphy,1991-08-19,levi.murphy@fmail.net,Divorced,Male,z5cRNfCU1wJR7
Sophia,Sullivan,1979-09-06,sophia.sullivan@omail.org,Separated,Female,C7FTS3teeP6Hb
Charles,Mitchell,1979-07-12,charles.mitchell@smail.org,In a domestic partnership,Male,wKzUxOl#Q#k
Alexa,James,1979-01-22,alexa.james@jmail.org,Widowed,Female,SsFGUzSdo#^sf%X
Ava,Williams,1994-07-08,ava.williams@tmail.com,In a civil partnership,Female,zPY6tUwMC
Claire,Hall,1978-05-26,claire.hall@wmail.com,Married,Female,mCkE0RRIj
Jacob,Thompson,1982-07-23,jacob.thompson@qmail.com,In an open relationship,Male,bTNjOOtASZGdka
Grace,Jackson,2002-06-25,grace.jackson@jmail.com,In an open relationship,Female,wXO7p#f1pYen2S
Abigail,Jones,1985-11-16,abigail.jones@umail.org,In an open relationship,Female,85SpcKQG#e
Savannah,Taylor,1989-04-19,savannah.taylor@pmail.com,Married,Female,i3VtHu%*tjqb#I
Isaac,Ross,1997-10-09,isaac.ross@omail.net,It is complicated,Male,IBXRH$75gEC%g7Y
Layla,Torres,1995-08-16,layla.torres@email.org,Single,Female,qpd5XApYqh&hSvq
Caleb,Hernandez,1979-05-23,caleb.hernandez@tmail.com,Widowed,Male,E1aZny#dnC
Jonathan,Reyes,1975-03-27,jonathan.reyes@ymail.net,In a domestic partnership,Male,QJIVJzmBsqitOI
Sebastian,Cruz,1979-06-30,sebastian.cruz@ymail.net,Married,Male,LSFDSFSpl
James,Bennett,1978-01-12,james.bennett@dmail.org,Divorced,Male,1LyhxsxOjZ
Camila,Russell,1979-07-02,camila.russell@gmail.com,Divorced,Female,d1^ILPaaJD9
Jackson,Lee,1987-08-17,jackson.lee@imail.net,In an open relationship,Male,yjj71Hi&$bfAH
Jaxon,Martinez,1980-03-23,jaxon.martinez@vmail.net,Engaged,Male,4bIIuJJ2
William,Perry,1979-09-29,william.perry@rmail.net,Separated,Male,tSw&GqdN
Isabella,Butler,1992-08-08,isabella.butler@omail.org,Single,Female,L4riCdPv5EWuc
Evelyn,Gray,2002-08-01,evelyn.gray@dmail.net,Separated,Female,FAu^nnU2F6*1fwE
Nathan,Gutierrez,2002-04-25,nathan.gutierrez@kmail.com,Divorced,Male,%97ytj&OOo
Aubrey,Robinson,1979-04-04,aubrey.robinson@mmail.com,In a civil partnership,Female,Rb1rg&ZfhiWRbX*
Dylan,Walker,1983-08-01,dylan.walker@bmail.org,It is complicated,Male,1W*S32fwvJfI*
Ella,Rodriguez,1998-10-27,ella.rodriguez@pmail.net,It is complicated,Female,limanK5ITLEZTM1
Michael,White,1994-10-06,michael.white@amail.org,In a civil partnership,Male,VYCjjMX1yiM
Luke,Fisher,1978-05-06,luke.fisher@mmail.com,Engaged,Male,O^qmMH*D10I0
Skylar,Martin,1983-09-16,skylar.martin@bmail.net,Single,Female,SrV%6N5mfPhd
Anna,Garcia,1985-01-05,anna.garcia@omail.net,It is complicated,Female,&3kbDZwTYZ0
\.

INSERT INTO users
VALUES ('Andrii', 'Orap', '12-12-2001', 'a', 'Single', 'Male', 'a');
INSERT INTO users
VALUES ('Nazarii', 'Denha', '10-10-2002', 'b', 'Single', 'Male', 'b');
INSERT INTO users
VALUES ('Maxym', 'Zub', '10-10-2002', 'c', 'Single', 'Male', 'c');
INSERT INTO users
VALUES ('Test', 'Testovich', '01-01-2000', 'd', 'Single', 'Male', 'd', 5);

INSERT INTO locations(country, city) VALUES ('Poland', 'Krakow');
INSERT INTO locations(country, city) VALUES ('Ukraine', 'Kremenchuk');

INSERT INTO facilities(facility_name, facility_location, facility_type) VALUES ('Jagiellonian University', 1, 'University');
INSERT INTO facilities(facility_name, facility_location, facility_type) VALUES ('Lyceum Polit', 2, 'School');
INSERT INTO user_facilities (user_id, facility_id, date_from, description) VALUES (1, 1, '2019-10-1', 'student');
INSERT INTO user_facilities (user_id, facility_id, date_from, description) VALUES (2, 1, '2019-10-1', 'student');
INSERT INTO user_facilities (user_id, facility_id, date_from, description) VALUES (3, 1, '2019-10-1', 'student');

/*INSERT INTO friendship VALUES (1, 2);
INSERT INTO friendship VALUES (1, 2);
INSERT INTO friendship VALUES (2, 1);

INSERT INTO  friend_request VALUES (1, 2);
INSERT INTO friend_request VALUES (1, 2);

INSERT INTO friend_request VALUES (2, 3);
INSERT INTO friend_request VALUES (2, 3);
INSERT INTO friend_request VALUES (3, 2);
INSERT INTO friend_request VALUES (3, 2);
INSERT INTO friend_request VALUES (3, 2);
INSERT INTO friend_request VALUES (3, 2);
INSERT INTO friend_request VALUES (3, 2);

INSERT INTO friend_request VALUES (1, 3);
INSERT INTO friend_request VALUES (1, 3);
INSERT INTO friend_request VALUES (1, 3);
INSERT INTO friend_request VALUES (1, 3);

SELECT * FROM friend_request;
SELECT * FROM friendship;*/
--SELECT * FROM get_user_friend(1);
--SELECT * FROM messages;

--SELECT * FROM get_refactored_all_posts;