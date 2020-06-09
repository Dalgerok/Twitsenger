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
        INSERT INTO friendship VALUES (NEW.friend2, NEW.friend1);
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
\.

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
COPY friendship (friend1, friend2) FROM stdin(FORMAT CSV);
85,7
29,33
41,52
5,55
24,91
86,69
12,40
93,69
62,11
100,15
38,40
54,9
35,27
55,70
38,41
61,34
82,75
72,40
70,57
16,62
71,14
2,37
62,57
50,68
35,93
15,61
35,70
6,71
93,63
70,26
85,31
30,89
86,81
32,40
26,64
52,38
48,79
9,74
73,33
65,11
9,63
22,36
99,74
62,6
30,15
19,12
26,41
40,4
20,80
65,34
18,30
47,32
99,51
37,100
30,36
78,45
79,27
31,40
70,37
62,15
93,1
65,51
82,72
71,19
55,14
66,95
54,35
38,96
35,18
38,35
58,84
16,51
58,89
95,53
85,60
44,12
26,13
3,22
70,39
15,50
45,2
80,42
47,95
70,92
81,31
19,98
3,7
8,18
78,4
54,65
93,48
84,89
73,77
86,93
2,95
53,88
83,28
60,88
99,24
65,13
100,49
78,93
79,5
12,53
72,90
46,1
93,82
4,37
19,68
71,2
90,78
28,46
11,40
40,16
28,76
52,28
87,72
35,51
52,6
61,56
13,86
94,76
87,16
58,70
62,46
7,73
72,13
9,13
28,47
81,8
28,62
55,65
56,28
39,77
19,87
97,74
33,24
62,22
39,93
41,17
28,14
43,68
15,78
79,78
48,2
15,37
14,11
67,51
57,39
95,62
4,11
22,50
3,30
17,22
44,54
72,50
40,21
58,75
20,42
13,46
57,49
90,55
26,78
2,87
37,17
34,13
38,86
82,25
39,10
39,64
33,38
97,8
1,79
57,55
37,97
4,10
82,39
18,75
37,18
79,80
52,57
66,12
52,44
19,50
10,68
93,70
71,77
91,49
44,92
79,49
9,35
27,82
8,33
57,37
71,65
84,52
15,48
87,4
15,81
8,27
92,67
94,16
25,78
67,89
59,13
6,82
29,82
67,32
15,14
99,85
17,74
6,24
47,14
92,93
83,56
79,99
84,97
70,49
73,93
22,59
73,27
29,50
83,58
78,53
59,26
6,29
95,38
30,57
77,21
34,82
28,27
42,43
93,7
33,61
72,59
24,30
21,36
49,55
98,38
33,62
100,29
80,22
61,86
91,17
7,27
83,48
10,89
100,82
83,16
10,22
91,97
58,80
11,5
59,90
50,82
55,92
1,70
68,55
86,17
85,39
16,23
70,88
79,44
92,82
4,94
20,51
98,1
81,21
36,65
92,5
59,52
5,63
27,4
74,93
87,97
81,79
70,76
63,4
95,57
9,69
33,49
21,71
55,47
43,82
18,40
69,77
48,25
51,48
33,18
84,61
5,50
65,78
72,53
61,90
23,28
51,74
27,90
32,3
4,68
38,57
60,43
87,38
65,99
8,55
91,78
72,18
54,55
3,85
83,15
69,67
29,99
35,53
35,20
95,23
94,14
11,51
4,59
56,6
35,77
62,41
7,31
19,77
7,67
90,41
95,71
17,19
91,32
65,47
78,10
77,74
77,80
100,70
14,86
37,35
7,19
62,51
6,33
43,61
3,58
5,31
89,39
36,63
28,31
69,33
63,27
73,45
21,32
53,19
93,47
36,61
5,20
7,97
81,32
89,71
61,22
61,55
42,39
8,86
20,17
23,21
22,29
8,61
92,50
70,60
7,83
89,43
12,83
73,8
15,27
77,72
93,87
60,34
24,61
91,94
42,58
9,86
98,58
47,60
60,51
83,21
28,84
91,96
20,65
79,46
41,93
9,21
54,19
52,13
2,58
58,57
91,54
1,99
82,60
62,59
67,86
9,7
97,95
25,97
65,14
1,29
3,1
30,35
54,75
19,13
60,64
29,71
77,43
38,100
31,58
80,49
18,7
54,39
18,94
6,84
79,93
17,79
43,73
17,72
81,61
45,85
85,44
41,22
52,8
65,12
88,45
12,10
64,83
53,16
54,51
87,59
3,59
26,77
72,6
48,4
35,12
94,92
71,13
8,12
42,37
22,7
100,8
71,41
61,98
80,83
41,59
43,69
51,75
1,89
16,6
82,70
46,6
38,76
21,64
12,37
34,3
67,18
94,47
85,16
18,5
46,89
57,33
84,63
3,11
72,25
12,84
50,9
9,67
52,33
40,84
60,25
7,70
65,68
58,97
10,98
28,33
14,100
70,13
23,1
78,64
16,28
53,75
63,85
53,98
67,55
59,32
68,56
47,18
37,66
53,23
47,57
32,18
27,43
80,7
26,17
25,61
37,77
18,17
97,2
19,66
27,26
7,72
52,67
19,31
26,58
92,40
33,13
46,25
70,78
51,57
32,34
1,50
68,7
33,21
34,18
68,30
34,72
86,39
37,63
90,47
40,30
53,2
69,55
91,60
74,32
74,6
75,43
90,92
75,37
92,81
75,25
82,32
79,19
82,24
95,4
57,16
44,98
89,16
50,31
21,61
49,32
61,23
88,97
68,8
52,11
74,16
43,22
32,38
16,80
92,33
80,75
22,53
70,24
37,25
90,66
8,87
35,89
60,65
94,15
49,43
66,61
53,87
54,64
38,56
57,65
87,91
69,56
29,47
60,31
95,11
44,81
15,63
31,12
32,29
9,6
52,63
74,35
67,45
14,90
89,13
62,79
67,65
48,87
39,11
33,47
51,29
8,13
68,59
80,87
80,6
94,95
41,97
4,76
6,42
45,37
47,20
64,27
82,54
95,82
82,99
24,22
59,15
16,38
91,61
81,17
83,57
66,86
72,9
47,96
15,35
23,13
21,10
43,71
96,57
48,41
56,15
2,74
42,87
73,35
3,99
71,69
79,32
81,47
64,96
48,81
10,57
83,95
31,83
88,58
98,82
21,47
32,4
9,83
76,68
1,13
20,95
64,67
52,26
63,64
98,88
38,37
37,47
79,23
11,50
39,2
29,21
90,89
30,95
94,61
77,16
84,27
16,21
16,15
46,67
76,39
22,56
5,70
27,49
61,49
43,29
28,66
80,100
63,70
84,38
5,60
75,61
34,80
33,67
42,2
92,62
85,13
52,71
25,41
66,25
38,97
68,53
50,47
8,91
17,73
74,4
91,68
86,78
45,33
42,100
28,53
28,20
73,63
100,27
47,61
28,93
96,75
79,45
74,67
82,55
89,54
64,95
65,30
16,22
66,23
47,91
21,2
43,7
69,28
81,43
27,38
91,79
30,70
15,13
95,13
75,36
91,90
17,42
6,51
78,81
90,17
47,92
96,5
84,100
17,56
95,17
61,77
77,33
63,40
92,8
11,60
77,88
13,99
69,38
82,1
95,24
43,34
75,7
84,79
35,97
69,27
45,91
29,34
65,87
32,22
32,28
70,17
43,39
80,64
64,92
44,77
3,29
75,11
45,89
99,19
19,11
7,1
24,53
9,26
53,94
87,55
89,53
24,41
76,2
97,42
6,76
7,99
3,95
61,100
9,27
28,80
64,52
58,49
4,41
17,67
79,24
98,29
89,92
69,63
58,48
80,95
81,67
80,88
28,18
8,29
47,51
98,68
21,66
91,99
33,60
36,91
66,8
8,77
88,91
56,3
83,18
25,81
12,7
88,34
3,93
75,28
8,30
37,82
59,86
24,26
91,58
96,3
56,46
78,62
26,60
18,57
78,35
57,87
44,80
40,86
8,36
26,68
3,76
76,5
34,99
6,34
89,9
50,23
98,28
91,29
24,52
37,87
47,63
94,38
72,91
21,91
45,46
40,25
94,22
64,32
12,54
61,65
56,4
65,4
23,40
51,90
11,45
78,29
61,5
36,70
30,2
7,78
94,43
79,51
36,13
21,82
41,6
98,63
29,27
58,87
62,23
97,46
33,25
25,39
68,11
30,80
80,36
83,72
94,56
94,45
91,65
39,60
59,96
14,10
31,32
6,75
34,26
47,53
15,29
32,13
74,8
92,53
92,26
31,55
98,23
53,40
54,79
64,31
40,41
100,77
21,34
38,5
94,31
57,67
8,11
43,66
43,63
43,59
23,36
60,69
35,87
31,76
40,39
74,31
12,95
87,15
53,99
95,90
80,52
8,20
69,34
66,94
91,84
82,42
34,100
81,91
6,90
71,54
68,83
42,63
95,45
90,33
65,23
68,25
19,26
57,53
32,75
96,24
85,83
93,52
100,41
56,59
4,80
97,33
23,55
82,3
62,71
15,10
82,46
78,61
73,98
68,93
30,79
44,76
55,73
31,42
82,89
91,95
59,94
68,100
93,20
65,46
39,50
57,8
18,63
83,34
54,32
96,13
67,68
1,91
86,43
47,49
34,92
53,29
28,100
27,68
42,72
46,33
27,78
81,87
49,90
51,82
12,56
53,86
55,97
89,68
84,98
61,7
49,12
96,99
39,8
71,82
24,55
100,32
9,46
29,79
100,12
79,70
15,26
63,91
59,10
20,46
50,93
6,93
66,22
26,37
71,8
52,36
49,26
24,88
28,79
37,23
22,57
22,25
68,12
56,51
15,39
39,91
66,26
5,37
8,3
32,92
59,77
90,1
99,41
11,90
3,80
18,97
97,96
20,82
93,36
86,22
10,67
42,19
8,44
75,45
10,35
64,1
64,8
53,67
7,100
71,79
13,67
56,58
71,100
10,16
58,7
30,98
84,21
67,19
60,58
47,69
39,28
12,52
23,63
47,88
70,62
92,45
2,46
45,63
100,6
5,2
70,15
3,92
69,70
90,29
55,99
58,22
48,13
81,10
75,64
14,18
79,90
50,64
36,38
24,60
44,26
26,4
20,59
66,88
56,64
1,63
59,99
33,51
54,59
9,49
66,71
91,52
38,78
45,39
52,2
62,53
42,73
41,69
13,94
35,95
83,29
35,39
46,69
81,96
57,40
42,88
40,81
86,20
21,96
27,57
35,45
12,6
76,37
24,46
72,93
89,73
31,37
86,3
18,74
91,35
12,36
96,85
2,3
7,25
87,27
25,98
61,30
32,77
30,17
16,66
25,47
75,90
33,83
41,70
78,100
17,92
13,98
61,73
76,98
24,35
65,32
86,85
74,87
28,72
64,59
84,77
94,6
64,13
8,40
74,19
87,6
23,99
73,11
89,29
73,87
91,11
34,39
54,2
71,42
65,84
90,21
9,84
16,71
43,52
49,72
66,9
61,16
97,65
42,57
53,73
68,1
15,1
86,79
84,64
6,70
32,87
100,83
32,58
28,2
9,30
89,94
45,36
54,5
56,54
16,2
82,84
6,3
27,48
26,18
73,94
18,59
1,56
8,98
2,47
76,1
92,80
34,46
66,99
47,27
88,26
68,24
14,36
61,57
47,43
77,96
11,38
18,42
47,67
23,22
59,51
18,13
35,16
90,98
90,24
77,9
93,22
87,21
67,12
27,96
39,41
62,87
62,39
99,39
4,29
68,75
94,28
\.
SELECT * FROM friendship;