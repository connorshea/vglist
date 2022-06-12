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
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    wikidata_id bigint
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: company_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_versions (
    id bigint NOT NULL,
    item_type text NOT NULL,
    item_id bigint NOT NULL,
    event text NOT NULL,
    whodunnit text,
    whodunnit_id bigint,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone
);


--
-- Name: company_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.company_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.company_versions_id_seq OWNED BY public.company_versions.id;


--
-- Name: engine_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.engine_versions (
    id bigint NOT NULL,
    item_type text NOT NULL,
    item_id bigint NOT NULL,
    event text NOT NULL,
    whodunnit text,
    whodunnit_id bigint,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone
);


--
-- Name: engine_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.engine_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: engine_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.engine_versions_id_seq OWNED BY public.engine_versions.id;


--
-- Name: engines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.engines (
    id bigint NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    wikidata_id bigint
);


--
-- Name: engines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.engines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: engines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.engines_id_seq OWNED BY public.engines.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    eventable_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    event_category integer NOT NULL,
    differences jsonb,
    eventable_type character varying,
    CONSTRAINT event_category_type_check CHECK ((((event_category = ANY (ARRAY[0, 1])) AND ((eventable_type)::text = 'GamePurchase'::text)) OR ((event_category = 2) AND ((eventable_type)::text = 'FavoriteGame'::text)) OR ((event_category = 3) AND ((eventable_type)::text = 'User'::text)) OR ((event_category = 4) AND ((eventable_type)::text = 'Relationship'::text))))
);


