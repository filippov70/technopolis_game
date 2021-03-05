PGDMP                         y            game    12.5    12.5 *    n           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            o           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            p           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            q           1262    16385    game    DATABASE     v   CREATE DATABASE game WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
    DROP DATABASE game;
                game    false                        2615    24634    game    SCHEMA        CREATE SCHEMA game;
    DROP SCHEMA game;
                game    false            �           1255    24696    get_question(integer)    FUNCTION     �  CREATE FUNCTION game.get_question(point_id integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
    DECLARE 
    t_row game.questions%ROWTYPE;
    t_ret record;
	BEGIN
        SELECT QUESTION, ANSWER1, ANSWER2, ANSWER3, ANSWER4 INTO t_ret FROM game.questions where point_id = linked_point;
        RETURN to_json(t_ret);
        --SELECT * INTO t_row FROM game.questions where point_id = linked_point;
        --RETURN row_to_json(t_row);
	END;
$$;
 3   DROP FUNCTION game.get_question(point_id integer);
       game          game    false    5            �           1255    24635 0   make_buffer64(double precision, public.geometry)    FUNCTION     �   CREATE FUNCTION game.make_buffer64(radius_b double precision, pt public.geometry) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
	BEGIN
		return public.st_buffer(pt::geography, radius_b);
	END;
$$;
 Q   DROP FUNCTION game.make_buffer64(radius_b double precision, pt public.geometry);
       game          game    false    5            �           1255    24695    make_turn(integer)    FUNCTION     �  CREATE FUNCTION game.make_turn(player_id integer) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
    DECLARE 
        l_return_point geometry;
        l_current_player int4;
        
    BEGIN
        -- поиск игрока
        SELECT id INTO STRICT l_current_player FROM game.users WHERE id = player_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Игрок % не найден', player_id;
            RETURN NULL;
        END IF;
        -- взять первую точку по полю id
        SELECT geom INTO l_return_point FROM game.points p WHERE id = player_id;
        RETURN l_return_point;
    END;
$$;
 1   DROP FUNCTION game.make_turn(player_id integer);
       game          game    false    5            �            1259    24641    points    TABLE     q   CREATE TABLE game.points (
    id integer NOT NULL,
    name character varying(100),
    geom public.geometry
);
    DROP TABLE game.points;
       game         heap    game    false    5            �            1259    24691    buffers    VIEW     �   CREATE VIEW game.buffers AS
 SELECT points.id,
    points.name,
    game.make_buffer64((50.0)::double precision, points.geom) AS make_buffer64
   FROM game.points;
    DROP VIEW game.buffers;
       game          game    false    219    219    923    219    5            �            1259    24636    game    TABLE     �   CREATE TABLE game.game (
    id integer NOT NULL,
    player bigint NOT NULL,
    question bigint NOT NULL,
    score interval(0),
    time_start time(0) without time zone
);
    DROP TABLE game.game;
       game         heap    game    false    5            �            1259    24639    game_id_seq    SEQUENCE     �   CREATE SEQUENCE game.game_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
     DROP SEQUENCE game.game_id_seq;
       game          game    false    217    5            r           0    0    game_id_seq    SEQUENCE OWNED BY     7   ALTER SEQUENCE game.game_id_seq OWNED BY game.game.id;
          game          game    false    218            �            1259    24647    points_id_seq    SEQUENCE     �   CREATE SEQUENCE game.points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE game.points_id_seq;
       game          game    false    5    219            s           0    0    points_id_seq    SEQUENCE OWNED BY     ;   ALTER SEQUENCE game.points_id_seq OWNED BY game.points.id;
          game          game    false    220            �            1259    24649 	   questions    TABLE     ?  CREATE TABLE game.questions (
    id integer NOT NULL,
    question text NOT NULL,
    answer1 character varying(100),
    answer2 character varying(100),
    answer3 character varying(100),
    answer4 character varying(100),
    correct_answer character(1),
    linked_point bigint NOT NULL,
    next_point bigint
);
    DROP TABLE game.questions;
       game         heap    game    false    5            �            1259    24655    questions_id_seq    SEQUENCE     �   CREATE SEQUENCE game.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE game.questions_id_seq;
       game          game    false    5    221            t           0    0    questions_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE game.questions_id_seq OWNED BY game.questions.id;
          game          game    false    222            �            1259    24657    users    TABLE     �   CREATE TABLE game.users (
    id integer NOT NULL,
    name character varying(20),
    password character varying(20),
    full_name character varying(100)
);
    DROP TABLE game.users;
       game         heap    game    false    5            �            1259    24660    users_id_seq    SEQUENCE     �   CREATE SEQUENCE game.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE game.users_id_seq;
       game          game    false    223    5            u           0    0    users_id_seq    SEQUENCE OWNED BY     9   ALTER SEQUENCE game.users_id_seq OWNED BY game.users.id;
          game          game    false    224            �           2604    24662    game id    DEFAULT     ^   ALTER TABLE ONLY game.game ALTER COLUMN id SET DEFAULT nextval('game.game_id_seq'::regclass);
 4   ALTER TABLE game.game ALTER COLUMN id DROP DEFAULT;
       game          game    false    218    217            �           2604    24663 	   points id    DEFAULT     b   ALTER TABLE ONLY game.points ALTER COLUMN id SET DEFAULT nextval('game.points_id_seq'::regclass);
 6   ALTER TABLE game.points ALTER COLUMN id DROP DEFAULT;
       game          game    false    220    219            �           2604    24664    questions id    DEFAULT     h   ALTER TABLE ONLY game.questions ALTER COLUMN id SET DEFAULT nextval('game.questions_id_seq'::regclass);
 9   ALTER TABLE game.questions ALTER COLUMN id DROP DEFAULT;
       game          game    false    222    221            �           2604    24665    users id    DEFAULT     `   ALTER TABLE ONLY game.users ALTER COLUMN id SET DEFAULT nextval('game.users_id_seq'::regclass);
 5   ALTER TABLE game.users ALTER COLUMN id DROP DEFAULT;
       game          game    false    224    223            d          0    24636    game 
   TABLE DATA           E   COPY game.game (id, player, question, score, time_start) FROM stdin;
    game          game    false    217            f          0    24641    points 
   TABLE DATA           .   COPY game.points (id, name, geom) FROM stdin;
    game          game    false    219            h          0    24649 	   questions 
   TABLE DATA           }   COPY game.questions (id, question, answer1, answer2, answer3, answer4, correct_answer, linked_point, next_point) FROM stdin;
    game          game    false    221            j          0    24657    users 
   TABLE DATA           <   COPY game.users (id, name, password, full_name) FROM stdin;
    game          game    false    223            v           0    0    game_id_seq    SEQUENCE SET     7   SELECT pg_catalog.setval('game.game_id_seq', 1, true);
          game          game    false    218            w           0    0    points_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('game.points_id_seq', 1, false);
          game          game    false    220            x           0    0    questions_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('game.questions_id_seq', 1, false);
          game          game    false    222            y           0    0    users_id_seq    SEQUENCE SET     8   SELECT pg_catalog.setval('game.users_id_seq', 2, true);
          game          game    false    224            �           1259    24666    game_pk    INDEX     ;   CREATE UNIQUE INDEX game_pk ON game.game USING btree (id);
    DROP INDEX game.game_pk;
       game            game    false    217            �           1259    24667    points_geom_idx    INDEX     ?   CREATE INDEX points_geom_idx ON game.points USING gist (geom);
 !   DROP INDEX game.points_geom_idx;
       game            game    false    219            �           1259    24668 	   points_pk    INDEX     ?   CREATE UNIQUE INDEX points_pk ON game.points USING btree (id);
    DROP INDEX game.points_pk;
       game            game    false    219            �           1259    24669    questions_pk    INDEX     E   CREATE UNIQUE INDEX questions_pk ON game.questions USING btree (id);
    DROP INDEX game.questions_pk;
       game            game    false    221            �           1259    24670    users_pk    INDEX     =   CREATE UNIQUE INDEX users_pk ON game.users USING btree (id);
    DROP INDEX game.users_pk;
       game            game    false    223            �           2606    24671    game game_fk    FK CONSTRAINT        ALTER TABLE ONLY game.game
    ADD CONSTRAINT game_fk FOREIGN KEY (question) REFERENCES game.questions(id) ON DELETE SET NULL;
 4   ALTER TABLE ONLY game.game DROP CONSTRAINT game_fk;
       game          game    false    4314    221    217            �           2606    24676    game game_fk_1    FK CONSTRAINT     {   ALTER TABLE ONLY game.game
    ADD CONSTRAINT game_fk_1 FOREIGN KEY (player) REFERENCES game.users(id) ON DELETE SET NULL;
 6   ALTER TABLE ONLY game.game DROP CONSTRAINT game_fk_1;
       game          game    false    217    4315    223            �           2606    24681    questions questions_fk    FK CONSTRAINT     �   ALTER TABLE ONLY game.questions
    ADD CONSTRAINT questions_fk FOREIGN KEY (linked_point) REFERENCES game.points(id) ON UPDATE SET NULL ON DELETE SET NULL;
 >   ALTER TABLE ONLY game.questions DROP CONSTRAINT questions_fk;
       game          game    false    219    221    4313            �           2606    24686    questions questions_fk_next    FK CONSTRAINT     �   ALTER TABLE ONLY game.questions
    ADD CONSTRAINT questions_fk_next FOREIGN KEY (next_point) REFERENCES game.points(id) ON UPDATE SET NULL ON DELETE SET NULL;
 C   ALTER TABLE ONLY game.questions DROP CONSTRAINT questions_fk_next;
       game          game    false    221    219    4313            d       x�3�4B+0�44�26�26����� F�      f     x�m�KJ�0�q���@NN��d�WW�̍x�A�@p�\�p�X�p�Wb�PD�>��?�1]��*~�C���3���cS��_>���0%y���A	#�J"�$�X�yH�?^�ι_�"�X9�Y�4aSk�hu���Oy����A� Ra��iލ��6
p���Ec�k�s�Y�B��4?�E*~�t��x��
V`���̄@
T����ɂ��B۴�Ѻ����o�q{��Eڜ��k������;S-��h�XҞ��e����      h   J   x�3�0�¾�/6\�w�QA���¼�M6]�z�	�c��1V@�pqrq�fD�Y�F3����� L�P�      j   B   x�3�L�,*.���_�z��¦��v*\�qa3����..#������ua�Ŧ���(�b���� ��+     