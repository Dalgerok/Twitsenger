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
Maksym,Zub,2002-08-13,max,Single,Male,max
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
COPY friend_request (from_whom, to_whom) FROM STDIN (FORMAT CSV);
81,74
48,72
5,8
14,92
91,93
17,28
32,16
14,79
80,76
95,48
86,75
87,60
95,18
61,96
56,72
60,75
67,54
44,14
36,90
41,2
25,19
43,23
19,57
14,7
96,45
43,19
31,92
11,28
47,62
97,24
3,71
59,14
28,26
93,46
37,74
13,37
10,72
72,64
73,22
40,7
56,82
76,91
17,14
19,1
34,98
25,91
27,72
4,62
35,8
64,100
85,33
97,63
47,31
65,45
36,89
42,16
99,87
6,15
23,90
6,40
54,86
100,44
99,86
12,28
57,68
100,53
38,77
7,48
17,5
44,46
70,33
17,53
12,42
50,53
38,21
79,33
81,98
89,42
92,97
57,21
50,40
7,52
66,82
80,53
88,87
75,26
45,3
94,21
82,11
94,77
54,41
57,85
59,81
30,25
5,41
72,14
50,38
3,84
99,64
56,98
66,41
63,55
31,1
11,10
14,98
55,52
4,57
85,91
35,21
60,48
21,72
91,7
44,62
54,30
41,82
84,20
88,76
10,31
16,73
13,54
57,98
15,11
76,82
97,11
55,100
81,46
4,55
18,98
2,90
98,36
3,62
71,32
96,4
84,48
33,10
92,4
19,38
84,44
57,35
40,85
7,64
68,39
10,40
31,14
31,49
33,88
13,63
29,54
64,44
56,41
1,94
43,99
38,22
11,85
20,68
46,36
61,12
70,9
59,89
23,82
38,93
20,49
36,82
52,15
87,100
26,76
13,30
52,10
62,7
34,91
18,78
33,81
24,38
33,93
31,79
13,24
52,60
5,53
1,26
89,66
14,70
64,35
48,59
40,42
1,37
8,80
75,49
56,42
38,43
96,53
6,27
15,42
76,57
78,20
30,14
98,95
35,69
99,47
19,35
31,38
25,53
27,39
26,22
49,85
30,90
16,78
29,46
57,90
32,76
41,76
67,41
93,13
76,22
78,5
100,97
17,36
50,60
70,81
58,92
3,15
58,15
18,38
57,75
16,49
30,29
92,42
21,14
93,51
71,75
74,34
46,72
31,20
41,53
58,14
90,5
32,50
97,52
74,72
31,82
4,91
20,96
61,45
54,92
12,77
53,79
9,17
90,37
37,58
93,67
58,41
10,82
25,52
82,88
42,46
64,40
29,16
97,76
67,35
26,95
12,1
73,12
43,57
94,88
43,98
96,44
64,77
94,39
62,93
53,10
63,57
63,92
76,11
24,5
72,79
85,53
85,90
47,16
50,95
75,21
52,40
23,92
49,15
71,55
94,65
94,63
72,54
16,43
24,66
29,41
22,8
97,31
9,45
51,23
66,3
56,47
26,6
21,25
15,34
66,5
71,4
71,64
92,65
44,59
65,74
59,74
44,57
91,22
30,91
56,35
75,8
5,94
59,25
32,8
23,91
17,50
58,79
22,9
85,25
87,31
2,1
10,51
24,86
58,73
63,39
47,74
83,47
38,89
92,77
58,10
32,25
73,40
11,12
50,87
94,57
28,61
17,55
72,76
92,49
54,74
15,4
99,49
84,80
88,71
93,88
15,17
84,93
68,13
25,80
70,94
91,92
67,26
86,80
100,99
36,58
2,36
52,30
5,98
26,99
85,23
1,58
93,99
4,86
61,51
26,33
88,75
35,28
52,73
5,80
78,73
20,87
7,20
68,79
69,98
66,84
89,91
93,98
2,78
45,68
60,59
59,69
97,48
89,65
93,21
57,25
54,60
20,22
17,71
97,23
46,4
80,78
62,14
93,45
96,63
3,12
85,36
96,62
94,83
89,21
24,72
61,37
57,31
46,77
36,49
27,99
9,75
40,44
79,61
71,94
66,58
17,87
26,51
45,20
99,36
68,99
62,18
70,50
78,41
95,52
42,66
12,18
91,86
56,75
57,82
6,45
3,100
14,27
97,39
78,34
68,16
39,72
6,1
63,82
78,6
69,11
3,55
68,81
64,81
23,88
84,87
48,53
22,33
57,92
26,53
22,89
85,48
78,92
63,31
92,74
52,53
60,84
85,41
76,75
85,14
20,88
31,84
22,72
76,35
26,23
95,6
14,22
45,14
14,46
43,46
6,63
5,74
48,3
51,64
60,49
37,68
65,6
25,54
80,81
40,100
88,1
57,59
99,80
47,12
43,95
52,19
77,67
21,73
42,59
97,99
38,64
97,98
41,7
11,100
39,88
97,75
94,12
11,42
49,84
70,86
73,25
70,25
37,59
44,50
92,29
75,79
47,13
\.
COPY posts (user_id, post_text, reposted_from) from STDIN (FORMAT CSV);
3,sit aliqua. non in consequat. nisi exercitation cillum magna veniam anim et ea laborum. officia minim Ut occaecat fugiat Lorem ex labore ut enim amet elit Duis laboris mollit eu sint,
78,aute eiusmod enim veniam labore incididunt anim exercitation cupidatat eu magna qui non Excepteur adipiscing sint id cillum aliquip Duis occaecat ad et ut,
28,nostrud enim esse incididunt voluptate ullamco laboris aliquip ex ut magna Duis Excepteur dolore anim minim amet culpa tempor adipiscing consectetur irure officia pariatur. sunt fugiat ea dolor consequat. sed,
50,dolor sint id consectetur nisi ut labore eiusmod nulla in,
8,nulla veniam Lorem commodo aute irure ad ullamco in adipiscing anim voluptate id,
64,reprehenderit eiusmod quis Ut aliquip in ullamco voluptate non in irure ad fugiat,
25,officia Lorem adipiscing fugiat Duis minim ipsum nostrud cillum in anim ad velit reprehenderit ex laboris ut pariatur. consequat. non dolor esse sunt est proident dolore aute exercitation voluptate tempor sit qui ut sint,
49,irure ex voluptate laboris pariatur. aute et laborum. Ut Duis occaecat Lorem qui sit sed dolore ut sunt eu est in labore ullamco anim consequat. mollit sint reprehenderit elit id dolor commodo adipiscing incididunt fugiat esse non amet ut,
13,in dolore fugiat culpa ex in dolor reprehenderit laboris exercitation ut eu,
89,eu nulla sit minim Duis sint mollit cillum adipiscing sed consectetur elit,
86,id dolor non est in veniam aliquip culpa eiusmod esse incididunt nisi aute cillum labore Lorem magna sunt laborum. voluptate reprehenderit mollit nulla dolore sit in exercitation,4
56,quis amet ad voluptate commodo ullamco elit dolore nisi dolore id velit proident sint nostrud occaecat dolor laborum. esse aliqua. do sed fugiat et qui,5
38,sunt aliqua. dolor commodo Lorem irure consequat. eu ut velit ea veniam amet Ut,
7,proident commodo elit et ea culpa ut magna,
36,minim ex occaecat Lorem sunt aute exercitation tempor dolore in in veniam ad cillum,
38,dolor Ut est nulla eu ea ad Lorem veniam cupidatat nostrud ut culpa in ex,
16,sint ea amet in veniam culpa in cupidatat sunt dolor labore in et aliquip quis ex dolore deserunt velit ipsum aliqua. id,
28,exercitation cupidatat sint ex consequat. ad reprehenderit enim,
64,deserunt pariatur. cillum labore sed do commodo Excepteur Ut ut dolore non est incididunt mollit qui veniam in occaecat officia velit nostrud ea reprehenderit irure ex aliquip ad consequat. Duis in Lorem laboris tempor magna proident enim,
93,sunt qui dolore velit laboris magna Ut pariatur. deserunt proident dolor eu laborum. in ea tempor est reprehenderit dolor,10
51,ex veniam consequat. eiusmod elit culpa est nisi cupidatat voluptate minim non anim eu exercitation esse officia id Ut laboris dolore laborum. in incididunt sed dolor ea ullamco deserunt irure occaecat et mollit Duis quis reprehenderit ut in,
89,do id elit tempor commodo minim nulla sed occaecat irure Lorem sunt magna cillum Ut ut,6
22,est voluptate eiusmod pariatur. in nisi nostrud sunt veniam ullamco et,
99,aliquip ad ut dolor cillum laborum. qui aute consectetur commodo sed exercitation dolore quis id Lorem sit dolor occaecat elit labore amet culpa tempor proident ea eu in cupidatat incididunt laboris adipiscing reprehenderit,23
69,veniam adipiscing Excepteur non dolore in cupidatat id Lorem ex dolor eiusmod mollit labore Duis deserunt proident est,12
82,dolore consequat. nulla ut in ad exercitation aliquip nisi et Duis sint sit,
7,ullamco dolor mollit enim officia Ut ex deserunt culpa voluptate irure ea amet exercitation dolore cillum velit non sint minim cupidatat pariatur. eiusmod dolore in elit commodo est nulla reprehenderit tempor eu nisi id fugiat occaecat,22
22,esse laborum. nisi ipsum magna dolore commodo officia laboris Excepteur Ut ut proident deserunt sunt et aliqua. occaecat in consequat. do adipiscing ad incididunt sed culpa dolor non ut,
42,esse pariatur. laboris aliquip laborum. magna ut eu et dolor consequat. consectetur cillum irure do occaecat sunt dolore labore Lorem ullamco cupidatat in qui amet sint ex ea mollit nulla proident nostrud incididunt,28
3,sit ipsum Excepteur fugiat sint,24
22,ut sit ut amet fugiat ea ipsum occaecat incididunt irure consectetur laboris pariatur. id enim quis in voluptate,5
20,proident nisi velit ea,18
47,voluptate officia est dolor Lorem Ut ipsum commodo ut aute quis in ad laboris nostrud,3
29,sed consectetur exercitation tempor in dolor ex mollit ea voluptate veniam labore incididunt Lorem deserunt dolore aute quis et,
99,dolor deserunt veniam sit consectetur minim aliquip commodo sed adipiscing culpa tempor ea qui consequat. anim esse officia dolor aliqua. eu Excepteur nulla labore id Duis voluptate elit Lorem pariatur. est amet proident ipsum reprehenderit in,15
9,dolor eu sed sunt culpa tempor dolor aliqua. reprehenderit cillum anim Ut ut cupidatat proident quis occaecat adipiscing laboris Lorem commodo Duis in fugiat mollit enim sit nostrud ex ipsum esse do nulla,
37,culpa voluptate quis aliquip Excepteur dolor,
92,veniam cupidatat elit officia occaecat incididunt laborum. tempor pariatur. aliquip magna ex ut exercitation consectetur ea non minim culpa ullamco reprehenderit eu labore nisi aliqua.,
76,officia tempor ut incididunt adipiscing voluptate dolore ad ullamco nulla non in sint et esse,
98,est culpa tempor ipsum Duis incididunt laborum. fugiat amet magna esse et cupidatat aliqua. ex in nostrud sed quis enim veniam,10
76,quis Ut velit ad in pariatur. ipsum dolor Duis ullamco ut enim cillum anim reprehenderit esse,
72,ipsum incididunt dolor ullamco deserunt dolore anim nulla in aliquip voluptate sit Excepteur consectetur ut aute sunt elit tempor pariatur. qui laborum. in laboris veniam exercitation culpa,
6,qui aute in dolor sed eu enim laboris dolor,
56,ea dolore quis mollit magna Ut cupidatat id est nulla sed reprehenderit fugiat consequat. consectetur,
36,cillum sed adipiscing sit dolore dolor id consectetur velit ipsum consequat. fugiat incididunt culpa aute occaecat aliqua. mollit commodo ea irure aliquip nostrud,
5,in sunt in ullamco culpa anim incididunt dolor laboris Duis non amet ad veniam nisi,
67,voluptate mollit sunt ipsum eiusmod velit anim nisi minim,
32,in irure tempor laboris est ad cupidatat ut occaecat dolore adipiscing sint nisi ut ea voluptate culpa Duis nulla do incididunt consequat. ex Excepteur ullamco magna enim ipsum eiusmod in id minim nostrud eu dolore sit exercitation veniam,
96,sunt enim elit ipsum tempor magna velit irure,
13,nostrud aliqua. sint dolore id incididunt est reprehenderit eiusmod in irure ex ea ad culpa magna consectetur commodo tempor mollit in eu do fugiat cillum deserunt ipsum Excepteur consequat. anim,10
9,dolor in sunt deserunt nisi labore ut Excepteur et ad amet esse ipsum cupidatat commodo velit irure tempor eiusmod est laborum. veniam id occaecat aliqua. culpa exercitation do voluptate in Duis enim sit dolor proident sint,
32,Excepteur mollit in ex amet sint occaecat deserunt non aute dolor laboris enim esse dolor nulla Ut id eiusmod,21
99,reprehenderit veniam Duis fugiat adipiscing Ut pariatur. irure ut amet minim anim dolore proident eiusmod aliquip sint,15
97,nulla elit aliquip deserunt aliqua. sit anim laborum. proident sint id in Ut enim ut labore magna veniam dolor eiusmod dolor officia Excepteur ad incididunt exercitation ipsum in fugiat,
9,ullamco sit nostrud dolore ea consequat. aute veniam pariatur. ipsum anim officia cupidatat enim et non dolor nulla incididunt qui commodo labore sed sunt quis est aliqua. ut in magna mollit fugiat aliquip do Duis in occaecat ex laborum. dolore,18
8,ut dolor aute,35
83,aliquip laboris eu magna Excepteur sed Ut,
90,elit ea id mollit minim nulla nisi non dolore cillum in proident nostrud laboris dolore ipsum deserunt ex Duis sed fugiat consequat. reprehenderit ullamco adipiscing commodo do ut culpa qui est veniam quis enim aliqua. esse amet Ut,
31,reprehenderit Duis quis voluptate eiusmod ullamco magna exercitation veniam ut in elit ipsum pariatur. adipiscing laborum. aliqua. ex officia laboris do irure nostrud ut ad tempor dolor Lorem ea,
17,qui consequat. sed adipiscing quis reprehenderit deserunt Lorem sit mollit ullamco velit ut incididunt Duis ut aliquip non aliqua. cillum voluptate,
86,ut fugiat amet veniam anim adipiscing incididunt nisi,
37,esse quis ex amet sed voluptate ipsum nisi dolor ut ea elit eu Duis et,
13,tempor ea sint amet Ut anim culpa sed irure aliqua. cillum velit veniam ad Lorem sit laboris aliquip adipiscing elit exercitation Duis Excepteur et qui proident est in enim dolor in nisi eiusmod id esse,26
79,sed culpa quis sint consequat. ut mollit eiusmod nostrud aliquip amet Duis fugiat esse cupidatat qui velit dolor Lorem voluptate nisi,1
66,cillum incididunt Lorem et sit nostrud non anim consectetur officia eiusmod minim Duis nisi quis amet do eu exercitation dolore esse Excepteur enim in,
90,ex esse reprehenderit ullamco Lorem ut mollit culpa eiusmod laboris Excepteur sit et nostrud cillum magna pariatur. velit anim qui laborum. officia nulla in,
24,adipiscing ullamco cupidatat proident elit amet sed,
11,aliqua. est occaecat reprehenderit ex cupidatat sit Lorem veniam sint eu qui tempor quis nulla ut exercitation esse consequat. in voluptate Excepteur ut sunt non in laboris nisi amet Ut,66
27,culpa sunt in ipsum consequat. in mollit consectetur commodo laborum. qui dolore dolor nisi eu voluptate exercitation ut occaecat quis esse velit in cillum sit magna ea minim et Ut do aliquip fugiat pariatur. dolore id,
62,incididunt ex officia nulla ullamco id culpa amet voluptate Excepteur veniam in et consequat. eu est laboris adipiscing do sit labore sed Duis,45
52,non ea quis do culpa dolore commodo reprehenderit aliqua. nostrud in est in veniam ad cillum laboris minim id proident nulla Excepteur eu magna dolor ut,
84,ea consequat. voluptate aliquip veniam in,39
63,culpa laboris pariatur. nisi quis irure nulla elit Excepteur,
30,Lorem non laboris labore in nulla qui aliqua. dolor nisi quis occaecat deserunt consectetur ut tempor culpa in Excepteur anim mollit irure pariatur. sunt sed laborum. eiusmod do Ut in,
14,minim deserunt Duis veniam mollit reprehenderit nisi nostrud incididunt quis sunt est in in aliquip nulla ex consectetur cillum dolore ullamco amet eu eiusmod esse ut sint magna ad irure exercitation in cupidatat ut fugiat consequat. velit,33
28,labore dolor nisi ad esse cupidatat voluptate in eiusmod reprehenderit ea veniam Excepteur nulla fugiat ullamco adipiscing Ut mollit dolore id ex magna officia nostrud consequat. pariatur. commodo irure eu dolore sed,42
35,ad elit aliquip et cillum deserunt ipsum mollit in pariatur. laborum. veniam Ut dolor Excepteur tempor sit ut occaecat consequat. esse dolor ex sint nisi est ea,
97,eiusmod dolore adipiscing ea laboris voluptate tempor exercitation veniam nostrud Duis Excepteur dolor occaecat qui quis Lorem sit labore officia sunt minim in aute fugiat ut sed,12
52,sunt est quis voluptate laborum. exercitation elit fugiat anim minim eiusmod amet non aliquip in Excepteur ex commodo reprehenderit in cillum velit,
72,tempor irure est elit amet sunt dolore in laboris velit ut voluptate ullamco sint Ut eu aute consectetur enim dolore aliquip ut,
96,officia voluptate sit in ad eiusmod dolore esse id est dolor tempor sed deserunt sunt amet aute ullamco dolor minim Duis consequat. aliquip ea enim,
50,esse voluptate ut labore commodo laborum. id dolore nulla do,25
56,nulla consequat. ullamco ut Duis in dolore Lorem fugiat incididunt eiusmod cupidatat deserunt culpa non occaecat proident ut id elit eu dolore veniam ipsum reprehenderit voluptate sunt qui,83
58,cillum magna proident non incididunt mollit veniam Lorem consectetur velit officia ut ex aliquip eiusmod dolore commodo ipsum enim quis irure dolore aliqua. est pariatur. exercitation amet laboris elit aute adipiscing dolor ea Ut,
37,Ut occaecat amet dolore sed et incididunt sit pariatur. reprehenderit non nisi laborum. dolor laboris dolor ex in ipsum est ullamco in,
28,est non velit laboris Lorem nostrud in officia aliqua. in quis sed Ut ut,
4,Excepteur labore ea do in in aute dolore id anim ut deserunt adipiscing mollit cupidatat in dolor,
1,sunt nisi laborum. quis dolor et elit Ut tempor sit,28
12,deserunt in minim cupidatat elit irure consequat. in,2
41,Duis nisi amet deserunt aute pariatur. aliqua. irure commodo sit dolore proident consequat. veniam sunt nulla et sint minim velit eiusmod ea,
39,id nostrud aliqua. officia commodo aute ut nulla Duis dolor ipsum non proident culpa Excepteur cillum dolor velit deserunt tempor,78
18,quis qui irure voluptate tempor deserunt minim incididunt laborum. aute aliquip ad anim mollit ullamco labore laboris ex nisi,
30,in reprehenderit mollit ad deserunt consequat. occaecat fugiat anim dolore commodo non nulla dolore eu est sint velit laborum. esse nisi tempor elit veniam ut,
51,nostrud esse Excepteur dolor quis sit sint fugiat culpa veniam Duis proident mollit aliqua. amet est laborum. id Lorem pariatur. consectetur nulla et ut,
96,irure laboris id laborum. elit dolor mollit reprehenderit sunt voluptate culpa adipiscing sit,
54,quis nisi consectetur ipsum labore pariatur. veniam dolor tempor ut dolor qui occaecat nulla fugiat sunt ex ullamco adipiscing aliqua. velit,
28,ad officia do ex magna non minim quis dolor ullamco fugiat Ut,
77,Ut officia aliquip ex eiusmod anim exercitation non dolor sint in reprehenderit labore mollit veniam id irure deserunt laboris Duis ut aute cupidatat qui voluptate consequat. elit amet,52
43,elit aute sed cillum sunt fugiat reprehenderit sit in nulla labore laborum. ipsum tempor aliqua. anim dolore id pariatur. minim mollit culpa in commodo nisi non veniam consequat. amet dolore deserunt laboris do enim Ut,
52,id laborum. amet cillum aute nisi voluptate commodo Lorem in est ex sunt ipsum ea,
79,labore commodo anim mollit voluptate pariatur. laboris officia consequat. Duis id culpa ullamco deserunt occaecat et ea magna veniam non sit,70
92,mollit ut dolore in dolor fugiat dolore ullamco cillum ad ea proident laborum. qui incididunt in laboris tempor velit quis id,52
16,sit proident adipiscing laboris veniam Ut velit nostrud ut mollit exercitation nisi Lorem incididunt dolore ut anim eu officia irure sunt voluptate qui Excepteur commodo in sint consequat. in in laborum. cillum ex fugiat est esse culpa,
34,in deserunt consectetur fugiat quis ad ea amet occaecat Ut dolor proident officia minim velit magna dolore Lorem adipiscing ipsum id cupidatat exercitation nostrud esse voluptate sit laborum. do in Duis culpa anim ut est Excepteur irure,
29,eiusmod aliqua. Excepteur anim minim qui consequat. proident Duis consectetur nulla pariatur. dolor nisi occaecat esse do commodo nostrud id ea elit irure in Ut ex cupidatat est sit,
80,ut cupidatat enim,56
15,aliquip quis irure reprehenderit dolore enim minim tempor proident eiusmod in Duis qui aute ullamco cupidatat pariatur. esse in incididunt et mollit sit ad consequat. voluptate consectetur id est sint veniam ut ut officia dolor ea fugiat eu,
65,magna nulla sit aute minim sint in,
86,tempor dolore aliqua. ullamco Duis ut veniam aliquip minim officia consectetur commodo nulla amet occaecat elit adipiscing qui sint pariatur. do sit incididunt anim ut ipsum quis proident magna,25
40,nisi elit ea incididunt qui in ut tempor consectetur occaecat Excepteur dolore veniam dolor,
64,deserunt eiusmod enim magna Excepteur do,
12,laboris exercitation voluptate dolor aute incididunt ut dolore tempor sunt fugiat minim in pariatur. velit id ex nostrud labore esse qui aliquip in eu ut occaecat est Duis culpa aliqua. ad enim,
25,proident cupidatat esse voluptate ipsum et pariatur. sint Duis sunt dolor in anim occaecat irure cillum,33
7,sed do Duis magna enim tempor fugiat exercitation Ut,21
100,in dolor enim mollit labore in Duis velit occaecat Ut dolor dolore ex ipsum consequat. reprehenderit adipiscing nisi dolore id elit ut cillum sunt minim qui,
31,Ut exercitation minim sed ut id mollit sit adipiscing dolore cupidatat non laboris Lorem et ea quis do velit labore Excepteur fugiat amet incididunt laborum. in dolor,
57,cupidatat fugiat irure et sit in magna incididunt Lorem dolor commodo labore Duis eiusmod ut,
15,sed fugiat anim in et ullamco deserunt laborum. esse exercitation mollit in dolor sunt commodo Duis officia consectetur reprehenderit nostrud minim ipsum in ut pariatur. quis id,
69,sint occaecat et aute amet ipsum ea consectetur fugiat veniam culpa do nulla deserunt officia anim irure velit dolor nostrud voluptate id eiusmod laboris cupidatat esse Ut Excepteur magna cillum quis ut ex eu,
52,fugiat labore deserunt ea consequat. culpa nisi enim aliquip magna eu adipiscing laborum. pariatur. Duis Ut velit reprehenderit exercitation est ullamco ut ad voluptate anim sunt do elit officia irure ut consectetur aute ipsum cillum,
97,Duis sint laborum. tempor deserunt occaecat eu officia in culpa sed aute qui incididunt proident consequat. ipsum minim in adipiscing dolor velit in elit fugiat Ut quis id magna ea exercitation laboris,
13,exercitation mollit nulla esse ea ex amet cillum Lorem ullamco anim enim fugiat irure ipsum pariatur. sint in commodo id est,
14,nostrud deserunt labore eu exercitation id do velit pariatur. cillum voluptate sint tempor et Lorem quis aliquip nulla sit Duis ea,
98,aliqua. adipiscing occaecat non sint in anim aliquip est velit labore qui amet fugiat ut exercitation deserunt ea culpa officia,89
59,consequat. ut dolore cupidatat occaecat fugiat aliqua. ut Lorem irure quis Ut elit veniam laboris ipsum,
72,non nostrud officia Duis Lorem occaecat pariatur. deserunt ea commodo nulla adipiscing sint ad cillum proident ut id nisi quis qui aliqua. sed ex aute enim culpa veniam amet irure in,
89,sit dolor sunt labore sint mollit irure nostrud eu tempor amet qui reprehenderit elit incididunt in laboris fugiat Ut minim velit commodo in do veniam ut Excepteur in sed quis cupidatat aliqua. ullamco et magna est,
74,ad nisi enim adipiscing culpa dolor Ut non,
18,consequat. sit laboris Lorem nostrud ipsum officia proident labore enim do,
52,cillum ullamco aute Excepteur pariatur. laborum. consequat. aliqua. cupidatat Lorem consectetur mollit sit adipiscing commodo eu labore in amet velit laboris dolore minim ea,125
33,pariatur. cillum reprehenderit irure fugiat nulla sint est laborum. commodo in eu aliquip sit consectetur officia elit dolor laboris eiusmod dolore in quis ad dolore ullamco magna esse Ut amet labore ipsum Excepteur mollit et,
45,dolore do in Ut aliqua. fugiat non aute eiusmod mollit sint commodo velit ex dolore laborum. quis dolor in incididunt veniam pariatur. magna id elit anim eu ullamco adipiscing minim occaecat tempor ad et,
8,do elit occaecat nostrud amet labore voluptate qui dolor tempor ullamco mollit aliquip minim est veniam deserunt incididunt dolore Excepteur proident quis ut ut in laboris anim,
38,ea ex sed non aute elit eiusmod ullamco ut,
81,Excepteur sed exercitation velit in deserunt est et irure reprehenderit ea voluptate pariatur. incididunt occaecat tempor laboris minim ex dolor Ut esse ipsum sit quis amet cupidatat,64
58,ullamco esse fugiat do reprehenderit nisi ut tempor veniam adipiscing ex laboris in ea,39
38,Excepteur non,132
29,in adipiscing culpa occaecat dolore mollit Ut ullamco Duis,
75,eiusmod occaecat enim in culpa deserunt sed commodo anim labore dolore veniam sit Excepteur ullamco cillum et proident eu id officia sint nostrud ipsum fugiat incididunt ad in,40
44,sit qui magna cupidatat esse ex adipiscing mollit eiusmod id ad in consequat. velit minim dolor fugiat aliquip sint dolore sunt ut sed proident aute amet,
95,sint consectetur ea proident cupidatat Ut dolore magna ipsum occaecat ut id officia aliquip labore enim quis anim in tempor incididunt consequat. deserunt do eiusmod sit laboris nulla Lorem elit Excepteur voluptate veniam sed in,48
20,exercitation adipiscing nostrud cupidatat ut sunt culpa nisi sed,
27,anim exercitation tempor eu Lorem aliquip dolor laboris cupidatat elit amet velit id labore irure ut ipsum adipiscing nisi,
46,veniam Duis culpa incididunt aute occaecat cillum Excepteur dolor officia sed magna dolore est aliquip ex,
89,nisi ut et,58
81,nostrud velit aute id officia,
22,qui reprehenderit exercitation cillum in id pariatur. in nostrud velit,
68,veniam in minim sunt amet,11
6,enim aliqua. velit Duis ipsum ut et id dolor consequat. ullamco ut magna mollit ea Ut sunt cillum est esse in sint voluptate nisi in dolor non irure commodo elit exercitation qui officia ex,
28,sint incididunt cupidatat anim dolor reprehenderit dolore officia aliquip dolor ea eu esse ipsum occaecat Duis veniam exercitation est nostrud enim magna aliqua. velit id Lorem in ex fugiat minim voluptate adipiscing culpa cillum,
31,irure officia ullamco nisi cupidatat dolor laboris non Excepteur Ut exercitation est minim quis reprehenderit ut id ut velit dolore incididunt in ipsum sed elit aliquip in sint magna fugiat sunt sit Duis culpa ex,
62,est dolor esse velit qui aliquip,
35,veniam Lorem fugiat qui laboris laborum. eu elit minim cupidatat ea exercitation sit adipiscing ut,
6,consequat. incididunt ipsum qui Lorem Excepteur reprehenderit mollit tempor culpa dolore laborum. veniam pariatur. quis anim ad,
77,nisi in Excepteur ullamco mollit officia Duis anim velit adipiscing consectetur ipsum veniam esse sit culpa ut fugiat est in,
81,proident sunt sed ex elit exercitation,18
97,in esse eu elit magna Ut ex occaecat sint est Excepteur mollit et ut irure dolor amet proident dolore sed aliqua. incididunt do id nostrud ea officia exercitation voluptate minim Lorem laborum. ullamco,125
97,ut magna quis Lorem proident nisi minim Excepteur dolore ex sunt ad dolor reprehenderit amet Ut ullamco mollit eu,
3,labore velit non incididunt anim id do amet eiusmod reprehenderit magna in dolor ex ea dolore aliqua. cillum ut sed irure ad quis aliquip,136
58,amet mollit pariatur. aliquip adipiscing labore dolore ea eiusmod,
86,labore esse pariatur. dolor nulla magna ut mollit exercitation elit do aliquip nisi quis eu velit proident cillum Duis minim ipsum dolore dolore occaecat incididunt,120
84,labore ullamco et cillum est ea anim elit sint amet minim eu ut,142
92,dolore sunt minim Ut labore sed et amet in ut ea in dolor consequat. ex qui anim voluptate dolor,
40,et consectetur qui dolor,
80,veniam esse id do aliquip officia irure consectetur ipsum dolor anim in nulla enim dolore consequat. mollit ut Excepteur est ad Duis fugiat ea,
92,elit voluptate dolore irure proident id dolore,
28,occaecat in dolore sed deserunt aliquip nulla sint quis voluptate dolore ut irure sunt in nostrud Ut do amet esse Excepteur elit anim laborum. adipiscing velit Duis non id est officia ex Lorem,165
50,in quis non veniam anim eu commodo dolore dolor incididunt ut labore ut enim sit adipiscing et pariatur. ad in Duis sunt sed deserunt tempor ex in,
3,pariatur. dolor sint adipiscing nulla esse minim dolor sit proident in eu voluptate deserunt officia aliqua. non consequat. aliquip Duis fugiat ex nostrud ut et,
74,anim minim dolor adipiscing voluptate enim id elit sit consequat. non eu proident Duis veniam ullamco do ex culpa in cillum Ut,169
71,magna culpa nulla adipiscing amet et pariatur. do quis officia dolor nisi velit occaecat aliquip consectetur laboris enim eu aute ut labore,
11,in qui mollit anim commodo aliquip occaecat Ut pariatur. dolore ullamco veniam consectetur laborum. ad cupidatat enim et eiusmod ut proident deserunt aute id irure magna exercitation adipiscing,
99,magna incididunt non adipiscing aliquip eiusmod cupidatat est ut in qui Ut veniam officia ex irure dolore pariatur. eu,
65,eiusmod proident id dolor reprehenderit commodo dolore enim cupidatat do nostrud fugiat in ex ullamco dolore Duis eu Lorem culpa adipiscing nulla sit est mollit aute ea exercitation veniam non velit consectetur deserunt ut,
32,laborum. pariatur. ad ex deserunt eu aute enim exercitation nostrud tempor aliquip elit sint nulla qui dolor veniam mollit in,
58,officia veniam ut anim voluptate non esse adipiscing id pariatur. Excepteur irure Duis sed quis consectetur culpa Lorem labore commodo ex in sit exercitation velit ea ullamco et aute consequat. sint nisi mollit,168
14,pariatur. qui cupidatat culpa ad elit proident sed dolore tempor laboris incididunt in Excepteur magna nostrud labore anim dolor nisi Ut adipiscing minim ea est do nulla sint in consequat.,
91,nostrud culpa pariatur.,
65,Lorem sunt consequat. ex dolore ea amet irure enim cupidatat consectetur ullamco mollit sit pariatur. exercitation nisi officia do dolor aliqua. incididunt dolore ipsum aute sint tempor sed esse in id ad,99
56,aliquip ad veniam dolor laboris aute reprehenderit officia et in cillum Lorem ex eiusmod ut dolore id Duis do ullamco pariatur. consectetur,
71,consequat. et officia id qui occaecat eiusmod elit ex cillum sint est commodo sunt ad aute magna,
8,Duis irure laborum. sunt ex,180
69,elit ex aute Duis officia dolor culpa nisi,
40,et aliquip Ut aliqua. culpa laboris consequat. exercitation Lorem incididunt ipsum id est irure sunt dolor ut minim tempor veniam consectetur nostrud in officia do cupidatat proident ea sit,
20,in labore nostrud nulla tempor voluptate velit aliqua. fugiat reprehenderit ut est ut laborum. quis elit non ex ipsum Lorem eiusmod eu incididunt irure Excepteur,
43,veniam aliqua. ut Ut voluptate enim fugiat occaecat ut reprehenderit laboris nostrud aute adipiscing culpa Lorem anim cupidatat in amet Excepteur officia exercitation cillum consequat. sit,94
85,enim fugiat elit ullamco,
40,minim aute in incididunt eu ipsum nostrud nulla proident officia dolore non exercitation tempor qui cillum Duis labore Excepteur esse ut in ut amet mollit ex ea nisi sit magna deserunt commodo laboris ullamco ad adipiscing Lorem et,
78,qui aute magna dolor deserunt dolor labore velit est ullamco,125
69,ex consectetur sint nostrud et fugiat culpa velit aliquip ad adipiscing proident ipsum ut aute ut dolore minim laboris Lorem est Ut,
1,qui velit laboris amet minim est ut Excepteur et in ut occaecat eiusmod esse Ut sint nisi,
18,non eiusmod est ex Ut minim in irure dolor labore dolore adipiscing occaecat Duis ut voluptate laboris,31
18,ut pariatur. tempor magna laboris cupidatat id proident ipsum sed labore cillum ea amet occaecat ut incididunt adipiscing aliquip esse reprehenderit est sunt dolor non veniam,
70,occaecat amet ea laboris exercitation nostrud ullamco consequat. sed elit,
38,Lorem laboris dolor voluptate nostrud ipsum occaecat velit cupidatat exercitation consectetur pariatur. ea do aliquip proident minim ex aute Ut nulla Duis ut magna dolore ut sint incididunt est anim cillum sed aliqua. amet in commodo quis labore,
43,tempor sint occaecat magna anim aliqua. ut Lorem do reprehenderit et dolor est irure deserunt laborum. eu cupidatat nulla amet in cillum consequat. quis nostrud Excepteur ullamco aute,
42,ut nulla tempor adipiscing aute ipsum aliquip labore qui esse mollit anim ut Ut eu in dolor do ex dolore consequat. amet,
91,voluptate est cillum aute in aliqua. minim enim officia amet dolore ea magna qui adipiscing laboris veniam in et pariatur. ut tempor sit dolor nostrud velit incididunt nulla cupidatat exercitation commodo consectetur anim ad occaecat in do sunt,
88,nulla officia sint Ut in do laboris est veniam sed Excepteur occaecat voluptate elit Lorem in laborum. proident irure mollit Duis ut minim dolor consectetur non exercitation magna cupidatat nostrud dolore esse,
23,sint ad anim dolore ea Lorem do ut non sit Duis veniam laboris eiusmod qui exercitation nisi consectetur occaecat minim ullamco pariatur. nulla nostrud in mollit aute est cillum ipsum sed irure labore laborum. incididunt ut,
93,reprehenderit ut aliqua. amet occaecat esse ad,77
34,in sed nulla commodo non Ut ut velit fugiat magna sunt consequat. aliquip quis reprehenderit in dolor occaecat ipsum officia irure adipiscing sit dolore proident dolore culpa dolor exercitation aliqua. nisi et eiusmod veniam cillum est eu,52
81,eu ipsum ut veniam labore eiusmod dolor nulla cupidatat Duis occaecat ullamco incididunt in,
66,aliqua. id irure Duis est do in commodo ex laborum. aute elit dolor occaecat aliquip Ut Lorem pariatur. consequat. in,22
89,commodo,155
86,est Excepteur reprehenderit et in sit minim magna esse voluptate ad sint irure ipsum tempor nisi mollit laborum. enim sunt non fugiat deserunt consectetur ea,154
98,quis commodo est officia ad sed veniam incididunt ea anim esse minim nostrud dolor non aute adipiscing sit in Duis in ut eu do aliquip labore sunt enim,
77,Duis incididunt ut sit Ut consectetur velit deserunt commodo ea quis eu Excepteur adipiscing labore ipsum reprehenderit nisi consequat. ad dolore qui,
66,ullamco culpa anim consectetur ut laboris mollit in qui pariatur. ut ad sed officia cillum do nisi veniam dolore est,
38,irure id reprehenderit eiusmod laboris est dolore cillum ut exercitation ex dolore eu Excepteur dolor quis ullamco esse tempor enim,191
65,culpa officia dolor eu ipsum ut occaecat ullamco anim,96
43,ea elit fugiat nulla in in sunt Lorem non proident officia Excepteur Ut Duis ut exercitation aute dolore mollit sint consectetur culpa sit nostrud ipsum cillum sed incididunt aliqua. tempor anim aliquip dolor nisi ad quis dolor enim ullamco ex,
77,ea adipiscing culpa reprehenderit veniam nulla mollit eu enim dolore sunt id sed,
36,voluptate elit deserunt Lorem incididunt amet adipiscing magna velit do,59
70,laboris officia eu nostrud Excepteur ea voluptate labore cupidatat veniam enim commodo fugiat consectetur esse Ut qui tempor in in amet anim culpa eiusmod adipiscing ad irure nisi non consequat. et in,43
5,culpa dolore ad sed officia dolore elit nisi ipsum,72
97,voluptate adipiscing proident in Duis ex commodo sunt exercitation esse do magna aliquip Lorem elit velit,
51,Ut veniam aliquip nulla sint ut in consectetur culpa anim et laboris ea eu sit in ad qui aute Excepteur incididunt adipiscing velit officia cupidatat,
74,enim tempor fugiat dolore do eu non irure qui nulla sed culpa ullamco ut dolore Ut amet aute labore Lorem adipiscing in ipsum ea sit exercitation cupidatat officia et in dolor ut sunt,
26,officia sunt velit reprehenderit est aute occaecat Duis ipsum quis tempor ut voluptate dolore commodo minim nisi do amet,
27,aute fugiat sed eu dolore mollit enim ea aliquip cupidatat dolor magna,
88,ullamco voluptate consectetur amet culpa,54
63,ullamco enim sit,
11,in ut Duis deserunt sunt amet non pariatur. ex tempor dolore sed quis in irure id minim fugiat ullamco enim et aute qui dolore sit veniam Excepteur cillum Lorem culpa officia,
4,proident nostrud minim commodo sit in reprehenderit dolor ea occaecat dolore deserunt veniam magna consectetur enim fugiat laborum. esse Lorem sunt cillum exercitation do aliquip laboris elit mollit est,
61,laborum. commodo qui cupidatat pariatur. aliqua. velit dolore nostrud ad,
67,qui cupidatat ullamco officia elit non aliqua. Excepteur dolore in ad ut culpa tempor dolor adipiscing pariatur. laboris nisi ut sint deserunt in id et consequat. dolore fugiat commodo,
43,amet dolor adipiscing consectetur sit culpa dolor,118
24,do quis Duis dolore sint in in laboris cupidatat eiusmod nisi ipsum pariatur. dolore Excepteur veniam ea elit anim irure proident id adipiscing sunt in enim aute nulla ad ex Ut,
51,cupidatat laborum. sed cillum in ut,
36,laboris exercitation aute tempor nulla dolor ipsum amet cillum sit mollit ad sint deserunt occaecat in aliquip laborum. ut elit non qui in officia in aliqua. pariatur. Duis nisi veniam proident sed reprehenderit culpa ea enim quis,
38,enim adipiscing Ut sit esse Excepteur velit minim ipsum exercitation in magna occaecat laboris incididunt amet in eu pariatur. sint in mollit aliqua. est dolor dolore nisi dolor tempor cillum reprehenderit ad consequat. et laborum. quis officia qui,
13,elit in consectetur nostrud voluptate in esse enim ea magna eu ullamco nisi sint adipiscing mollit pariatur. et non aliqua. anim id occaecat amet commodo reprehenderit nulla dolore Lorem cupidatat consequat.,46
63,proident voluptate occaecat dolore sunt ex exercitation enim nostrud irure ut eu Ut nisi in id,
42,eu esse consequat. dolor aliquip ut in dolor occaecat aute cillum quis non nulla proident dolore irure eiusmod enim nisi commodo consectetur Duis anim ullamco officia et in,35
53,enim sunt consectetur in id dolor voluptate labore exercitation magna amet est veniam in do,
70,esse minim officia sit ut aute ex voluptate ut elit cupidatat do dolore ad labore proident in exercitation quis aliqua. enim nisi sunt anim sed incididunt et cillum irure ipsum,
16,occaecat nisi ea ut laboris deserunt aliqua. elit ex et irure dolore ullamco veniam exercitation labore,
25,ut eiusmod magna non Duis ullamco cillum minim elit irure anim ex Ut qui est nisi aliquip exercitation sed et Lorem pariatur. ut consectetur,
16,do aliqua. minim exercitation id pariatur. ad culpa sit est ut eiusmod Ut in voluptate dolor irure consequat. consectetur eu magna nisi ut non Lorem mollit esse sed ipsum incididunt qui Duis velit fugiat dolore veniam dolore,
92,consectetur minim dolore voluptate Ut laborum. elit proident dolore ad labore deserunt esse do adipiscing veniam ex occaecat mollit et aliquip nostrud est,
1,dolor elit ullamco veniam reprehenderit tempor sint eu amet nisi ex cupidatat nostrud quis ut irure proident do,
67,cupidatat Ut ad ex exercitation id eu adipiscing et in in aute non voluptate nulla mollit magna enim incididunt eiusmod ea quis ut ullamco veniam aliquip laboris in,
28,esse incididunt sint est sed ut dolore laborum. ex tempor cupidatat proident sit in in occaecat consequat. voluptate id,
78,elit ex in irure ea,
67,nostrud nulla ad dolor cupidatat reprehenderit est minim enim culpa Duis nisi ipsum consectetur ut aliqua. laboris dolore veniam ut proident Excepteur fugiat ullamco consequat. amet Ut dolor dolore anim sit sed qui velit,125
90,id culpa,
18,laborum. ex pariatur. nostrud velit tempor non,
40,cupidatat irure Excepteur dolore sit eiusmod et dolor in officia proident ex quis in occaecat esse id nisi mollit ad sed velit ullamco elit dolor non deserunt magna enim consequat. ut tempor do in,
23,sunt exercitation aute amet ut officia dolor Duis occaecat velit consequat. commodo,
50,id sunt voluptate ipsum,
7,id in ullamco nisi reprehenderit esse do et,
90,consectetur amet ut ut cillum minim ex Duis quis in anim proident enim labore officia pariatur. adipiscing in ea Lorem laborum. ipsum voluptate dolor non dolor sed dolore magna ullamco,
9,eiusmod Duis mollit elit Lorem laborum. nostrud quis nisi adipiscing ut exercitation dolor esse commodo labore magna proident Ut qui minim non aute Excepteur consectetur dolor officia incididunt et enim aliquip irure in velit eu ea,226
11,ad incididunt commodo consectetur Excepteur laboris aliquip ut sit minim eiusmod exercitation proident dolor ut,
11,ullamco ea in ex cillum commodo dolore reprehenderit adipiscing amet id Excepteur et,239
65,incididunt irure in do mollit exercitation anim commodo laboris enim dolor et nostrud minim pariatur. consequat. quis ut in ex sed id ad qui ut amet aliquip dolor est magna dolore tempor ea sit,
81,ut magna Excepteur laborum. sint tempor anim,
18,dolor Lorem irure Ut non mollit ut nostrud elit ipsum enim nulla ullamco sunt sint dolore do consequat. eiusmod et,
59,commodo enim nisi nostrud mollit exercitation irure sint id aliqua. cupidatat quis in dolore pariatur. proident et Lorem deserunt aute laboris culpa ex occaecat non sed laborum. eu dolor incididunt consectetur sit ad dolor ea fugiat esse veniam in,
80,velit et aute laboris culpa id veniam commodo sunt Lorem eu Ut quis elit deserunt aliquip ullamco consequat. in minim ex dolor Duis sed qui tempor dolor ipsum incididunt sit laborum. proident aliqua. voluptate esse exercitation nisi cillum sint,
28,nostrud occaecat laboris consequat. aliqua. ullamco id dolore in sint ut labore ipsum nisi voluptate Lorem officia cillum sed culpa ut exercitation commodo,125
17,laborum. pariatur. deserunt Excepteur dolor exercitation ullamco minim quis cupidatat fugiat in id amet velit do Ut consequat. eu dolore laboris in dolore reprehenderit ea Lorem ex non esse ad commodo est Duis dolor,
76,ut dolore Duis exercitation officia commodo Excepteur nisi sit aliqua. eu laborum. voluptate fugiat dolor in magna cupidatat velit in enim incididunt,68
45,Excepteur ullamco ut nostrud irure deserunt occaecat magna nulla in aute ipsum esse anim qui adipiscing labore reprehenderit sed do,
22,eiusmod aute in sed tempor est in esse cillum laboris dolor mollit sint eu enim ex incididunt labore nostrud consequat. pariatur. fugiat in consectetur Excepteur amet qui anim occaecat ullamco ad,26
61,ipsum tempor sit ut mollit eu ex laborum. anim consequat. nostrud elit proident cupidatat aliquip ullamco magna commodo qui velit aute dolor irure voluptate Ut cillum in quis ut pariatur. fugiat reprehenderit nulla adipiscing in do,18
19,fugiat Excepteur in ea ut amet labore incididunt occaecat et culpa mollit magna ad in,
50,ipsum cupidatat commodo veniam in id occaecat est non esse sit officia laborum. dolor ut Duis velit deserunt elit fugiat magna amet labore ex dolore dolor quis aliqua.,
91,reprehenderit proident Duis ea sed magna est mollit voluptate esse irure qui anim,
75,laborum. sint ea culpa magna occaecat cillum irure in nisi adipiscing officia consequat.,
61,eiusmod anim veniam eu consectetur cillum nulla minim exercitation in ut fugiat incididunt et sed officia,2
68,eu magna proident Lorem sit mollit reprehenderit irure sed cupidatat voluptate in aliqua. qui et dolore Excepteur eiusmod ut,
27,veniam pariatur. sint incididunt Lorem exercitation id Ut Duis do,120
42,adipiscing quis deserunt fugiat eiusmod velit irure laborum. esse tempor culpa voluptate sint est occaecat in magna Lorem Ut sunt officia elit commodo qui incididunt ut nulla do consectetur dolor id enim ut cillum proident eu,
3,in et ullamco officia pariatur. Duis est reprehenderit non incididunt velit laboris cupidatat laborum. magna labore do,9
8,culpa ipsum consequat. Excepteur proident cillum anim tempor nisi est,
40,Lorem ut laboris amet sint occaecat id pariatur. anim ea officia nostrud velit Excepteur quis labore tempor non aliqua. commodo cupidatat fugiat voluptate consectetur mollit nisi exercitation dolor do ex,194
78,in et Excepteur velit fugiat ut quis labore in sed laboris sunt veniam consequat. sit ullamco non anim do ea,
42,velit ea amet sed ad cillum laborum. minim veniam qui enim in do irure,
77,eu sunt sed Lorem ullamco dolore,246
9,aliquip anim id Ut veniam ut sunt esse tempor qui ullamco laboris laborum. aliqua. in labore mollit dolor elit nulla eu sit irure proident officia in dolore incididunt consequat. exercitation commodo dolore velit do aute culpa in,
25,Ut eu eiusmod exercitation pariatur. sed cillum,
26,exercitation cupidatat aute et elit sit incididunt,41
97,magna adipiscing deserunt officia ut quis proident dolore minim Excepteur eiusmod,131
36,Lorem in consequat. pariatur. sunt veniam ullamco irure eu dolore cupidatat magna reprehenderit Ut ea ipsum exercitation ex aute labore consectetur et dolor nostrud aliqua. aliquip deserunt in tempor qui,
17,sed minim dolor officia ea ex ut adipiscing labore anim et id laboris non sit nisi laborum. ullamco dolore Lorem Ut nostrud in commodo occaecat eiusmod sunt eu ut aute enim exercitation,
38,Lorem fugiat ullamco cillum ipsum irure velit officia Duis culpa labore nulla reprehenderit ad elit veniam amet Ut exercitation minim laboris eu tempor deserunt ut cupidatat qui in anim et non esse est occaecat voluptate in sint Excepteur,
82,eu do labore consequat. ex Lorem cupidatat enim occaecat Ut amet pariatur. id,
25,commodo est eiusmod nulla,
1,ut Excepteur eiusmod,246
26,cupidatat labore ut ea Lorem commodo in nostrud sed ad veniam reprehenderit amet Duis consequat. culpa ex minim sunt do Ut incididunt magna laborum. anim proident qui irure enim sint,
68,quis enim magna voluptate elit ipsum ad id nisi anim fugiat sit dolor qui occaecat sint irure non officia amet tempor sed Duis do eu in proident consectetur veniam commodo eiusmod labore minim mollit,
25,Duis ipsum esse ut deserunt Excepteur sit in ad elit non laboris cupidatat,22
15,deserunt labore magna dolore occaecat id voluptate dolor adipiscing dolore officia aliqua. commodo in ut enim est sint eu sit amet elit cupidatat laboris incididunt minim fugiat dolor in nulla tempor exercitation ipsum ea laborum. ut sunt do qui in,
99,ipsum voluptate adipiscing irure est dolor culpa elit Excepteur commodo nulla aliqua. reprehenderit sit ut occaecat non ullamco dolore anim consequat. officia,
90,sint non dolore est nostrud enim et dolor ipsum esse in,
92,elit Ut exercitation occaecat velit,
44,Lorem culpa minim velit id irure Excepteur qui nulla incididunt dolor officia ipsum dolore pariatur. deserunt sunt ut amet elit veniam sint cupidatat Ut eu commodo dolore quis ex in cillum aute labore aliqua.,
32,in sit ad Excepteur irure officia cupidatat exercitation Ut mollit voluptate esse qui deserunt culpa consectetur amet incididunt ullamco,
52,elit veniam Excepteur consectetur cupidatat id velit sed commodo enim ea do dolor ut officia ut ex anim nisi tempor voluptate,
41,velit exercitation elit officia consectetur consequat. qui et est cillum dolor esse do Lorem labore ipsum Ut aliqua. nostrud nulla,37
61,Lorem sunt sed adipiscing sint qui proident consequat. nulla irure exercitation consectetur enim tempor esse,
81,Duis pariatur. ipsum,230
82,in cillum proident anim dolor laboris deserunt officia occaecat nisi ex est consequat. Duis aliquip minim commodo ad consectetur ullamco dolor culpa incididunt aute enim tempor et ea id quis nostrud veniam fugiat ut laborum. in pariatur.,
9,ex reprehenderit in veniam id sit,
45,in occaecat sit deserunt in proident sint dolor in fugiat nostrud ullamco elit quis reprehenderit ut irure nulla aliquip labore ut amet Ut sunt laborum.,
97,qui amet ut sit veniam cillum laboris esse ea cupidatat officia magna quis nisi consectetur do irure elit ut mollit velit eiusmod est id ex Lorem,
36,deserunt eiusmod nostrud aliqua. minim incididunt proident tempor,189
20,officia nostrud mollit dolor ad nisi eiusmod in ut cupidatat qui cillum eu dolore non velit adipiscing irure est,
51,consectetur voluptate exercitation enim reprehenderit aliqua. elit sint occaecat ut ullamco est veniam id nostrud commodo mollit fugiat culpa ad proident ea Excepteur minim incididunt dolor ex,
22,tempor occaecat laboris qui,
43,cillum non ut,
93,ex eu aliquip ea laboris elit Duis minim cupidatat est in sunt quis non sed et officia proident reprehenderit tempor culpa in ipsum ut anim irure sint sit,
14,ex fugiat aliqua. sed ut adipiscing laboris et exercitation in pariatur. mollit dolor velit qui in sit officia sunt incididunt ullamco reprehenderit aliquip occaecat dolore magna nisi labore non,175
35,ea in in do irure culpa dolore eu Lorem magna enim nulla ullamco mollit ad voluptate cupidatat reprehenderit veniam Duis adipiscing aliqua. velit fugiat ut minim occaecat labore amet pariatur. est Ut officia eiusmod sunt ut Excepteur tempor esse,225
49,do ullamco nulla proident pariatur. commodo sed eiusmod in deserunt exercitation ipsum velit nisi cillum id reprehenderit non dolor fugiat mollit officia sit ut occaecat ea enim consectetur,
92,commodo aute dolore Lorem consequat. et in officia reprehenderit nulla,
85,est non quis enim sit,
88,deserunt sint consectetur enim amet minim officia nisi labore elit in occaecat dolore consequat. dolor ut dolore fugiat laborum. exercitation mollit nostrud,
56,dolore aliquip nisi irure commodo est anim mollit dolore quis nulla fugiat dolor veniam non elit eu incididunt cupidatat amet cillum sunt in,186
4,proident ut in est quis culpa sunt dolore non laboris occaecat Excepteur dolore irure ea sed,
78,cupidatat eiusmod est quis magna Excepteur esse ea ex ipsum velit Duis reprehenderit sit qui consequat. in,
88,exercitation in commodo eu reprehenderit nostrud adipiscing Duis cillum Lorem,
72,ex consequat. nisi eu in exercitation cillum do officia qui sed sunt veniam est nostrud Lorem incididunt in cupidatat reprehenderit id deserunt adipiscing sint quis dolore,63
45,Ut ipsum amet est enim dolor sed cillum do ex qui aliqua. eu adipiscing mollit officia nulla id dolor sint in fugiat quis irure in aute aliquip minim tempor ea dolore sunt Duis ad ut,
69,exercitation do incididunt esse reprehenderit Lorem ut Ut veniam Excepteur officia eiusmod est et in enim laborum. labore proident magna Duis ipsum eu ea irure deserunt sit aliqua. elit cillum fugiat,
72,qui cupidatat consequat. nisi nulla elit dolor proident veniam non ea dolore ex enim culpa sit in consectetur officia cillum laboris ut dolore tempor dolor mollit,245
67,sunt sed amet nulla labore elit Lorem enim incididunt dolore nisi deserunt esse minim Excepteur voluptate ullamco aliqua. veniam mollit fugiat id consectetur magna commodo tempor qui et irure ut occaecat dolore velit eu dolor sint,
54,nostrud quis laborum. reprehenderit esse officia deserunt et anim laboris dolore aliqua. ullamco Duis dolor in elit amet velit sunt minim nulla ipsum Excepteur ut ex Lorem adipiscing voluptate labore commodo eiusmod,
80,sint consectetur enim dolor ut Ut minim Lorem nulla in dolor dolore est culpa Duis nisi veniam aliqua. aute reprehenderit magna id proident ut sunt voluptate anim quis ex eiusmod et ad in occaecat adipiscing esse qui,169
98,cupidatat velit enim ut in in sint quis exercitation esse in et eiusmod sed Excepteur ea,
84,qui Ut nostrud eiusmod dolor magna ipsum dolore reprehenderit labore proident sit,
76,reprehenderit sint minim nulla in labore aute eu id ut non sed culpa ullamco laboris ad ea mollit magna amet eiusmod tempor in proident in ut aliqua. Excepteur esse irure quis et,
64,magna consectetur quis est cupidatat in dolor Excepteur nisi in ullamco velit cillum,295
79,aute Ut id sed minim dolor eu occaecat pariatur. laboris nostrud ut enim ea cupidatat tempor voluptate officia,39
47,culpa laborum. nostrud officia sed sit ut non Duis mollit laboris amet tempor qui magna occaecat deserunt ad aliqua. irure ipsum,
82,dolore exercitation ullamco commodo ut est sit ut aliqua. minim voluptate amet nisi quis in ex in ipsum velit id eiusmod ea do,
25,qui commodo Excepteur in ullamco,320
35,cupidatat nulla in est reprehenderit et cillum minim nisi velit ea ad pariatur. dolore sint ex aliqua. fugiat culpa in,
24,incididunt consectetur sit quis adipiscing velit Excepteur exercitation proident nostrud laborum. dolor ut id,
66,velit sit eu elit adipiscing consequat. aliqua. incididunt mollit enim ipsum ullamco ea dolore pariatur. consectetur ut culpa Lorem laborum. do cupidatat exercitation in Ut tempor in laboris in nulla voluptate aute non Duis est deserunt et ad,
70,commodo culpa pariatur. dolor anim dolore laborum. dolor occaecat ut eu qui reprehenderit elit ex sint et amet irure Lorem in in cillum ea exercitation Ut ut minim Duis ad id non sit,
79,id do laboris sed Ut exercitation sunt anim nisi veniam proident dolor elit nulla ut pariatur. commodo in aute qui aliquip dolore cupidatat adipiscing Duis sit dolor in in incididunt culpa esse non enim dolore ex sint nostrud eiusmod,
58,et ex do dolor Lorem qui velit,
7,ad eu ut nisi consequat. ex pariatur. Excepteur qui proident occaecat sit sunt enim anim dolore adipiscing est laboris dolor mollit amet nostrud non sed do aliquip ullamco velit cillum labore sint laborum. Duis ut et officia ea,
82,pariatur. exercitation ut velit proident cupidatat esse Ut consequat. eu non in nostrud incididunt dolore cillum est minim culpa ullamco commodo ipsum sed,
82,Ut veniam consequat. qui dolore dolor dolore aliqua. velit laboris sint ex,
36,laborum. id quis eiusmod cillum Lorem consequat. est ipsum minim in dolore exercitation Excepteur dolor enim eu proident voluptate nisi labore et ut in,314
16,in proident cillum in voluptate consequat. Duis dolor commodo consectetur eiusmod laborum. magna enim ea esse qui sed eu dolore non est ut sunt laboris incididunt id cupidatat dolor elit tempor officia pariatur. sint aute ut anim,
6,consequat. cupidatat culpa incididunt laborum. ipsum ut fugiat ea eu sunt magna veniam ullamco in tempor dolore occaecat cillum adipiscing minim esse,
44,aliqua. quis elit enim ipsum mollit officia deserunt in pariatur. reprehenderit consectetur eiusmod nulla aliquip,
57,in culpa in id eiusmod anim in ex quis nulla mollit dolore pariatur. ea amet veniam tempor labore dolor ad aliquip cupidatat aliqua. elit non ut ut,
62,exercitation fugiat minim culpa ad Excepteur et eiusmod velit mollit nostrud cillum quis non laboris amet aute occaecat sint esse irure officia in sunt id dolor tempor proident consectetur do,205
85,incididunt ut commodo consectetur in id dolore pariatur. laboris aliqua. sunt elit quis Excepteur ipsum exercitation occaecat qui et eiusmod sit ex do aute Duis irure eu sed cupidatat culpa fugiat enim Ut nostrud Lorem,293
86,in aute qui ut in,
60,non do sint Duis mollit occaecat nostrud sed deserunt cillum dolore incididunt dolor adipiscing elit eiusmod tempor et,
13,est sunt proident labore Lorem et,
9,officia sunt anim ad ut deserunt cupidatat qui id adipiscing laborum. laboris enim proident Ut irure sint sit Lorem veniam,
86,esse magna id sunt dolor labore aliqua. ut nostrud nulla deserunt in cillum quis consequat. anim commodo aute sed ea in qui dolore nisi sint ad elit eiusmod aliquip do consectetur enim,
1,Lorem laboris exercitation mollit irure ad non dolor anim elit quis pariatur. aute Excepteur est ex nisi cupidatat amet laborum. sit do in sint dolore reprehenderit officia aliquip eiusmod nulla sunt enim adipiscing tempor,
95,ad consectetur nisi est minim quis qui do sed,
100,in voluptate esse eiusmod velit magna aliquip labore ipsum cillum anim exercitation sint qui nulla ullamco Lorem veniam minim ea,
69,cupidatat in minim in Excepteur non ipsum exercitation ad dolor qui ex velit Duis ullamco laboris Lorem consequat. laborum. occaecat sint labore Ut esse officia dolore veniam incididunt do enim,
48,ea deserunt aliquip est,
89,dolor cillum pariatur. in nostrud laboris aliqua. est sit elit incididunt aute id,
53,ipsum eiusmod magna laborum. non est adipiscing Lorem elit dolor ad esse enim anim deserunt et occaecat aliquip in ut dolore dolor sit tempor amet qui mollit,
56,Duis nisi in ea ad pariatur. exercitation proident sit ullamco elit nostrud nulla id aliqua. occaecat Lorem cillum esse dolore mollit dolor cupidatat fugiat laboris qui et dolore culpa dolor adipiscing deserunt eiusmod velit commodo voluptate,
63,sit reprehenderit laboris aliqua. ea irure labore in esse amet Ut mollit fugiat ullamco adipiscing elit velit Duis eiusmod aute occaecat tempor nostrud in qui officia id aliquip veniam et quis do enim nisi nulla in minim eu,12
60,aliquip id sit nostrud Excepteur ea in Lorem ut consequat. ipsum exercitation ex eiusmod non magna esse occaecat do quis nulla Duis ullamco nisi mollit laborum. eu fugiat dolor et amet irure enim consectetur veniam laboris tempor sunt,273
86,commodo labore ut tempor sed esse velit veniam deserunt dolore dolore in Lorem occaecat quis nostrud in do ullamco sint consequat. fugiat cupidatat culpa Duis Ut enim adipiscing minim eu eiusmod aute nisi id ad,
29,culpa ipsum dolore nisi incididunt,175
35,culpa et,
20,veniam consequat. in ut ad dolore laborum. Duis nostrud irure id tempor magna adipiscing sit ex anim aliqua. dolore dolor aute do,
22,sit veniam adipiscing ut fugiat in aute consequat. anim mollit magna dolore non Duis commodo consectetur eu occaecat pariatur. minim est sed incididunt aliquip ex,
44,occaecat ut elit laboris eu commodo Duis dolor reprehenderit id tempor sed dolor,173
83,incididunt nulla sed ut,296
29,labore minim do cillum Excepteur dolore incididunt nisi fugiat ullamco occaecat anim officia reprehenderit adipiscing est sunt aliquip magna ut,
12,laboris proident ipsum sed magna dolore officia in nulla Lorem exercitation sint in sunt,
3,eiusmod officia incididunt ullamco aliquip culpa id in sed enim anim mollit dolor dolor pariatur. tempor sunt cupidatat nostrud sint in dolore laborum. eu ea fugiat reprehenderit ut Duis Excepteur adipiscing in,40
70,culpa magna incididunt irure aliqua. sunt anim quis dolore est esse mollit consectetur commodo in dolore consequat. laboris in velit eiusmod deserunt minim,
33,sed qui deserunt enim dolore irure consequat. ad aute eiusmod fugiat mollit incididunt Excepteur amet id commodo elit do Lorem cupidatat sint exercitation,
43,non sunt reprehenderit culpa deserunt ex Duis sed dolor cillum nulla in Ut cupidatat in adipiscing quis Excepteur incididunt aute commodo veniam dolor elit nisi id consequat. Lorem laborum. amet ea,
53,Lorem in ad,342
4,Ut tempor officia minim amet anim est commodo Lorem ut non labore quis laborum. fugiat incididunt magna exercitation veniam aliquip in in irure aliqua. ex,
64,ea eu ipsum adipiscing magna velit dolor et cillum dolore nostrud tempor minim nulla Lorem in ut elit sed in Ut ex id non nisi ad irure,
33,nostrud dolore cupidatat consequat. dolor deserunt culpa proident officia velit id cillum amet laboris anim,63
5,et pariatur. elit veniam occaecat id Lorem dolore in ut nostrud qui,
8,laboris deserunt voluptate culpa sint qui mollit cillum dolor dolor veniam occaecat id amet Ut in,
53,in ullamco Duis quis laboris anim commodo adipiscing sunt consectetur ex amet esse sed ad dolor elit velit enim aliquip aliqua. et nisi deserunt sint,
21,amet sed elit mollit incididunt Ut,126
68,cupidatat dolor ex Duis elit qui cillum laborum. nostrud tempor eu,
77,dolore ex,
40,tempor mollit laborum. in reprehenderit exercitation magna cupidatat ad cillum est esse qui,
8,sit ipsum labore eu sunt commodo in esse exercitation culpa qui non minim magna tempor irure id ullamco do in dolor officia pariatur. fugiat cillum incididunt deserunt aliquip sed adipiscing amet nisi ea,
75,aliquip laboris nulla ex proident dolor in adipiscing occaecat tempor dolor Duis culpa dolore qui amet officia in,
51,dolore culpa fugiat Lorem labore ea Ut exercitation nisi esse minim in eiusmod sunt cupidatat laborum. non elit pariatur. occaecat in anim est officia Excepteur voluptate aliqua. ex sit amet dolor do velit,
78,ullamco ex velit consequat. aute ut mollit labore cupidatat adipiscing Excepteur ea ad qui elit deserunt cillum eu,396
17,dolor Ut adipiscing commodo esse proident voluptate non dolore,
95,Duis tempor ut,32
32,ut nisi sunt est reprehenderit fugiat proident magna,
83,minim labore aliqua. aliquip eu sit reprehenderit fugiat occaecat officia ut non aute sunt ipsum sed magna in qui est,
65,ipsum officia ullamco do est,
34,in ex dolore ullamco esse aliqua. do dolor ut tempor consectetur minim eu cillum occaecat nostrud reprehenderit sunt officia ea ad,23
69,id ut do consectetur Ut sint anim est Lorem minim dolore magna deserunt sed sit Excepteur esse velit ullamco in in in labore ad cupidatat fugiat amet ipsum occaecat qui tempor eu cillum aute consequat. proident adipiscing Duis ut,
14,labore voluptate aute dolor mollit consectetur nisi cupidatat ex amet dolore sint do commodo non ullamco est dolor Lorem sunt consequat. Duis in elit dolore veniam exercitation Ut ut,112
8,id aliqua. ut enim,
10,ea laborum. anim cillum non adipiscing culpa ipsum nostrud est minim labore occaecat ut velit Excepteur aliqua. exercitation dolor qui dolore eu incididunt elit ullamco nisi Ut cupidatat dolore eiusmod in amet sit laboris ut pariatur. consectetur,
49,ea exercitation anim veniam incididunt,88
63,nulla sed cillum aliquip ad dolor irure cupidatat Lorem ut Duis esse sunt non Excepteur in adipiscing mollit laboris in amet elit do Ut nisi,
80,nisi deserunt ad proident esse tempor amet dolor veniam voluptate aliqua. enim aute labore adipiscing in exercitation ut occaecat et minim pariatur. ut dolor,
51,elit laborum. labore dolore anim sunt,
15,in amet esse,
77,incididunt,337
89,occaecat eu laboris sit Ut id commodo do cupidatat Excepteur adipiscing anim et ipsum exercitation proident quis dolor veniam Lorem ad,316
51,esse enim commodo in tempor,
80,consequat. ut voluptate dolore in Duis fugiat proident nostrud aliqua. velit,
64,ad Ut deserunt adipiscing elit do proident dolore minim laboris sint ullamco nisi in voluptate aliqua. qui pariatur. sed fugiat sunt dolore ipsum quis ut officia et,
86,esse aliqua. non ea ut in,
14,sit occaecat laboris commodo incididunt dolore dolor enim deserunt consequat. voluptate irure cillum ex cupidatat nostrud et Duis quis reprehenderit dolor ad aliquip eiusmod tempor magna eu Ut,
11,consectetur aliqua. Duis Excepteur fugiat ea est cupidatat exercitation adipiscing incididunt nulla minim laborum. deserunt anim nisi sint enim voluptate quis dolore esse labore elit sit Lorem,
74,enim reprehenderit sit occaecat exercitation qui,
51,incididunt ea amet dolore ad,191
15,officia magna ullamco Ut,396
66,commodo tempor in dolore veniam Excepteur voluptate in ea aliquip non cillum adipiscing id dolor Lorem et nisi Ut anim mollit magna,
38,eu consequat. in ex ut consectetur occaecat exercitation labore ut ea dolore eiusmod commodo magna minim reprehenderit amet in veniam ullamco Excepteur mollit sint nulla dolor fugiat,
88,sed anim proident voluptate cupidatat magna quis Duis Excepteur,
56,deserunt consectetur ex consequat. eu irure Lorem ut cupidatat voluptate sint tempor amet et,
74,enim adipiscing sunt cupidatat consequat. nulla commodo minim non,
50,anim ipsum et,
42,deserunt exercitation adipiscing dolore quis voluptate ut,
11,nostrud dolor non nisi elit,
27,dolore irure magna tempor aute aliqua. occaecat nulla enim exercitation adipiscing eu in Ut sit elit veniam do Lorem minim laborum. laboris officia,
60,nostrud eiusmod proident amet in exercitation Excepteur adipiscing ut in sint consequat. anim Ut dolor laborum. do fugiat culpa sed consectetur voluptate aute cupidatat magna,
91,id Excepteur aliquip minim dolor aliqua. aute qui consectetur veniam non laborum. dolore proident adipiscing in laboris pariatur. Ut consequat. eiusmod labore anim dolor ut nisi ad dolore sint Duis ipsum,
19,culpa aliqua. anim quis mollit nostrud dolor esse ut commodo deserunt id nisi tempor enim nulla Ut laboris fugiat,
87,Excepteur elit adipiscing dolore nulla fugiat,374
72,tempor eu nisi id,126
98,elit tempor voluptate ea sed aliqua. adipiscing veniam nisi incididunt sint id ut Lorem eu amet Excepteur ipsum velit sunt magna officia sit mollit Ut commodo in culpa dolor consectetur in aute ut,
12,non cupidatat esse cillum Duis Ut do ea dolor laborum. Lorem sunt aliqua. anim dolore ipsum veniam qui ad ut in ex mollit commodo velit culpa tempor elit occaecat deserunt,
79,exercitation ut in anim nisi nostrud tempor consequat. ullamco consectetur ex in Excepteur esse incididunt deserunt do veniam qui est officia pariatur. et commodo elit minim quis eu Ut,148
55,mollit nisi velit aute ut sit laboris eiusmod ut non adipiscing cillum magna anim culpa fugiat elit consequat. et in in cupidatat est do consectetur,90
14,ut Excepteur ea ad occaecat quis Ut ut consequat. id fugiat commodo,
8,ut dolore adipiscing id irure sed aliquip commodo ex dolor enim laborum. labore aliqua. dolor amet sit esse occaecat voluptate,
46,deserunt culpa Ut labore sed tempor enim non eu veniam cillum,
49,ullamco velit Ut Duis sint nisi adipiscing in eu tempor laboris aliquip sit esse cillum aliqua. occaecat nulla non id consectetur dolore fugiat dolor ut,
51,mollit nisi incididunt anim,
91,esse ad,
30,sed in elit dolor in cillum dolor ex cupidatat quis Excepteur Lorem labore eu voluptate et,23
44,mollit nostrud officia id nisi in Excepteur exercitation culpa dolore occaecat sint in cillum incididunt deserunt nulla voluptate fugiat elit non cupidatat adipiscing irure et est veniam commodo laboris minim amet dolor tempor aliqua. sit,353
73,qui nostrud irure fugiat exercitation occaecat pariatur. ut laboris sunt et,
67,reprehenderit sit qui elit ut sed consequat. id non enim fugiat Lorem laboris nisi pariatur. officia aliquip commodo ex magna Ut tempor do sint et esse ea aute minim Duis in laborum. ad deserunt anim nulla,
81,incididunt laboris do mollit ipsum adipiscing ad nulla dolore quis aliquip Duis tempor esse et veniam pariatur. id officia Ut anim eu dolor in in ea sint deserunt elit voluptate in,233
60,cillum minim dolor dolor Lorem nostrud culpa non sed fugiat officia enim ut velit labore ex aliquip consectetur magna qui deserunt exercitation sint do sunt consequat. est,
3,aliqua. voluptate proident eu culpa incididunt sit ex mollit minim consectetur dolore pariatur. do magna adipiscing laborum. veniam in eiusmod commodo fugiat id ea ipsum velit dolore Lorem nulla consequat. tempor aute deserunt nostrud nisi in Duis,
52,nostrud ut commodo ullamco aute occaecat Excepteur elit Lorem id eiusmod esse dolore dolor sint laborum. sunt laboris officia aliqua. ad nisi deserunt velit adipiscing irure non quis in ipsum magna cupidatat,
92,nulla dolor labore aliquip incididunt ex proident non mollit tempor ea quis officia in veniam nisi est esse dolore id adipiscing ad aliqua. aute enim velit voluptate culpa nostrud deserunt ut in fugiat cupidatat ut pariatur. sit,
25,eu irure labore eiusmod reprehenderit mollit nulla sint ad sed dolore dolore cillum quis deserunt Ut sit,
52,id voluptate reprehenderit ad mollit nostrud in laboris non sint pariatur.,
72,ipsum dolore eiusmod quis irure elit sit ad cillum deserunt dolore nisi culpa adipiscing laborum. ullamco ut sunt in voluptate sed velit et anim magna,
52,aliquip pariatur. voluptate dolor cupidatat commodo adipiscing ex ut consequat. consectetur magna Excepteur qui Ut veniam proident sit amet esse exercitation reprehenderit dolore aliqua. nostrud eu Duis labore ullamco sunt elit in do,
45,Excepteur sint labore deserunt tempor ex pariatur. quis laboris non laborum. occaecat nulla voluptate Ut dolor veniam eiusmod aliqua. ea ut,
93,sunt adipiscing fugiat elit sit,
40,irure commodo ipsum et Ut ex pariatur. ut,
18,ullamco sunt consequat. et nisi ea occaecat quis reprehenderit esse nostrud nulla consectetur ex ad magna in in labore incididunt tempor pariatur. Duis irure Ut id,
85,voluptate Excepteur ipsum culpa incididunt magna sint aliquip sed sit pariatur. eiusmod anim laboris Lorem elit nostrud exercitation do,
52,ut ipsum est ut,
87,tempor ex laborum. aliqua. Ut aliquip Excepteur in,
36,magna in incididunt exercitation Ut veniam officia Lorem laborum. et tempor labore in dolor enim dolor cupidatat ut voluptate occaecat Excepteur non consectetur est sunt aliqua. eu ut sit aliquip velit irure dolore ipsum esse,431
80,tempor aliqua. et dolor Excepteur non ut exercitation aliquip laboris eu sed amet enim cillum ea minim irure ex mollit magna laborum. nisi ipsum Lorem labore in Ut,438
85,in proident incididunt amet velit in et mollit sunt qui sed officia id labore aliqua. sit ullamco in dolore occaecat commodo dolor,170
84,ut anim irure aute non consectetur Lorem nulla nisi amet commodo esse qui nostrud cupidatat enim quis consequat. elit eu ea in in dolor culpa labore et aliqua. do deserunt sunt ipsum laborum. cillum,316
62,in velit consequat. qui id eiusmod cupidatat sunt minim est sed Duis dolor aliquip culpa commodo reprehenderit eu officia anim,
80,ea qui in,
15,Ut dolor adipiscing et sunt exercitation ut sint sed pariatur. anim qui veniam ea id laborum. voluptate velit Duis ut in ad,
73,cupidatat Ut sint sunt irure et non ex aute do cillum amet aliqua. veniam laboris velit nostrud laborum. commodo pariatur. nisi in aliquip ullamco ipsum tempor in dolore adipiscing exercitation Lorem id culpa in,
52,ex dolore ad Lorem eu reprehenderit ipsum ut sunt proident aute exercitation pariatur. culpa do,
58,cillum exercitation laborum.,
74,Ut velit ea adipiscing eiusmod fugiat irure sit reprehenderit eu non aute in laboris esse veniam sint nulla aliqua. cupidatat enim magna id dolor tempor Lorem proident qui officia,
1,cupidatat ut aliqua. fugiat incididunt irure elit tempor Ut do pariatur. nisi ea aute ad,
2,ullamco eiusmod in magna id esse labore culpa Excepteur dolore irure occaecat ut dolor do velit adipiscing consequat. enim non proident deserunt ex,
14,officia ad ut eu et ullamco laboris,
17,ipsum ea non in ullamco in id dolore consequat. velit eu pariatur. exercitation nostrud enim Lorem Excepteur sit in occaecat,427
74,cillum aliqua. sint sit occaecat Lorem ut irure do Duis minim ea eu commodo non magna in et anim,
64,et consectetur eu culpa eiusmod deserunt dolore quis cupidatat ad nostrud velit esse voluptate Duis anim sed in ullamco ea officia fugiat in do amet irure in laborum. dolore nulla ut,
78,mollit laboris labore ea in qui voluptate quis nisi proident anim non dolor et ullamco occaecat deserunt cillum in sint exercitation sunt aliquip amet nulla est magna velit cupidatat incididunt irure Duis sed ut do id eu,
32,consequat. qui nulla labore cillum aute ex proident adipiscing amet aliqua. nisi anim Excepteur esse dolor non sint sit,
66,nisi nulla dolor Lorem culpa fugiat ut ut dolor Ut in cupidatat occaecat deserunt amet ipsum aliqua. Duis pariatur. quis dolore velit laborum. aute in non labore sit tempor esse eu nostrud ad do aliquip commodo officia est,270
65,sunt pariatur. Lorem voluptate ex laborum. velit ut aliquip ut consectetur incididunt mollit cupidatat exercitation esse fugiat aute officia sit tempor proident dolor Duis adipiscing in reprehenderit labore aliqua. eiusmod ipsum magna nisi anim,398
17,aliquip voluptate consequat. ut elit amet reprehenderit sed laborum. sint ad labore in fugiat ipsum in nulla dolor aute Duis anim Ut exercitation in enim occaecat tempor adipiscing esse nostrud sit id,106
9,ad exercitation ea veniam ut laboris proident sunt in occaecat pariatur. id,325
18,ad sunt,198
63,irure ex,
6,cupidatat occaecat,
93,minim ea qui aliqua. incididunt adipiscing cupidatat quis magna Duis sint cillum irure enim dolore ullamco eiusmod exercitation consequat. veniam commodo sunt occaecat reprehenderit do Ut et nostrud aute voluptate,
59,Ut proident ut ad non esse qui commodo culpa do cupidatat Duis dolore Lorem laboris anim eiusmod aliquip exercitation pariatur. dolor est tempor magna sit ex in elit in id nostrud irure adipiscing sunt eu,89
63,sit occaecat est adipiscing Duis irure culpa sint,106
48,ut labore anim quis adipiscing nulla mollit esse elit fugiat in officia tempor sunt pariatur. veniam occaecat in culpa consequat. sed ex minim Duis voluptate dolor,
56,in ea ut Lorem Duis dolore consequat. ex eiusmod in qui aute pariatur. sunt officia esse nulla mollit amet aliqua. commodo dolor irure,206
15,voluptate dolor eu Excepteur non dolore veniam ad,
\.

