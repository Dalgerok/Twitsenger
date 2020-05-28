--GOOD
CREATE  TABLE locations ( 
	location_id          SERIAL	   ,
	city                 varchar   ,
	country              varchar   ,
	CONSTRAINT pk_location_id PRIMARY KEY ( location_id ),
	CONSTRAINT un_location UNIQUE (city, country)
 );
----

--GOOD
CREATE TYPE public.genders AS ENUM ( 'Male', 'Female', 'Unspecified' );

CREATE TYPE public.relationshipstatus AS ENUM ( 
'Married', 
'Single', 
'Engaged', 
'In a civil partnership', 
'In a domestic partnership', 
'In an open relationship', 
'It is complicated', 
'Separated', 
'Divorced', 
'Widowed' );
CREATE  TABLE users ( 
	user_id              SERIAL ,
	first_name           varchar(100)  NOT NULL ,
	last_name            varchar(100)  NOT NULL ,
	birthday             timestamp  NOT NULL ,
	email                varchar(254)  NOT NULL ,
	current_location_id  integer   ,
	relationship_status  relationshipstatus  NOT NULL ,
	gender               genders  NOT NULL ,
	hometown_location_id integer   ,
	picture_url 		 varchar(255),
	CONSTRAINT pk_tbl_user_id PRIMARY KEY ( user_id ),
	CONSTRAINT fk_user_location FOREIGN KEY ( current_location_id ) REFERENCES locations( location_id ) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT fk_user_location_0 FOREIGN KEY ( hometown_location_id ) REFERENCES locations( location_id ) ON DELETE SET NULL ON UPDATE CASCADE,  
 	CONSTRAINT ch_user_birthday CHECK ((now() - (birthday)::timestamp with time zone) >= '13 years'::interval year)
);

--BAD (NEED TRIGGERS)!!!
CREATE  TABLE friendrequest ( 
	from_whom            integer  NOT NULL ,
	to_whom              integer  NOT NULL ,
	request_date         timestamp DEFAULT CURRENT_DATE NOT NULL ,
	CONSTRAINT pk_friendrequest_from_whom PRIMARY KEY ( from_whom, to_whom ),
	CONSTRAINT fk_friendrequest_user FOREIGN KEY ( from_whom ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_friendrequest_user_0 FOREIGN KEY ( to_whom ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT ch_friendrequest CHECK (from_whom <> to_whom)
 );
CREATE  TABLE friendship ( 
	friend1              integer  NOT NULL ,
	friend2              integer  NOT NULL ,
	date_from            timestamp DEFAULT CURRENT_DATE NOT NULL ,
	CONSTRAINT pk_friendhsip PRIMARY KEY ( friend1, friend2 ),
	CONSTRAINT fk_friendship_user FOREIGN KEY ( friend1 ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_friendship_user_0 FOREIGN KEY ( friend2 ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT ch_friendship CHECK (friend1 <> friend2)
 );
----


--GOOD
CREATE  TABLE message ( 
	message_id           SERIAL ,
	user_from            integer  NOT NULL ,
	user_to              integer  NOT NULL ,
	message_text         varchar(250)  NOT NULL ,
	message_date         timestamp DEFAULT CURRENT_DATE NOT NULL ,
	CONSTRAINT pk_message_message_id PRIMARY KEY ( message_id ),
	CONSTRAINT fk_message_user FOREIGN KEY ( user_from ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_message_user_0 FOREIGN KEY ( user_to ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT ch_message CHECK (user_from <> user_to)
 );
----

--GOOD
CREATE  TABLE post ( 
	post_id              SERIAL ,
	user_id 			 integer NOT NULL,
	post_text         	 varchar(250)  NOT NULL ,
	post_date            timestamp DEFAULT CURRENT_DATE NOT NULL ,
	reposted_from        integer   ,
	CONSTRAINT pk_post_post_id PRIMARY KEY ( post_id ),
	CONSTRAINT fk_post_post FOREIGN KEY ( reposted_from ) REFERENCES post( post_id ) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT fk_user_post FOREIGN KEY ( user_id) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE
 );
----

--GOOD
CREATE  TABLE likesign ( 
	post_id              integer  NOT NULL ,
	user_id              integer  NOT NULL ,
	CONSTRAINT pk_likesign PRIMARY KEY ( post_id, user_id ),
	CONSTRAINT fk_likesign_user FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_likesign_post FOREIGN KEY ( post_id ) REFERENCES post( post_id ) ON DELETE CASCADE ON UPDATE CASCADE
 );
----

--GOOD
CREATE TABLE facility_type(
	facility_type_id SERIAL,
	facility_description varchar(100) NOT NULL,
	CONSTRAINT pk_facility_type PRIMARY KEY ( facility_type_id ),
	CONSTRAINT un_facility_description UNIQUE ( facility_description )
);
INSERT INTO facility_type(facility_description)
VALUES ('School'), ('University'), ('Work');

CREATE  TABLE facility ( 
	facility_id        SERIAL ,
	facility_name      varchar(100)  NOT NULL ,
	facility_location  integer NOT NULL,
	facility_type	   integer NOT NULL,
	CONSTRAINT pk_facility_id PRIMARY KEY ( facility_id ),
	CONSTRAINT fk_facility_location FOREIGN KEY ( facility_location ) REFERENCES locations( location_id ) ON DELETE CASCADE ON UPDATE CASCADE
 );
CREATE  TABLE userfacility ( 
	user_id              integer  NOT NULL ,
	facility_id          integer  NOT NULL ,
	date_from            timestamp  NOT NULL ,
	date_to              timestamp   ,
	description          varchar(100),
	CONSTRAINT pk_userfacility PRIMARY KEY ( user_id, facility_id, date_from ),
	CONSTRAINT fk_userfacility_user FOREIGN KEY ( user_id ) REFERENCES users( user_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_userfacility_facility FOREIGN KEY ( facility_id ) REFERENCES facility( facility_id ) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT ch_date CHECK ((date_to IS NULL) OR (date_to >= date_from))
 );
----