--
-- Name: events_favorite_game_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_favorite_game_events (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    eventable_id bigint NOT NULL,
    event_category integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: events_game_purchase_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_game_purchase_events (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    eventable_id bigint NOT NULL,
    differences jsonb,
    event_category integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: events_relationship_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_relationship_events (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    eventable_id bigint NOT NULL,
    event_category integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: events_user_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_user_events (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id bigint NOT NULL,
    eventable_id bigint NOT NULL,
    event_category integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: external_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_accounts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_type integer NOT NULL,
    steam_id bigint,
    steam_profile_url text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_accounts_id_seq OWNED BY public.external_accounts.id;


--
-- Name: favorite_games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_games (
    id bigint NOT NULL,
    game_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: favorite_games_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.favorite_games_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favorite_games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.favorite_games_id_seq OWNED BY public.favorite_games.id;


--
-- Name: friendly_id_slugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendly_id_slugs (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    sluggable_id integer NOT NULL,
    sluggable_type character varying(50),
    scope character varying,
    created_at timestamp without time zone
);


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.friendly_id_slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.friendly_id_slugs_id_seq OWNED BY public.friendly_id_slugs.id;


--
-- Name: game_developers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_developers (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    company_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: game_developers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_developers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_developers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_developers_id_seq OWNED BY public.game_developers.id;


--
-- Name: game_engines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_engines (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    engine_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: game_engines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_engines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_engines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_engines_id_seq OWNED BY public.game_engines.id;


--
-- Name: game_genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_genres (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    genre_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: game_genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_genres_id_seq OWNED BY public.game_genres.id;


--
-- Name: game_platforms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_platforms (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    platform_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: game_platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_platforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_platforms_id_seq OWNED BY public.game_platforms.id;


--
-- Name: game_publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_publishers (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    company_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: game_publishers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_publishers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_publishers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_publishers_id_seq OWNED BY public.game_publishers.id;


--
-- Name: game_purchase_platforms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_purchase_platforms (
    id bigint NOT NULL,
    game_purchase_id bigint NOT NULL,
    platform_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: game_purchase_platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_purchase_platforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_purchase_platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_purchase_platforms_id_seq OWNED BY public.game_purchase_platforms.id;


--
-- Name: game_purchase_stores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_purchase_stores (
    id bigint NOT NULL,
    game_purchase_id bigint NOT NULL,
    store_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: game_purchase_stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_purchase_stores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_purchase_stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_purchase_stores_id_seq OWNED BY public.game_purchase_stores.id;


--
-- Name: game_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_purchases (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    user_id bigint NOT NULL,
    comments text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    rating integer,
    completion_status integer,
    start_date date,
    completion_date date,
    hours_played numeric(10,1),
    replay_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT game_purchases_replay_count_not_negative CHECK ((replay_count >= 0))
);


--
-- Name: game_purchases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_purchases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_purchases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_purchases_id_seq OWNED BY public.game_purchases.id;


--
-- Name: game_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_versions (
    id bigint NOT NULL,
    item_type text NOT NULL,
    item_id bigint NOT NULL,
    event text NOT NULL,
    whodunnit text,
    whodunnit_id bigint,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone
);


--
-- Name: game_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_versions_id_seq OWNED BY public.game_versions.id;


--
-- Name: games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.games (
    id bigint NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    series_id bigint,
    wikidata_id bigint,
    pcgamingwiki_id text,
    mobygames_id text,
    release_date date,
    giantbomb_id text,
    epic_games_store_id text,
    gog_id text,
    avg_rating double precision,
    igdb_id text
);


--
-- Name: games_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.games_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.games_id_seq OWNED BY public.games.id;


--
-- Name: genre_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genre_versions (
    id bigint NOT NULL,
    item_type text NOT NULL,
    item_id bigint NOT NULL,
    event text NOT NULL,
    whodunnit text,
    whodunnit_id bigint,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone
);


--
-- Name: genre_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genre_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genre_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genre_versions_id_seq OWNED BY public.genre_versions.id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genres (
    id bigint NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    wikidata_id bigint
);


--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genres_id_seq OWNED BY public.genres.id;


--
-- Name: unmatched_games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unmatched_games (
    id bigint NOT NULL,
    user_id bigint,
    external_service_id text,
    external_service_name text,
    name text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT validate_external_service_name CHECK ((external_service_name = 'Steam'::text))
);


--
-- Name: TABLE unmatched_games; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.unmatched_games IS 'Games imported from a third party service, such as Steam, that we weren''t able to match to a game in vglist.';


--
-- Name: COLUMN unmatched_games.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unmatched_games.user_id IS 'The ID of the user that tried to import this game, can be null if the user deleted their account.';


--
-- Name: COLUMN unmatched_games.external_service_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unmatched_games.external_service_id IS 'The ID of the game on the external service, e.g. the Steam AppID.';


--
-- Name: COLUMN unmatched_games.external_service_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unmatched_games.external_service_name IS 'The name of the service we''re trying to import from, e.g. Steam.';


--
-- Name: COLUMN unmatched_games.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.unmatched_games.name IS 'The name of the game that was imported.';


--
-- Name: grouped_unmatched_games; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.grouped_unmatched_games AS
 SELECT count(*) AS count,
    unmatched_games.external_service_id,
    unmatched_games.external_service_name,
    array_agg(unmatched_games.name) AS names
   FROM public.unmatched_games
  GROUP BY unmatched_games.external_service_id, unmatched_games.external_service_name
  ORDER BY (count(*)) DESC;


--
-- Name: new_events; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.new_events AS
 SELECT events_game_purchase_events.id,
    events_game_purchase_events.user_id,
    events_game_purchase_events.eventable_id,
    events_game_purchase_events.differences,
    events_game_purchase_events.event_category,
    events_game_purchase_events.created_at,
    events_game_purchase_events.updated_at,
    'GamePurchase'::text AS eventable_type
   FROM public.events_game_purchase_events
UNION ALL
 SELECT events_favorite_game_events.id,
    events_favorite_game_events.user_id,
    events_favorite_game_events.eventable_id,
    NULL::jsonb AS differences,
    events_favorite_game_events.event_category,
    events_favorite_game_events.created_at,
    events_favorite_game_events.updated_at,
    'FavoriteGame'::text AS eventable_type
   FROM public.events_favorite_game_events
UNION ALL
 SELECT events_user_events.id,
    events_user_events.user_id,
    events_user_events.eventable_id,
    NULL::jsonb AS differences,
    events_user_events.event_category,
    events_user_events.created_at,
    events_user_events.updated_at,
    'User'::text AS eventable_type
   FROM public.events_user_events
UNION ALL
 SELECT events_relationship_events.id,
    events_relationship_events.user_id,
    events_relationship_events.eventable_id,
    NULL::jsonb AS differences,
    events_relationship_events.event_category,
    events_relationship_events.created_at,
    events_relationship_events.updated_at,
    'Relationship'::text AS eventable_type
   FROM public.events_relationship_events;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id bigint NOT NULL,
    resource_owner_id bigint NOT NULL,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    revoked_at timestamp without time zone
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id bigint NOT NULL,
    resource_owner_id bigint,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id bigint NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    owner_id integer,
    owner_type character varying
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pg_search_documents (
    id bigint NOT NULL,
    content text,
    searchable_type character varying,
    searchable_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pg_search_documents_id_seq OWNED BY public.pg_search_documents.id;


--
-- Name: platform_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_versions (
    id bigint NOT NULL,
    item_type text NOT NULL,
    item_id bigint NOT NULL,
    event text NOT NULL,
    whodunnit text,
    whodunnit_id bigint,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone
);


--
-- Name: platform_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platform_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platform_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platform_versions_id_seq OWNED BY public.platform_versions.id;


--
-- Name: platforms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platforms (
    id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    wikidata_id bigint
);


--
-- Name: platforms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platforms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platforms_id_seq OWNED BY public.platforms.id;


--
-- Name: relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationships (
    id bigint NOT NULL,
    follower_id bigint NOT NULL,
    followed_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.relationships_id_seq OWNED BY public.relationships.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: series; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.series (
    id bigint NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    wikidata_id bigint
);


--
-- Name: series_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.series_id_seq OWNED BY public.series.id;


--
-- Name: series_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.series_versions (
    id bigint NOT NULL,
    item_type text NOT NULL,
    item_id bigint NOT NULL,
    event text NOT NULL,
    whodunnit text,
    whodunnit_id bigint,
    object jsonb,
    object_changes jsonb,
    created_at timestamp without time zone
);


--
-- Name: series_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.series_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: series_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.series_versions_id_seq OWNED BY public.series_versions.id;


--
-- Name: statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistics (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    users integer NOT NULL,
    games integer NOT NULL,
    platforms integer NOT NULL,
    series integer NOT NULL,
    engines integer NOT NULL,
    companies integer NOT NULL,
    genres integer NOT NULL,
    stores integer NOT NULL,
    events integer NOT NULL,
    game_purchases integer NOT NULL,
    relationships integer NOT NULL,
    games_with_covers integer NOT NULL,
    games_with_release_dates integer NOT NULL,
    banned_users integer NOT NULL,
    mobygames_ids integer NOT NULL,
    pcgamingwiki_ids integer NOT NULL,
    wikidata_ids integer NOT NULL,
    giantbomb_ids integer NOT NULL,
    steam_app_ids integer NOT NULL,
    epic_games_store_ids integer NOT NULL,
    gog_ids integer NOT NULL,
    company_versions bigint,
    game_versions bigint,
    genre_versions bigint,
    engine_versions bigint,
    platform_versions bigint,
    series_versions bigint,
    igdb_ids bigint,
    unmatched_games bigint
);


--
-- Name: statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistics_id_seq OWNED BY public.statistics.id;


--
-- Name: steam_app_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.steam_app_ids (
    id bigint NOT NULL,
    game_id bigint NOT NULL,
    app_id integer NOT NULL
);


--
-- Name: steam_app_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.steam_app_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: steam_app_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.steam_app_ids_id_seq OWNED BY public.steam_app_ids.id;


--
-- Name: steam_blocklist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.steam_blocklist (
    id bigint NOT NULL,
    steam_app_id bigint NOT NULL,
    name text NOT NULL,
    user_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: steam_blocklist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.steam_blocklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: steam_blocklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.steam_blocklist_id_seq OWNED BY public.steam_blocklist.id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stores (
    id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stores_id_seq OWNED BY public.stores.id;


--
-- Name: unmatched_games_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unmatched_games_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unmatched_games_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unmatched_games_id_seq OWNED BY public.unmatched_games.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    username text NOT NULL,
    bio text DEFAULT ''::text NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    slug character varying,
    privacy integer DEFAULT 0 NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    encrypted_api_token character varying,
    hide_days_played boolean DEFAULT false
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: wikidata_blocklist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wikidata_blocklist (
    id bigint NOT NULL,
    wikidata_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name text NOT NULL,
    user_id bigint
);


--
-- Name: wikidata_blocklist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wikidata_blocklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wikidata_blocklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wikidata_blocklist_id_seq OWNED BY public.wikidata_blocklist.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: company_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_versions ALTER COLUMN id SET DEFAULT nextval('public.company_versions_id_seq'::regclass);


--
-- Name: engine_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.engine_versions ALTER COLUMN id SET DEFAULT nextval('public.engine_versions_id_seq'::regclass);


--
-- Name: engines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.engines ALTER COLUMN id SET DEFAULT nextval('public.engines_id_seq'::regclass);


--
-- Name: external_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_accounts ALTER COLUMN id SET DEFAULT nextval('public.external_accounts_id_seq'::regclass);


--
-- Name: favorite_games id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_games ALTER COLUMN id SET DEFAULT nextval('public.favorite_games_id_seq'::regclass);


--
-- Name: friendly_id_slugs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs ALTER COLUMN id SET DEFAULT nextval('public.friendly_id_slugs_id_seq'::regclass);


--
-- Name: game_developers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_developers ALTER COLUMN id SET DEFAULT nextval('public.game_developers_id_seq'::regclass);


--
-- Name: game_engines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_engines ALTER COLUMN id SET DEFAULT nextval('public.game_engines_id_seq'::regclass);


--
-- Name: game_genres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_genres ALTER COLUMN id SET DEFAULT nextval('public.game_genres_id_seq'::regclass);


--
-- Name: game_platforms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_platforms ALTER COLUMN id SET DEFAULT nextval('public.game_platforms_id_seq'::regclass);


--
-- Name: game_publishers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_publishers ALTER COLUMN id SET DEFAULT nextval('public.game_publishers_id_seq'::regclass);


--
-- Name: game_purchase_platforms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_platforms ALTER COLUMN id SET DEFAULT nextval('public.game_purchase_platforms_id_seq'::regclass);


--
-- Name: game_purchase_stores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_stores ALTER COLUMN id SET DEFAULT nextval('public.game_purchase_stores_id_seq'::regclass);


--
-- Name: game_purchases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchases ALTER COLUMN id SET DEFAULT nextval('public.game_purchases_id_seq'::regclass);


--
-- Name: game_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_versions ALTER COLUMN id SET DEFAULT nextval('public.game_versions_id_seq'::regclass);


--
-- Name: games id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.games ALTER COLUMN id SET DEFAULT nextval('public.games_id_seq'::regclass);


--
-- Name: genre_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genre_versions ALTER COLUMN id SET DEFAULT nextval('public.genre_versions_id_seq'::regclass);


--
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genres_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- Name: pg_search_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents ALTER COLUMN id SET DEFAULT nextval('public.pg_search_documents_id_seq'::regclass);


--
-- Name: platform_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_versions ALTER COLUMN id SET DEFAULT nextval('public.platform_versions_id_seq'::regclass);


--
-- Name: platforms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platforms ALTER COLUMN id SET DEFAULT nextval('public.platforms_id_seq'::regclass);


--
-- Name: relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships ALTER COLUMN id SET DEFAULT nextval('public.relationships_id_seq'::regclass);


--
-- Name: series id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series ALTER COLUMN id SET DEFAULT nextval('public.series_id_seq'::regclass);


--
-- Name: series_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series_versions ALTER COLUMN id SET DEFAULT nextval('public.series_versions_id_seq'::regclass);


--
-- Name: statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistics ALTER COLUMN id SET DEFAULT nextval('public.statistics_id_seq'::regclass);


--
-- Name: steam_app_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steam_app_ids ALTER COLUMN id SET DEFAULT nextval('public.steam_app_ids_id_seq'::regclass);


--
-- Name: steam_blocklist id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steam_blocklist ALTER COLUMN id SET DEFAULT nextval('public.steam_blocklist_id_seq'::regclass);


--
-- Name: stores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores ALTER COLUMN id SET DEFAULT nextval('public.stores_id_seq'::regclass);


--
-- Name: unmatched_games id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unmatched_games ALTER COLUMN id SET DEFAULT nextval('public.unmatched_games_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wikidata_blocklist id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wikidata_blocklist ALTER COLUMN id SET DEFAULT nextval('public.wikidata_blocklist_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_versions company_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_versions
    ADD CONSTRAINT company_versions_pkey PRIMARY KEY (id);


--
-- Name: engine_versions engine_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.engine_versions
    ADD CONSTRAINT engine_versions_pkey PRIMARY KEY (id);


--
-- Name: engines engines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.engines
    ADD CONSTRAINT engines_pkey PRIMARY KEY (id);


--
-- Name: events_favorite_game_events events_favorite_game_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_favorite_game_events
    ADD CONSTRAINT events_favorite_game_events_pkey PRIMARY KEY (id);


--
-- Name: events_game_purchase_events events_game_purchase_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_game_purchase_events
    ADD CONSTRAINT events_game_purchase_events_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: events_relationship_events events_relationship_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_relationship_events
    ADD CONSTRAINT events_relationship_events_pkey PRIMARY KEY (id);


--
-- Name: events_user_events events_user_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_user_events
    ADD CONSTRAINT events_user_events_pkey PRIMARY KEY (id);


--
-- Name: external_accounts external_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_accounts
    ADD CONSTRAINT external_accounts_pkey PRIMARY KEY (id);


--
-- Name: favorite_games favorite_games_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_games
    ADD CONSTRAINT favorite_games_pkey PRIMARY KEY (id);


--
-- Name: friendly_id_slugs friendly_id_slugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs
    ADD CONSTRAINT friendly_id_slugs_pkey PRIMARY KEY (id);


--
-- Name: game_developers game_developers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_developers
    ADD CONSTRAINT game_developers_pkey PRIMARY KEY (id);


--
-- Name: game_engines game_engines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_engines
    ADD CONSTRAINT game_engines_pkey PRIMARY KEY (id);


--
-- Name: game_genres game_genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_genres
    ADD CONSTRAINT game_genres_pkey PRIMARY KEY (id);


--
-- Name: game_platforms game_platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_platforms
    ADD CONSTRAINT game_platforms_pkey PRIMARY KEY (id);


--
-- Name: game_publishers game_publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_publishers
    ADD CONSTRAINT game_publishers_pkey PRIMARY KEY (id);


--
-- Name: game_purchase_platforms game_purchase_platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_platforms
    ADD CONSTRAINT game_purchase_platforms_pkey PRIMARY KEY (id);


--
-- Name: game_purchase_stores game_purchase_stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_stores
    ADD CONSTRAINT game_purchase_stores_pkey PRIMARY KEY (id);


--
-- Name: game_purchases game_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchases
    ADD CONSTRAINT game_purchases_pkey PRIMARY KEY (id);


--
-- Name: game_versions game_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_versions
    ADD CONSTRAINT game_versions_pkey PRIMARY KEY (id);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: genre_versions genre_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genre_versions
    ADD CONSTRAINT genre_versions_pkey PRIMARY KEY (id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: pg_search_documents pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: platform_versions platform_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_versions
    ADD CONSTRAINT platform_versions_pkey PRIMARY KEY (id);


--
-- Name: platforms platforms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (id);


--
-- Name: relationships relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: series series_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_pkey PRIMARY KEY (id);


--
-- Name: series_versions series_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.series_versions
    ADD CONSTRAINT series_versions_pkey PRIMARY KEY (id);


--
-- Name: statistics statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistics
    ADD CONSTRAINT statistics_pkey PRIMARY KEY (id);


--
-- Name: steam_app_ids steam_app_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steam_app_ids
    ADD CONSTRAINT steam_app_ids_pkey PRIMARY KEY (id);


--
-- Name: steam_blocklist steam_blocklist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steam_blocklist
    ADD CONSTRAINT steam_blocklist_pkey PRIMARY KEY (id);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: unmatched_games unmatched_games_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unmatched_games
    ADD CONSTRAINT unmatched_games_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wikidata_blocklist wikidata_blocklist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wikidata_blocklist
    ADD CONSTRAINT wikidata_blocklist_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_companies_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_companies_on_wikidata_id ON public.companies USING btree (wikidata_id);


--
-- Name: index_company_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_versions_on_item_type_and_item_id ON public.company_versions USING btree (item_type, item_id);


--
-- Name: index_engine_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_engine_versions_on_item_type_and_item_id ON public.engine_versions USING btree (item_type, item_id);


--
-- Name: index_engines_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_engines_on_wikidata_id ON public.engines USING btree (wikidata_id);


--
-- Name: index_events_favorite_game_events_on_eventable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_favorite_game_events_on_eventable_id ON public.events_favorite_game_events USING btree (eventable_id);


--
-- Name: index_events_favorite_game_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_favorite_game_events_on_user_id ON public.events_favorite_game_events USING btree (user_id);


--
-- Name: index_events_game_purchase_events_on_eventable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_game_purchase_events_on_eventable_id ON public.events_game_purchase_events USING btree (eventable_id);


--
-- Name: index_events_game_purchase_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_game_purchase_events_on_user_id ON public.events_game_purchase_events USING btree (user_id);


--
-- Name: index_events_on_eventable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_eventable_id ON public.events USING btree (eventable_id);


--
-- Name: index_events_on_id_type_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_id_type_and_user_id ON public.events USING btree (eventable_id, eventable_type, user_id);


--
-- Name: index_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_user_id ON public.events USING btree (user_id);


--
-- Name: index_events_relationship_events_on_eventable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_relationship_events_on_eventable_id ON public.events_relationship_events USING btree (eventable_id);


--
-- Name: index_events_relationship_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_relationship_events_on_user_id ON public.events_relationship_events USING btree (user_id);


--
-- Name: index_events_user_events_on_eventable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_user_events_on_eventable_id ON public.events_user_events USING btree (eventable_id);


--
-- Name: index_events_user_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_user_events_on_user_id ON public.events_user_events USING btree (user_id);


--
-- Name: index_external_accounts_on_steam_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_accounts_on_steam_id ON public.external_accounts USING btree (steam_id);


--
-- Name: index_external_accounts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_accounts_on_user_id ON public.external_accounts USING btree (user_id);


--
-- Name: index_external_accounts_on_user_id_and_account_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_accounts_on_user_id_and_account_type ON public.external_accounts USING btree (user_id, account_type);


--
-- Name: index_favorite_games_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_games_on_game_id ON public.favorite_games USING btree (game_id);


--
-- Name: index_favorite_games_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_games_on_user_id ON public.favorite_games USING btree (user_id);


--
-- Name: index_favorite_games_on_user_id_and_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_games_on_user_id_and_game_id ON public.favorite_games USING btree (user_id, game_id);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type ON public.friendly_id_slugs USING btree (slug, sluggable_type);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope ON public.friendly_id_slugs USING btree (slug, sluggable_type, scope);


--
-- Name: index_friendly_id_slugs_on_sluggable_type_and_sluggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_sluggable_type_and_sluggable_id ON public.friendly_id_slugs USING btree (sluggable_type, sluggable_id);


--
-- Name: index_game_developers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_developers_on_company_id ON public.game_developers USING btree (company_id);


--
-- Name: index_game_developers_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_developers_on_game_id ON public.game_developers USING btree (game_id);


--
-- Name: index_game_developers_on_game_id_and_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_developers_on_game_id_and_company_id ON public.game_developers USING btree (game_id, company_id);


--
-- Name: index_game_engines_on_engine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_engines_on_engine_id ON public.game_engines USING btree (engine_id);


--
-- Name: index_game_engines_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_engines_on_game_id ON public.game_engines USING btree (game_id);


--
-- Name: index_game_engines_on_game_id_and_engine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_engines_on_game_id_and_engine_id ON public.game_engines USING btree (game_id, engine_id);


--
-- Name: index_game_genres_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_genres_on_game_id ON public.game_genres USING btree (game_id);


--
-- Name: index_game_genres_on_game_id_and_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_genres_on_game_id_and_genre_id ON public.game_genres USING btree (game_id, genre_id);


--
-- Name: index_game_genres_on_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_genres_on_genre_id ON public.game_genres USING btree (genre_id);


--
-- Name: index_game_platforms_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_platforms_on_game_id ON public.game_platforms USING btree (game_id);


--
-- Name: index_game_platforms_on_game_id_and_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_platforms_on_game_id_and_platform_id ON public.game_platforms USING btree (game_id, platform_id);


--
-- Name: index_game_platforms_on_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_platforms_on_platform_id ON public.game_platforms USING btree (platform_id);


--
-- Name: index_game_publishers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_publishers_on_company_id ON public.game_publishers USING btree (company_id);


--
-- Name: index_game_publishers_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_publishers_on_game_id ON public.game_publishers USING btree (game_id);


--
-- Name: index_game_publishers_on_game_id_and_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_publishers_on_game_id_and_company_id ON public.game_publishers USING btree (game_id, company_id);


--
-- Name: index_game_purchase_platforms_on_game_purchase_and_platform; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_purchase_platforms_on_game_purchase_and_platform ON public.game_purchase_platforms USING btree (game_purchase_id, platform_id);


--
-- Name: index_game_purchase_platforms_on_game_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchase_platforms_on_game_purchase_id ON public.game_purchase_platforms USING btree (game_purchase_id);


--
-- Name: index_game_purchase_platforms_on_platform_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchase_platforms_on_platform_id ON public.game_purchase_platforms USING btree (platform_id);


--
-- Name: index_game_purchase_stores_on_game_purchase_and_store; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_purchase_stores_on_game_purchase_and_store ON public.game_purchase_stores USING btree (game_purchase_id, store_id);


--
-- Name: index_game_purchase_stores_on_game_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchase_stores_on_game_purchase_id ON public.game_purchase_stores USING btree (game_purchase_id);


--
-- Name: index_game_purchase_stores_on_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchase_stores_on_store_id ON public.game_purchase_stores USING btree (store_id);


--
-- Name: index_game_purchases_on_extant_rating_and_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchases_on_extant_rating_and_game_id ON public.game_purchases USING btree (rating, game_id) WHERE (rating IS NOT NULL);


--
-- Name: index_game_purchases_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchases_on_game_id ON public.game_purchases USING btree (game_id);


--
-- Name: index_game_purchases_on_game_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_purchases_on_game_id_and_user_id ON public.game_purchases USING btree (game_id, user_id);


--
-- Name: index_game_purchases_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_purchases_on_user_id ON public.game_purchases USING btree (user_id);


--
-- Name: index_game_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_versions_on_item_type_and_item_id ON public.game_versions USING btree (item_type, item_id);


--
-- Name: index_games_on_epic_games_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_games_on_epic_games_store_id ON public.games USING btree (epic_games_store_id);


--
-- Name: index_games_on_giantbomb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_games_on_giantbomb_id ON public.games USING btree (giantbomb_id);


--
-- Name: index_games_on_igdb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_games_on_igdb_id ON public.games USING btree (igdb_id);


--
-- Name: index_games_on_mobygames_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_games_on_mobygames_id ON public.games USING btree (mobygames_id);


--
-- Name: index_games_on_series_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_games_on_series_id ON public.games USING btree (series_id);


--
-- Name: index_games_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_games_on_wikidata_id ON public.games USING btree (wikidata_id);


--
-- Name: index_genre_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genre_versions_on_item_type_and_item_id ON public.genre_versions USING btree (item_type, item_id);


--
-- Name: index_genres_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_genres_on_wikidata_id ON public.genres USING btree (wikidata_id);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON public.oauth_access_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_applications_on_owner_id_and_owner_type ON public.oauth_applications USING btree (owner_id, owner_type);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_pg_search_documents_on_searchable_type_and_searchable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pg_search_documents_on_searchable_type_and_searchable_id ON public.pg_search_documents USING btree (searchable_type, searchable_id);


--
-- Name: index_platform_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_platform_versions_on_item_type_and_item_id ON public.platform_versions USING btree (item_type, item_id);


--
-- Name: index_platforms_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_platforms_on_wikidata_id ON public.platforms USING btree (wikidata_id);


--
-- Name: index_relationships_on_followed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relationships_on_followed_id ON public.relationships USING btree (followed_id);


--
-- Name: index_relationships_on_follower_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relationships_on_follower_id ON public.relationships USING btree (follower_id);


--
-- Name: index_relationships_on_follower_id_and_followed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_relationships_on_follower_id_and_followed_id ON public.relationships USING btree (follower_id, followed_id);


--
-- Name: index_series_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_series_on_wikidata_id ON public.series USING btree (wikidata_id);


--
-- Name: index_series_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_series_versions_on_item_type_and_item_id ON public.series_versions USING btree (item_type, item_id);


--
-- Name: index_steam_app_ids_on_app_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_steam_app_ids_on_app_id ON public.steam_app_ids USING btree (app_id);


--
-- Name: index_steam_app_ids_on_game_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steam_app_ids_on_game_id ON public.steam_app_ids USING btree (game_id);


--
-- Name: index_steam_blocklist_on_steam_app_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_steam_blocklist_on_steam_app_id ON public.steam_blocklist USING btree (steam_app_id);


--
-- Name: index_steam_blocklist_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_steam_blocklist_on_user_id ON public.steam_blocklist USING btree (user_id);


--
-- Name: index_unmatched_games_on_game_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unmatched_games_on_game_per_user ON public.unmatched_games USING btree (user_id, external_service_id, external_service_name) WHERE (user_id IS NOT NULL);


--
-- Name: index_unmatched_games_on_service_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unmatched_games_on_service_id_and_name ON public.unmatched_games USING btree (external_service_id, external_service_name);


--
-- Name: index_unmatched_games_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unmatched_games_on_user_id ON public.unmatched_games USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_slug ON public.users USING btree (slug);


--
-- Name: index_wikidata_blocklist_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wikidata_blocklist_on_user_id ON public.wikidata_blocklist USING btree (user_id);


--
-- Name: index_wikidata_blocklist_on_wikidata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_wikidata_blocklist_on_wikidata_id ON public.wikidata_blocklist USING btree (wikidata_id);


--
-- Name: events_relationship_events fk_rails_05a7410ab8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_relationship_events
    ADD CONSTRAINT fk_rails_05a7410ab8 FOREIGN KEY (eventable_id) REFERENCES public.relationships(id);


--
-- Name: game_purchase_platforms fk_rails_0727c9e126; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_platforms
    ADD CONSTRAINT fk_rails_0727c9e126 FOREIGN KEY (platform_id) REFERENCES public.platforms(id) ON DELETE CASCADE;


--
-- Name: game_platforms fk_rails_148d8deb91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_platforms
    ADD CONSTRAINT fk_rails_148d8deb91 FOREIGN KEY (platform_id) REFERENCES public.platforms(id) ON DELETE CASCADE;


--
-- Name: steam_app_ids fk_rails_153bcbca81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steam_app_ids
    ADD CONSTRAINT fk_rails_153bcbca81 FOREIGN KEY (game_id) REFERENCES public.games(id);


--
-- Name: game_purchase_stores fk_rails_23ebf1e596; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_stores
    ADD CONSTRAINT fk_rails_23ebf1e596 FOREIGN KEY (game_purchase_id) REFERENCES public.game_purchases(id) ON DELETE CASCADE;


--
-- Name: game_developers fk_rails_287ef661d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_developers
    ADD CONSTRAINT fk_rails_287ef661d2 FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: game_publishers fk_rails_3144a1efd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_publishers
    ADD CONSTRAINT fk_rails_3144a1efd9 FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: events_favorite_game_events fk_rails_31a149f860; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_favorite_game_events
    ADD CONSTRAINT fk_rails_31a149f860 FOREIGN KEY (eventable_id) REFERENCES public.favorite_games(id);


--
-- Name: oauth_access_grants fk_rails_330c32d8d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_330c32d8d9 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- Name: favorite_games fk_rails_3e7dcfb748; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_games
    ADD CONSTRAINT fk_rails_3e7dcfb748 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: game_developers fk_rails_4a2c4562f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_developers
    ADD CONSTRAINT fk_rails_4a2c4562f8 FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: events_game_purchase_events fk_rails_54d9eb6aa1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_game_purchase_events
    ADD CONSTRAINT fk_rails_54d9eb6aa1 FOREIGN KEY (eventable_id) REFERENCES public.game_purchases(id);


--
-- Name: game_publishers fk_rails_58a057ae0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_publishers
    ADD CONSTRAINT fk_rails_58a057ae0c FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: game_purchase_platforms fk_rails_5fec5902a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_platforms
    ADD CONSTRAINT fk_rails_5fec5902a9 FOREIGN KEY (game_purchase_id) REFERENCES public.game_purchases(id) ON DELETE CASCADE;


--
-- Name: games fk_rails_71c5ca4cdf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT fk_rails_71c5ca4cdf FOREIGN KEY (series_id) REFERENCES public.series(id) ON DELETE SET NULL;


--
-- Name: external_accounts fk_rails_71e339855b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_accounts
    ADD CONSTRAINT fk_rails_71e339855b FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: game_purchases fk_rails_7c90c810f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchases
    ADD CONSTRAINT fk_rails_7c90c810f6 FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: steam_blocklist fk_rails_862578ca5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.steam_blocklist
    ADD CONSTRAINT fk_rails_862578ca5c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: wikidata_blocklist fk_rails_8ade4916f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wikidata_blocklist
    ADD CONSTRAINT fk_rails_8ade4916f2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: relationships fk_rails_8c9a6d4759; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT fk_rails_8c9a6d4759 FOREIGN KEY (follower_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: game_purchase_stores fk_rails_9df80bc31c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchase_stores
    ADD CONSTRAINT fk_rails_9df80bc31c FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: relationships fk_rails_9f3075433a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT fk_rails_9f3075433a FOREIGN KEY (followed_id) REFERENCES public.users(id);


--
-- Name: favorite_games fk_rails_ac647def17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_games
    ADD CONSTRAINT fk_rails_ac647def17 FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: game_platforms fk_rails_b0825e253b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_platforms
    ADD CONSTRAINT fk_rails_b0825e253b FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: game_genres fk_rails_c26a013c96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_genres
    ADD CONSTRAINT fk_rails_c26a013c96 FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: events_user_events fk_rails_d08547655e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_user_events
    ADD CONSTRAINT fk_rails_d08547655e FOREIGN KEY (eventable_id) REFERENCES public.users(id);


--
-- Name: game_purchases fk_rails_d215b0a5c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_purchases
    ADD CONSTRAINT fk_rails_d215b0a5c1 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: game_genres fk_rails_e760a0ff73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_genres
    ADD CONSTRAINT fk_rails_e760a0ff73 FOREIGN KEY (genre_id) REFERENCES public.genres(id) ON DELETE CASCADE;


--
-- Name: game_engines fk_rails_e93911d53f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_engines
    ADD CONSTRAINT fk_rails_e93911d53f FOREIGN KEY (engine_id) REFERENCES public.engines(id) ON DELETE CASCADE;


--
-- Name: game_engines fk_rails_eb138dfb9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_engines
    ADD CONSTRAINT fk_rails_eb138dfb9a FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens fk_rails_ee63f25419; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_ee63f25419 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20181229014249'),
('20181229041436'),
('20181229041526'),
('20181229041603'),
('20181229041801'),
('20181230003903'),
('20181231003119'),
('20190103004002'),
('20190106222958'),
('20190106224616'),
('20190106224620'),
('20190113184757'),
('20190119025532'),
('20190127225315'),
('20190127230914'),
('20190127231411'),
('20190127232524'),
('20190127234855'),
('20190214043128'),
('20190214053222'),
('20190214053320'),
('20190217221228'),
('20190217221351'),
('20190217221850'),
('20190217221900'),
('20190217231801'),
('20190217232558'),
('20190219035444'),
('20190219035507'),
('20190226032050'),
('20190227035618'),
('20190228051000'),
('20190301023926'),
('20190305020700'),
('20190305020731'),
('20190305020739'),
('20190305021512'),
('20190305021856'),
('20190305022847'),
('20190306015104'),
('20190310233016'),
('20190311003141'),
('20190311015828'),
('20190312024943'),
('20190314030442'),
('20190316171635'),
('20190316174824'),
('20190317225558'),
('20190323034752'),
('20190324192555'),
('20190324220019'),
('20190324220242'),
('20190324222637'),
('20190331164739'),
('20190420211124'),
('20190420223028'),
('20190420225006'),
('20190516231534'),
('20190516232228'),
('20190516232940'),
('20190517005153'),
('20190817180449'),
('20190817181570'),
('20190817182420'),
('20190817182547'),
('20190817210528'),
('20190817225925'),
('20190824031742'),
('20190827015409'),
('20190831230621'),
('20190903012523'),
('20190912051541'),
('20190914181400'),
('20190914185512'),
('20190924010237'),
('20190925024449'),
('20191019022324'),
('20191019224617'),
('20191102002234'),
('20191102003525'),
('20191102003947'),
('20191102004443'),
('20191105030259'),
('20191123173554'),
('20191123180826'),
('20191210234208'),
('20200116030201'),
('20200128045830'),
('20200202205531'),
('20200208220808'),
('20200429023641'),
('20200429030034'),
('20200430041735'),
('20200514050743'),
('20200610015353'),
('20200709013909'),
('20200709014503'),
('20201202003011'),
('20201202003012'),
('20210122012249'),
('20210122043044'),
('20210124194958'),
('20210124200454'),
('20210124204720'),
('20210227204700'),
('20210710185728'),
('20211228183617'),
('20220415022658'),
('20220415044554'),
('20220418015453'),
('20220517025337'),
('20220611221953'),
('20220611223002'),
('20220611223008'),
('20220611223015'),
('20220611224027'),
('20220612003054');