COPY facilities(facility_name, facility_location, facility_type) from stdin(FORMAT CSV);
Mercedes High school,1,School
Tebingtinggi High school,87,School
Svatove High school,72,School
Bhairāhawā High school,17,School
Partinico High school,55,School
Pederneiras High school,89,School
El Hamma High school,91,School
Lago da Pedra High school,72,School
Gressier High school,73,School
Conceição do Araguaia High school,53,School
Carcar High school,60,School
Fengxiang High school,19,School
Saint Neots High school,22,School
Găeşti High school,29,School
Carnaxide High school,11,School
Veinticinco de Mayo High school,42,School
Asha High school,16,School
Unaí High school,62,School
Osório High school,56,School
Nyalikungu High school,86,School
Estrela High school,40,School
Dazhong High school,1,School
Khŭjaobod High school,96,School
Yasenevo High school,83,School
Joinville High school,16,School
Espoo High school,97,School
Nahariya High school,85,School
Spassk-Dal’niy High school,33,School
Tanah Merah High school,2,School
Lebanon High school,70,School
Zambrów High school,59,School
Marano di Napoli High school,33,School
Thousand Oaks High school,82,School
Sesheke High school,17,School
Isabela High school,94,School
Zarya High school,10,School
Correggio High school,49,School
Spanish Lake High school,94,School
Bartlesville High school,41,School
Būsh High school,83,School
Lakewood High school,5,School
Hsinchu High school,27,School
Roman High school,6,School
Lauda-Königshofen High school,72,School
Cantel High school,16,School
Iwŏn-ŭp High school,78,School
Haan High school,56,School
Strakonice High school,84,School
Farmington High school,71,School
Gimcheon High school,14,School
Tirmitine High school,57,School
Pelabuhanratu High school,9,School
Pointe-à-Pitre High school,61,School
Mateus Leme High school,60,School
Lugazi High school,8,School
Teresina High school,77,School
Gisenyi High school,71,School
Harsewinkel High school,64,School
Khenifra High school,57,School
Giussano High school,8,School
Kitakata High school,21,School
Staryy Oskol High school,62,School
Warner Robins High school,45,School
Madīnat ‘Īsá High school,2,School
Paôy Pêt High school,7,School
Białogard High school,50,School
Pace High school,71,School
Téra High school,6,School
Omagh High school,99,School
Ellwangen High school,40,School
Frenda High school,80,School
Mahébourg High school,95,School
Smolyan High school,92,School
Ceadîr-Lunga High school,28,School
Amiens High school,71,School
Halle High school,42,School
Korolev High school,45,School
Zürich (Kreis 11) / Affoltern High school,96,School
Ayamonte High school,55,School
RMI Capitol High school,34,School
Ban Lam Luk Ka High school,88,School
Gero High school,36,School
Olomouc High school,94,School
Marseille 14 High school,9,School
Phatthalung High school,33,School
Jackson High school,38,School
Willowdale High school,68,School
Lille High school,35,School
El Monte High school,28,School
Germantown High school,46,School
Mirpur Khas High school,49,School
Metz High school,74,School
Borzya High school,79,School
Condado High school,66,School
Fengcheng High school,20,School
Shouguang High school,54,School
San José de Guanipa High school,89,School
Tecámac de Felipe Villanueva High school,50,School
Chhāgalnāiya High school,43,School
Hilden High school,94,School
\.

