--
-- PostgreSQL database dump
--

-- Dumped from database version 12.6
-- Dumped by pg_dump version 12.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: game; Type: SCHEMA; Schema: -; Owner: game
--

CREATE SCHEMA game;


ALTER SCHEMA game OWNER TO game;

--
-- Name: add_user(character varying, character varying, character varying); Type: FUNCTION; Schema: game; Owner: game
--

CREATE FUNCTION game.add_user(user_name character varying, passwd character varying, fullname character varying) RETURNS integer
    LANGUAGE sql
    AS $$
INSERT
    INTO
    game.users (name,
    PASSWORD,
    full_name)
VALUES (user_name,
passwd,
fullname) RETURNING id;

$$;


ALTER FUNCTION game.add_user(user_name character varying, passwd character varying, fullname character varying) OWNER TO game;

--
-- Name: do_answer(integer, integer, integer); Type: FUNCTION; Schema: game; Owner: game
--

CREATE FUNCTION game.do_answer(player_id integer, question_id integer, user_answer integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    l_return_point     geometry := NULL;
    l_next_point_id    integer;
    l_current_answer   integer;
    l_current_question integer;

BEGIN
    SELECT correct_answer INTO l_current_answer FROM game.questions WHERE id = question_id;
    IF l_current_answer = user_answer THEN
        RAISE NOTICE 'Ответ верный';
        -- следующая точка
        SELECT next_point INTO l_next_point_id FROM game.questions WHERE id = question_id;
        -- следующий вопрос
        SELECT id INTO l_current_question FROM game.questions WHERE linked_point = l_next_point_id;
        IF l_current_question IS NOT NULL THEN
            INSERT INTO game.game (player, question)
            VALUES (player_id, l_current_question); -- штрафных очков нет
            --RETURN l_next_point_id;
        ELSE -- следующая null, конец. Назначить результирующие очки
            UPDATE game.game SET result = LOCALTIME - game.time_start + game.score WHERE game.player = player_id;
            RETURN NULL;
        END IF;
    ELSE
        RAISE NOTICE '';
        INSERT INTO game.game (player, score)
        VALUES (player_id, MAKE_INTERVAL(0, 0, 0, 0, 0, 15)); -- штрафные минуты (15)
        RETURN NULL;
    END IF;

    -- взять точку по id вопроса
    SELECT geom
    INTO l_return_point
    FROM game.points p
    WHERE id IN (
        SELECT linked_point
        FROM game.questions
        WHERE id IN
              (SELECT question FROM game.game WHERE player = player_id)
    );

    RETURN public.st_asgeojson(l_return_point, 7);
END;
$$;


ALTER FUNCTION game.do_answer(player_id integer, question_id integer, user_answer integer) OWNER TO game;

--
-- Name: get_question(integer); Type: FUNCTION; Schema: game; Owner: game
--

CREATE FUNCTION game.get_question(point_id integer) RETURNS json
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


ALTER FUNCTION game.get_question(point_id integer) OWNER TO game;

--
-- Name: make_buffer64(double precision, public.geometry); Type: FUNCTION; Schema: game; Owner: game
--

CREATE FUNCTION game.make_buffer64(radius_b double precision, pt public.geometry) RETURNS public.geometry
    LANGUAGE plpgsql
    AS $$
	BEGIN
		return public.st_buffer(pt::geography, radius_b);
	END;
$$;


ALTER FUNCTION game.make_buffer64(radius_b double precision, pt public.geometry) OWNER TO game;

--
-- Name: make_turn(integer); Type: FUNCTION; Schema: game; Owner: game
--

CREATE FUNCTION game.make_turn(player_id integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
        l_return_point geometry;
        l_current_player integer;
        l_current_question integer;
    BEGIN
        -- поиск игрока
        SELECT id INTO STRICT l_current_player FROM game.users WHERE id = player_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Игрок % не найден', player_id;
            RETURN NULL;
        END IF;
        SELECT id INTO l_current_player FROM game.game WHERE player = player_id;
        IF l_current_player IS NOT NULL THEN
            RAISE NOTICE 'Уже есть';
           -- при последующих ходах (после ответов) записи о новых вопросах и их точках вносит другая функция

        ELSE
            RAISE NOTICE 'Первый ход';
            SELECT id INTO l_current_question FROM game.questions WHERE id = 1;
            INSERT INTO game.game (player, question, score, time_start)
            VALUES (player_id, l_current_question, make_interval(),  localtime);
        END IF;
        -- взять первую точку
        SELECT geom INTO l_return_point FROM game.points p WHERE id in (
            SELECT linked_point FROM game.questions WHERE id in
            (SELECT question FROM game.game WHERE player = player_id)
        );

        RETURN public.st_asgeojson(l_return_point, 7);
    END;
$$;


ALTER FUNCTION game.make_turn(player_id integer) OWNER TO game;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: points; Type: TABLE; Schema: game; Owner: game
--

CREATE TABLE game.points (
    id integer NOT NULL,
    name character varying(100),
    geom public.geometry
);


ALTER TABLE game.points OWNER TO game;

--
-- Name: buffers; Type: VIEW; Schema: game; Owner: game
--

CREATE VIEW game.buffers AS
 SELECT points.id,
    points.name,
    game.make_buffer64((50.0)::double precision, points.geom) AS make_buffer64
   FROM game.points;


ALTER TABLE game.buffers OWNER TO game;

--
-- Name: game; Type: TABLE; Schema: game; Owner: game
--

CREATE TABLE game.game (
    id integer NOT NULL,
    player bigint NOT NULL,
    question bigint NOT NULL,
    score interval(0),
    time_start time(0) without time zone,
    result interval(0)
);


ALTER TABLE game.game OWNER TO game;

--
-- Name: game_id_seq; Type: SEQUENCE; Schema: game; Owner: game
--

CREATE SEQUENCE game.game_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE game.game_id_seq OWNER TO game;

--
-- Name: game_id_seq; Type: SEQUENCE OWNED BY; Schema: game; Owner: game
--

ALTER SEQUENCE game.game_id_seq OWNED BY game.game.id;


--
-- Name: points_id_seq; Type: SEQUENCE; Schema: game; Owner: game
--

CREATE SEQUENCE game.points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE game.points_id_seq OWNER TO game;

--
-- Name: points_id_seq; Type: SEQUENCE OWNED BY; Schema: game; Owner: game
--

ALTER SEQUENCE game.points_id_seq OWNED BY game.points.id;


--
-- Name: questions; Type: TABLE; Schema: game; Owner: game
--

CREATE TABLE game.questions (
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


ALTER TABLE game.questions OWNER TO game;

--
-- Name: questions_id_seq; Type: SEQUENCE; Schema: game; Owner: game
--

CREATE SEQUENCE game.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE game.questions_id_seq OWNER TO game;

--
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: game; Owner: game
--

ALTER SEQUENCE game.questions_id_seq OWNED BY game.questions.id;


--
-- Name: users; Type: TABLE; Schema: game; Owner: game
--

CREATE TABLE game.users (
    id integer NOT NULL,
    name character varying(20),
    password character varying(20),
    full_name character varying(100)
);


ALTER TABLE game.users OWNER TO game;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: game; Owner: game
--

CREATE SEQUENCE game.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE game.users_id_seq OWNER TO game;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: game; Owner: game
--

ALTER SEQUENCE game.users_id_seq OWNED BY game.users.id;


--
-- Name: game id; Type: DEFAULT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.game ALTER COLUMN id SET DEFAULT nextval('game.game_id_seq'::regclass);


--
-- Name: points id; Type: DEFAULT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.points ALTER COLUMN id SET DEFAULT nextval('game.points_id_seq'::regclass);


--
-- Name: questions id; Type: DEFAULT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.questions ALTER COLUMN id SET DEFAULT nextval('game.questions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.users ALTER COLUMN id SET DEFAULT nextval('game.users_id_seq'::regclass);


--
-- Data for Name: game; Type: TABLE DATA; Schema: game; Owner: game
--

COPY game.game (id, player, question, score, time_start, result) FROM stdin;
2	4	1	00:15:00	17:54:37	-11:13:28
\.


--
-- Data for Name: points; Type: TABLE DATA; Schema: game; Owner: game
--

COPY game.points (id, name, geom) FROM stdin;
1	Лицей Технополис	0101000020E6100000B2E7799E47CC5440CC051917A4774B40
2	Биотехнопарк	0101000020E6100000E01E307B20CC5440E2D872638B774B40
3	Школа №5	0101000020E6100000452EC8B8A0CB54408CAE10BA02784B40
5	Школа №21	0101000020E610000082FDBBF52FCC54407397AC5DF2784B40
6	Парк Кольцово	0101000020E61000000A12DC47B0CC54409DD7505E03794B40
4	Детская школа искусcтв	0101000020E61000004037B6DCD8CB5440734AB42951784B40
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: game; Owner: game
--

COPY game.questions (id, question, answer1, answer2, answer3, answer4, correct_answer, linked_point, next_point) FROM stdin;
2	Вопрос 2	Ответ 1	Ответ 2	Ответ 3	Ответ 4	3	2	4
3	Вопрос 3	Ответ 1	Ответ 2	Ответ 3	Ответ   4	2	4	3
4	Вопрос 4	Ответ 1	Ответ 2	Ответ 3	Ответ 4	1	3	\N
1	Вопрос 1	Ответ 1	Ответ 2	Ответ 3 	Ответ 4	2	1	2
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: game; Owner: game
--

COPY game.users (id, name, password, full_name) FROM stdin;
1	first	first	Первый игрок
2	second	second	Второй игрок
3	Me		Its me
4	вася	qwerty	Василий Миронов
\.


--
-- Name: game_id_seq; Type: SEQUENCE SET; Schema: game; Owner: game
--

SELECT pg_catalog.setval('game.game_id_seq', 2, true);


--
-- Name: points_id_seq; Type: SEQUENCE SET; Schema: game; Owner: game
--

SELECT pg_catalog.setval('game.points_id_seq', 1, false);


--
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: game; Owner: game
--

SELECT pg_catalog.setval('game.questions_id_seq', 3, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: game; Owner: game
--

SELECT pg_catalog.setval('game.users_id_seq', 4, true);


--
-- Name: game_pk; Type: INDEX; Schema: game; Owner: game
--

CREATE UNIQUE INDEX game_pk ON game.game USING btree (id);


--
-- Name: points_geom_idx; Type: INDEX; Schema: game; Owner: game
--

CREATE INDEX points_geom_idx ON game.points USING gist (geom);


--
-- Name: points_pk; Type: INDEX; Schema: game; Owner: game
--

CREATE UNIQUE INDEX points_pk ON game.points USING btree (id);


--
-- Name: questions_pk; Type: INDEX; Schema: game; Owner: game
--

CREATE UNIQUE INDEX questions_pk ON game.questions USING btree (id);


--
-- Name: users_pk; Type: INDEX; Schema: game; Owner: game
--

CREATE UNIQUE INDEX users_pk ON game.users USING btree (id);


--
-- Name: game game_fk; Type: FK CONSTRAINT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.game
    ADD CONSTRAINT game_fk FOREIGN KEY (question) REFERENCES game.questions(id) ON DELETE SET NULL;


--
-- Name: game game_fk_1; Type: FK CONSTRAINT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.game
    ADD CONSTRAINT game_fk_1 FOREIGN KEY (player) REFERENCES game.users(id) ON DELETE SET NULL;


--
-- Name: questions questions_fk; Type: FK CONSTRAINT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.questions
    ADD CONSTRAINT questions_fk FOREIGN KEY (linked_point) REFERENCES game.points(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- Name: questions questions_fk_next; Type: FK CONSTRAINT; Schema: game; Owner: game
--

ALTER TABLE ONLY game.questions
    ADD CONSTRAINT questions_fk_next FOREIGN KEY (next_point) REFERENCES game.points(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