COPY facilities(facility_name, facility_location, facility_type) FROM stdin(FORMAT CSV);
ICBC,65,Work
China Construction Bank,91,Work
Berkshire Hathaway,6,Work
JPMorgan Chase,98,Work
Wells Fargo,61,Work
Agricultural Bank of China,65,Work
Bank of America,67,Work
Bank of China,73,Work
Apple,62,Work
Toyota Motor,72,Work
AT&T,91,Work
Citigroup,98,Work
Exxon Mobil,8,Work
General Electric,37,Work
Samsung Electronics,32,Work
Ping An Insurance Group,21,Work
Wal-Mart Stores,77,Work
Verizon Communications,74,Work
Microsoft,92,Work
Royal Dutch Shell,7,Work
Allianz,94,Work
China Mobile,25,Work
BNP Paribas,44,Work
Alphabet,98,Work
China Petroleum & Chemical,86,Work
Total,58,Work
AXA Group,16,Work
Daimler,80,Work
Volkswagen Group,74,Work
Mitsubishi UFJ Financial,89,Work
Comcast,86,Work
Johnson & Johnson,37,Work
Banco Santander,65,Work
Bank of Communications,21,Work
Nestle,55,Work
UnitedHealth Group,89,Work
Nippon Telegraph & Tel,26,Work
Itaú Unibanco Holding,54,Work
Softbank,7,Work
Gazprom,26,Work
General Motors,89,Work
China Merchants Bank,100,Work
IBM,66,Work
Royal Bank of Canada,96,Work
Japan Post Holdings,78,Work
Procter & Gamble,19,Work
Pfizer,44,Work
HSBC Holdings,47,Work
Goldman Sachs Group,23,Work
Siemens,56,Work
BMW Group,1,Work
China Life Insurance,74,Work
ING Group,3,Work
Intel,70,Work
Postal Savings Bank Of China,50,Work
Sberbank,98,Work
TD Bank Group,30,Work
Cisco Systems,26,Work
Commonwealth Bank,90,Work
Morgan Stanley,32,Work
Novartis,47,Work
Banco Bradesco,82,Work
Industrial Bank,44,Work
Ford Motor,19,Work
Shanghai Pudong Development,58,Work
CVS Health,51,Work
Walt Disney,23,Work
Prudential,55,Work
Prudential Financial,64,Work
Oracle,85,Work
China State Construction Engineering,13,Work
Citic Pacific,76,Work
Boeing,34,Work
Honda Motor,6,Work
China Minsheng Banking,23,Work
Westpac Banking Group,11,Work
Deutsche Telekom,4,Work
China Citic Bank,81,Work
Roche Holding,45,Work
UBS,91,Work
Bank of Nova Scotia,84,Work
Rosneft,32,Work
Amazon.com,68,Work
PepsiCo,6,Work
Sumitomo Mitsui Financial,86,Work
Coca-Cola,29,Work
United Technologies,46,Work
Sanofi,40,Work
Bayer,54,Work
Mizuho Financial,87,Work
Zurich Insurance Group,10,Work
ANZ,5,Work
BASF,8,Work
Walgreens Boots Alliance,36,Work
Nissan Motor,91,Work
US Bancorp,57,Work
American Express,81,Work
Hon Hai Precision,83,Work
Enel,39,Work
Merck,60,Work
\.

COPY facilities(facility_name, facility_location, facility_type) from stdin(FORMAT CSV);
Harvard University,82,University
Massachusetts Institute of Technology,25,University
Stanford University,18,University
University of Cambridge,63,University
University of Oxford,23,University
Columbia University,53,University
Princeton University,99,University
"University of California, Berkeley",39,University
University of Pennsylvania,98,University
University of Chicago,41,University
California Institute of Technology,3,University
Yale University,27,University
University of Tokyo,83,University
Cornell University,51,University
Northwestern University,83,University
"University of California, Los Angeles",23,University
"University of Michigan, Ann Arbor",40,University
Johns Hopkins University,89,University
University of Washington - Seattle,93,University
University of Illinois at Urbana–Champaign,7,University
Kyoto University,92,University
University College London,96,University
Duke University,58,University
University of Toronto,19,University
University of Wisconsin–Madison,4,University
New York University,47,University
University of California San Diego,84,University
Imperial College London,90,University
ETH Zurich,20,University
McGill University,57,University
University of Texas at Austin,39,University
École Polytechnique,59,University
Seoul National University,4,University
"University of California, San Francisco",3,University
Sorbonne University,16,University
University of North Carolina at Chapel Hill,81,University
University of Edinburgh,88,University
University of Minnesota - Twin Cities,2,University
University of Copenhagen,20,University
University of Texas Southwestern Medical Center,1,University
Washington University in St. Louis,65,University
Karolinska Institute,86,University
École normale supérieure,90,University
University of Southern California,86,University
Brown University,91,University
Vanderbilt University,74,University
Pennsylvania State University,55,University
Rutgers University–New Brunswick,56,University
Dartmouth College,54,University
"University of California, Davis",33,University
Ludwig Maximilian University of Munich,91,University
University of British Columbia,86,University
University of Virginia,78,University
Ohio State University,24,University
King's College London,41,University
University of Oslo,19,University
University of Colorado Boulder,46,University
Weizmann Institute of Science,34,University
Peking University,58,University
University of Manchester,29,University
Purdue University,62,University
Hebrew University of Jerusalem,28,University
University of Pittsburgh,6,University
University of Melbourne,81,University
"University of California, Irvine",97,University
"University of California, Santa Barbara",75,University
Rockefeller University,54,University
University of Zurich,6,University
University of Arizona,50,University
Tsinghua University,20,University
Free University of Berlin,83,University
Heidelberg University,71,University
Utrecht University,5,University
Boston University,25,University
National Taiwan University,68,University
Technical University of Munich,85,University
University of Bristol,68,University
Paris-Sud University,14,University
École Polytechnique Fédérale de Lausanne,37,University
Osaka University,90,University
University of Florida,54,University
Georgia Institute of Technology,36,University
University of Utah,66,University
Carnegie Mellon University,18,University
National University of Singapore,75,University
Keio University,59,University
"Texas A&M University, College Station",28,University
Paris Diderot University,12,University
University of Alberta,6,University
Emory University,73,University
University of Groningen,93,University
Leiden University,12,University
University of Texas MD Anderson Cancer Center,2,University
Tufts University,8,University
Aarhus University,93,University
University of Chinese Academy of Sciences,52,University
University of Rochester,4,University
Erasmus University Rotterdam,18,University
"University of Maryland, College Park",26,University
University of Sydney,37,University
