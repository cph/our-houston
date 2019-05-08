--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: test_result_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.test_result_status AS ENUM (
    'fail',
    'skip',
    'pass'
);


--
-- Name: cache_items_count_on_todo_list(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cache_items_count_on_todo_list() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP IN ('DELETE', 'UPDATE') THEN
    UPDATE todo_lists SET
      items_count=(SELECT COUNT(*) FROM todo_list_items WHERE todo_list_items.todolist_id=todo_lists.id AND todo_list_items.destroyed_at IS NULL),
      completed_items_count=(SELECT COUNT(*) FROM todo_list_items WHERE todo_list_items.todolist_id=todo_lists.id AND todo_list_items.destroyed_at IS NULL AND todo_list_items.completed_at IS NOT NULL)
    WHERE id=OLD.todolist_id;
  END IF;

  IF TG_OP IN ('UPDATE', 'INSERT') THEN
    UPDATE todo_lists SET
      items_count=(SELECT COUNT(*) FROM todo_list_items WHERE todo_list_items.todolist_id=todo_lists.id AND todo_list_items.destroyed_at IS NULL),
      completed_items_count=(SELECT COUNT(*) FROM todo_list_items WHERE todo_list_items.todolist_id=todo_lists.id AND todo_list_items.destroyed_at IS NULL AND todo_list_items.completed_at IS NOT NULL)
    WHERE id=NEW.todolist_id;

    RETURN NEW;
  ELSE
    RETURN OLD;
  END IF;
END;
$$;


--
-- Name: create_snippet_for_conversation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_snippet_for_conversation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      INSERT INTO feedback_snippets (conversation_id, text, search_vector, created_at, updated_at)
      SELECT
        new.id,
        new.plain_text,
        setweight(to_tsvector('english', new.plain_text), 'B') ||
        setweight(to_tsvector('english', new.attributed_to), 'B'),
        new.created_at,
        new.updated_at;
      return new;
    END;
    $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actions (
    id integer NOT NULL,
    name character varying NOT NULL,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    succeeded boolean,
    error_id integer,
    trigger character varying,
    params text,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.actions_id_seq OWNED BY public.actions.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts (
    id integer NOT NULL,
    type character varying(255) NOT NULL,
    key character varying(255) NOT NULL,
    summary character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    project_id integer,
    checked_out_by_id integer,
    opened_at timestamp without time zone NOT NULL,
    closed_at timestamp without time zone,
    checked_out_by_email character varying(255),
    project_slug character varying(255),
    priority character varying(255) DEFAULT 'high'::character varying NOT NULL,
    deadline timestamp without time zone NOT NULL,
    destroyed_at timestamp without time zone,
    checked_out_remotely boolean DEFAULT false,
    can_change_project boolean DEFAULT false,
    number integer NOT NULL,
    environment_name character varying(255),
    text character varying(255),
    requires_verification boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    suppressed boolean DEFAULT false NOT NULL,
    props jsonb DEFAULT '{}'::jsonb
);


--
-- Name: alerts_commits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts_commits (
    alert_id integer,
    commit_id integer
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: api_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_tokens (
    id integer NOT NULL,
    name character varying NOT NULL,
    user_id integer NOT NULL,
    value character varying NOT NULL
);


--
-- Name: api_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_tokens_id_seq OWNED BY public.api_tokens.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorizations (
    id integer NOT NULL,
    scope character varying,
    access_token character varying,
    refresh_token character varying,
    secret character varying,
    expires_in integer,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer NOT NULL,
    props jsonb DEFAULT '{}'::jsonb,
    type character varying NOT NULL
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.authorizations_id_seq OWNED BY public.authorizations.id;


--
-- Name: brakeman_scans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brakeman_scans (
    id integer NOT NULL,
    project_id integer NOT NULL,
    commit_id integer,
    sha character varying NOT NULL,
    brakeman_version character varying,
    duration integer,
    checks_performed character varying[]
);


--
-- Name: brakeman_scans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.brakeman_scans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brakeman_scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.brakeman_scans_id_seq OWNED BY public.brakeman_scans.id;


--
-- Name: brakeman_scans_warnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brakeman_scans_warnings (
    scan_id integer,
    warning_id integer
);


--
-- Name: brakeman_warnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brakeman_warnings (
    id integer NOT NULL,
    project_id integer NOT NULL,
    warning_type character varying NOT NULL,
    warning_code integer NOT NULL,
    fingerprint character varying NOT NULL,
    message text NOT NULL,
    file character varying NOT NULL,
    line integer,
    url character varying NOT NULL,
    code text,
    confidence character varying NOT NULL,
    props json DEFAULT '{}'::json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: brakeman_warnings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.brakeman_warnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brakeman_warnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.brakeman_warnings_id_seq OWNED BY public.brakeman_warnings.id;


--
-- Name: checkins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checkins (
    id integer NOT NULL,
    project_id integer,
    status integer,
    info jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: checkins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.checkins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checkins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.checkins_id_seq OWNED BY public.checkins.id;


--
-- Name: commits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits (
    id integer NOT NULL,
    sha character varying(255),
    message text,
    committer character varying(255),
    date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    committer_email character varying(255),
    project_id integer NOT NULL,
    authored_at timestamp without time zone NOT NULL,
    unreachable boolean DEFAULT false NOT NULL,
    parent_sha character varying(255)
);


--
-- Name: commits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: commits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.commits_id_seq OWNED BY public.commits.id;


--
-- Name: commits_pull_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits_pull_requests (
    commit_id integer,
    pull_request_id integer
);


--
-- Name: commits_releases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits_releases (
    commit_id integer,
    release_id integer
);


--
-- Name: commits_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits_tasks (
    commit_id integer,
    task_id integer
);


--
-- Name: commits_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits_tickets (
    commit_id integer,
    ticket_id integer
);


--
-- Name: commits_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits_users (
    commit_id integer,
    user_id integer
);


--
-- Name: deploys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deploys (
    id integer NOT NULL,
    project_id integer,
    sha character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    environment_name character varying(255) DEFAULT 'Production'::character varying NOT NULL,
    deployer character varying(255),
    commit_id integer,
    duration integer,
    branch character varying(255),
    completed_at timestamp without time zone,
    output text,
    user_id integer,
    successful boolean DEFAULT false NOT NULL
);


--
-- Name: deploys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deploys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deploys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deploys_id_seq OWNED BY public.deploys.id;


--
-- Name: errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.errors (
    id integer NOT NULL,
    sha character varying NOT NULL,
    message text NOT NULL,
    backtrace text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying
);


--
-- Name: errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.errors_id_seq OWNED BY public.errors.id;


--
-- Name: feedback_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_comments (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    user_id integer NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_comments_id_seq OWNED BY public.feedback_comments.id;


--
-- Name: feedback_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_conversations (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer,
    text text NOT NULL,
    plain_text text NOT NULL,
    attributed_to character varying(255) DEFAULT ''::character varying NOT NULL,
    tags text DEFAULT ''::text NOT NULL,
    import character varying(255),
    __search_vector tsvector,
    ticket_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    customer_id integer,
    average_signal_strength double precision,
    archived boolean DEFAULT false NOT NULL,
    legacy_id character varying,
    props jsonb DEFAULT '{}'::jsonb
);


--
-- Name: feedback_conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_conversations_id_seq OWNED BY public.feedback_conversations.id;


--
-- Name: feedback_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_customers (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    attributions text[]
);


--
-- Name: feedback_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_customers_id_seq OWNED BY public.feedback_customers.id;


--
-- Name: feedback_snippets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_snippets (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    range integer[],
    text text NOT NULL,
    tags text DEFAULT ''::text NOT NULL,
    search_vector tsvector,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feedback_snippets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_snippets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_snippets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_snippets_id_seq OWNED BY public.feedback_snippets.id;


--
-- Name: feedback_user_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_user_flags (
    id integer NOT NULL,
    user_id integer NOT NULL,
    conversation_id integer NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    signal_strength double precision
);


--
-- Name: feedback_user_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_user_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_user_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_user_flags_id_seq OWNED BY public.feedback_user_flags.id;


--
-- Name: feedback_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback_versions (
    id integer,
    versioned_id integer,
    versioned_type character varying(255),
    user_id integer,
    user_type character varying(255),
    user_name character varying(255),
    modifications text,
    number integer,
    reverted_from integer,
    tag character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follows (
    id integer NOT NULL,
    user_id integer,
    project_id integer
);


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follows_id_seq OWNED BY public.follows.id;


--
-- Name: goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.goals (
    id integer NOT NULL,
    project_id integer,
    name character varying NOT NULL,
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    destroyed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone
);


--
-- Name: goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.goals_id_seq OWNED BY public.goals.id;


--
-- Name: goals_todo_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.goals_todo_lists (
    todo_list_id integer NOT NULL,
    goal_id integer NOT NULL
);


--
-- Name: measurements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurements (
    id integer NOT NULL,
    subject_type character varying(255),
    subject_id integer,
    name character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    taken_at timestamp without time zone NOT NULL,
    taken_on date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: measurements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.measurements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: measurements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.measurements_id_seq OWNED BY public.measurements.id;


--
-- Name: milestone_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.milestone_versions (
    id integer NOT NULL,
    versioned_id integer,
    versioned_type character varying(255),
    roadmap_commit_id integer,
    modifications text,
    number integer,
    reverted_from integer,
    tag character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    user_type character varying(255)
);


--
-- Name: milestone_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.milestone_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: milestone_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.milestone_versions_id_seq OWNED BY public.milestone_versions.id;


--
-- Name: milestones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.milestones (
    id integer NOT NULL,
    project_id integer NOT NULL,
    remote_id integer,
    name character varying(255) NOT NULL,
    tickets_count integer DEFAULT 0,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    destroyed_at timestamp without time zone,
    band integer DEFAULT 1 NOT NULL,
    end_date date,
    locked boolean DEFAULT false NOT NULL,
    closed_tickets_count integer DEFAULT 0 NOT NULL,
    lanes integer DEFAULT 1 NOT NULL,
    goal text,
    feedback_query character varying(255),
    props jsonb DEFAULT '{}'::jsonb
);


--
-- Name: milestones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.milestones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.milestones_id_seq OWNED BY public.milestones.id;


--
-- Name: nanoconf_presentations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nanoconf_presentations (
    id integer NOT NULL,
    title character varying,
    description text,
    date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    presenter_id integer,
    tags text[]
);


--
-- Name: nanoconf_presentations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nanoconf_presentations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nanoconf_presentations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nanoconf_presentations_id_seq OWNED BY public.nanoconf_presentations.id;


--
-- Name: persistent_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persistent_triggers (
    id integer NOT NULL,
    type character varying NOT NULL,
    value text NOT NULL,
    params text DEFAULT '{}'::text NOT NULL,
    action character varying NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: persistent_triggers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.persistent_triggers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: persistent_triggers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.persistent_triggers_id_seq OWNED BY public.persistent_triggers.id;


--
-- Name: project_quotas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_quotas (
    id integer NOT NULL,
    project_id integer NOT NULL,
    week date NOT NULL,
    value integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_quotas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_quotas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_quotas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_quotas_id_seq OWNED BY public.project_quotas.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    color_name character varying(255) DEFAULT 'default'::character varying NOT NULL,
    retired_at timestamp without time zone,
    category character varying(255),
    version_control_name character varying(255) DEFAULT 'None'::character varying NOT NULL,
    ticket_tracker_name character varying(255) DEFAULT 'None'::character varying NOT NULL,
    ci_server_name character varying(255) DEFAULT 'None'::character varying NOT NULL,
    min_passing_verdicts integer DEFAULT 1 NOT NULL,
    error_tracker_name character varying(255) DEFAULT 'None'::character varying,
    last_ticket_tracker_sync_at timestamp without time zone,
    ticket_tracker_sync_started_at timestamp without time zone,
    selected_features text[],
    head_sha character varying(255),
    props jsonb DEFAULT '{}'::jsonb,
    team_id integer
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: projects_roadmaps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects_roadmaps (
    project_id integer NOT NULL,
    roadmap_id integer NOT NULL
);


--
-- Name: pull_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pull_requests (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer,
    title character varying(255) NOT NULL,
    number integer NOT NULL,
    repo character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    base_ref character varying(255) NOT NULL,
    base_sha character varying(255) NOT NULL,
    head_ref character varying(255) NOT NULL,
    head_sha character varying(255) NOT NULL,
    body text,
    props jsonb DEFAULT '{}'::jsonb,
    avatar_url character varying(255),
    json_labels jsonb DEFAULT '[]'::jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    closed_at timestamp without time zone,
    merged_at timestamp without time zone
);


--
-- Name: pull_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pull_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pull_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pull_requests_id_seq OWNED BY public.pull_requests.id;


--
-- Name: releases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.releases (
    id integer NOT NULL,
    name character varying(255),
    commit0 character varying(255),
    commit1 character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    message text DEFAULT ''::text NOT NULL,
    deploy_id integer,
    project_id integer DEFAULT '-1'::integer NOT NULL,
    environment_name character varying(255) DEFAULT 'Production'::character varying NOT NULL,
    release_changes text DEFAULT ''::text NOT NULL,
    commit_before_id integer,
    commit_after_id integer,
    search_vector tsvector
);


--
-- Name: releases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: releases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.releases_id_seq OWNED BY public.releases.id;


--
-- Name: roadmap_commits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmap_commits (
    id integer NOT NULL,
    user_id integer NOT NULL,
    message character varying(255) NOT NULL,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    roadmap_id integer,
    diffs jsonb NOT NULL
);


--
-- Name: roadmap_commits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roadmap_commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmap_commits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roadmap_commits_id_seq OWNED BY public.roadmap_commits.id;


--
-- Name: roadmap_milestone_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmap_milestone_versions (
    id integer NOT NULL,
    versioned_id integer,
    versioned_type character varying,
    roadmap_commit_id integer,
    modifications text,
    number integer,
    reverted_from integer,
    tag character varying,
    user_id integer,
    user_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: roadmap_milestone_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roadmap_milestone_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmap_milestone_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roadmap_milestone_versions_id_seq OWNED BY public.roadmap_milestone_versions.id;


--
-- Name: roadmap_milestones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmap_milestones (
    id integer NOT NULL,
    milestone_id integer NOT NULL,
    roadmap_id integer NOT NULL,
    band integer DEFAULT 1 NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    lanes integer DEFAULT 1 NOT NULL,
    destroyed_at timestamp without time zone
);


--
-- Name: roadmap_milestones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roadmap_milestones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmap_milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roadmap_milestones_id_seq OWNED BY public.roadmap_milestones.id;


--
-- Name: roadmaps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmaps (
    id integer NOT NULL,
    name character varying NOT NULL,
    visibility character varying DEFAULT 'Team Members'::character varying NOT NULL
);


--
-- Name: roadmaps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roadmaps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmaps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roadmaps_id_seq OWNED BY public.roadmaps.id;


--
-- Name: roadmaps_teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmaps_teams (
    team_id integer NOT NULL,
    roadmap_id integer NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    user_id integer,
    project_id integer,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sprints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sprints (
    id integer NOT NULL,
    end_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    locked boolean DEFAULT false NOT NULL
);


--
-- Name: sprints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sprints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sprints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sprints_id_seq OWNED BY public.sprints.id;


--
-- Name: sprints_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sprints_tasks (
    sprint_id integer NOT NULL,
    task_id integer NOT NULL,
    checked_out_at timestamp without time zone,
    checked_out_by_id integer
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tasks (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    number integer NOT NULL,
    description character varying(255),
    effort numeric(6,2),
    first_release_at timestamp without time zone,
    first_commit_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer NOT NULL,
    completed_at timestamp without time zone
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name character varying,
    props jsonb DEFAULT '{}'::jsonb
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: teams_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams_users (
    id integer NOT NULL,
    team_id integer,
    user_id integer,
    roles character varying[],
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: teams_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_users_id_seq OWNED BY public.teams_users.id;


--
-- Name: test_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_errors (
    id integer NOT NULL,
    sha character varying(255),
    output text
);


--
-- Name: test_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_errors_id_seq OWNED BY public.test_errors.id;


--
-- Name: test_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_results (
    id integer NOT NULL,
    test_run_id integer NOT NULL,
    test_id integer NOT NULL,
    status public.test_result_status NOT NULL,
    different boolean,
    duration double precision,
    error_id integer,
    new_test boolean
);


--
-- Name: test_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_results_id_seq OWNED BY public.test_results.id;


--
-- Name: test_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_runs (
    id integer NOT NULL,
    project_id integer NOT NULL,
    sha character varying(255) NOT NULL,
    completed_at timestamp without time zone,
    results_url character varying(255),
    result character varying(255),
    duration integer DEFAULT 0 NOT NULL,
    fail_count integer DEFAULT 0 NOT NULL,
    pass_count integer DEFAULT 0 NOT NULL,
    skip_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tests text,
    total_count integer DEFAULT 0 NOT NULL,
    agent_email character varying(255),
    branch character varying(255),
    coverage text,
    covered_percent numeric(6,5) DEFAULT 0 NOT NULL,
    covered_strength numeric(6,5) DEFAULT 0 NOT NULL,
    regression_count integer DEFAULT 0 NOT NULL,
    commit_id integer,
    user_id integer,
    compared boolean DEFAULT false NOT NULL
);


--
-- Name: test_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_runs_id_seq OWNED BY public.test_runs.id;


--
-- Name: testing_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.testing_notes (
    id integer NOT NULL,
    user_id integer,
    ticket_id integer,
    verdict character varying(255) NOT NULL,
    comment text DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone,
    remote_id integer,
    project_id integer NOT NULL
);


--
-- Name: testing_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.testing_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: testing_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.testing_notes_id_seq OWNED BY public.testing_notes.id;


--
-- Name: tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tests (
    id integer NOT NULL,
    project_id integer NOT NULL,
    suite character varying(255) NOT NULL,
    name text NOT NULL
);


--
-- Name: tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tests_id_seq OWNED BY public.tests.id;


--
-- Name: ticket_queues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_queues (
    id integer NOT NULL,
    ticket_id integer,
    queue character varying(255),
    destroyed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ticket_queues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ticket_queues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ticket_queues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ticket_queues_id_seq OWNED BY public.ticket_queues.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id integer NOT NULL,
    project_id integer,
    number integer NOT NULL,
    summary character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id integer,
    expires_at timestamp without time zone,
    tags character varying[],
    type character varying(255),
    closed_at timestamp without time zone,
    reporter_email character varying(255),
    reporter_id integer,
    milestone_id integer,
    destroyed_at timestamp without time zone,
    priority character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    props jsonb DEFAULT '{}'::jsonb,
    due_date date
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: tickets_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets_versions (
    id integer,
    versioned_id integer,
    versioned_type character varying(255),
    user_id integer,
    user_type character varying(255),
    user_name character varying(255),
    modifications text,
    number integer,
    reverted_from integer,
    tag character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: todo_list_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.todo_list_items (
    id integer NOT NULL,
    authorization_id integer,
    todolist_id integer,
    created_by_id integer,
    assigned_to_id integer,
    remote_id character varying NOT NULL,
    summary character varying NOT NULL,
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    destroyed_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed_by_id integer,
    created_by_email character varying,
    assigned_to_email character varying,
    completed_by_email character varying
);


--
-- Name: todo_list_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.todo_list_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: todo_list_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.todo_list_items_id_seq OWNED BY public.todo_list_items.id;


--
-- Name: todo_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.todo_lists (
    id integer NOT NULL,
    authorization_id integer,
    remote_id character varying NOT NULL,
    name character varying NOT NULL,
    sequence integer DEFAULT 0 NOT NULL,
    props jsonb DEFAULT '{}'::jsonb NOT NULL,
    destroyed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    items_count integer DEFAULT 0 NOT NULL,
    completed_items_count integer DEFAULT 0 NOT NULL,
    archived boolean DEFAULT false NOT NULL
);


--
-- Name: todo_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.todo_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: todo_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.todo_lists_id_seq OWNED BY public.todo_lists.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    invitation_token character varying,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying(255),
    authentication_token character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    retired_at timestamp without time zone,
    email_addresses text[],
    invitation_created_at timestamp without time zone,
    current_project_id integer,
    nickname character varying(255),
    username character varying(255),
    props jsonb DEFAULT '{}'::jsonb,
    role character varying DEFAULT 'Member'::character varying
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
-- Name: value_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.value_statements (
    id integer NOT NULL,
    project_id integer NOT NULL,
    weight double precision NOT NULL,
    text character varying(255) NOT NULL
);


--
-- Name: value_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.value_statements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: value_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.value_statements_id_seq OWNED BY public.value_statements.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    versioned_id integer,
    versioned_type character varying(255),
    user_id integer,
    user_type character varying(255),
    user_name character varying(255),
    modifications text,
    number integer,
    reverted_from integer,
    tag character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions ALTER COLUMN id SET DEFAULT nextval('public.actions_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: api_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens ALTER COLUMN id SET DEFAULT nextval('public.api_tokens_id_seq'::regclass);


--
-- Name: authorizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorizations ALTER COLUMN id SET DEFAULT nextval('public.authorizations_id_seq'::regclass);


--
-- Name: brakeman_scans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brakeman_scans ALTER COLUMN id SET DEFAULT nextval('public.brakeman_scans_id_seq'::regclass);


--
-- Name: brakeman_warnings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brakeman_warnings ALTER COLUMN id SET DEFAULT nextval('public.brakeman_warnings_id_seq'::regclass);


--
-- Name: checkins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkins ALTER COLUMN id SET DEFAULT nextval('public.checkins_id_seq'::regclass);


--
-- Name: commits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits ALTER COLUMN id SET DEFAULT nextval('public.commits_id_seq'::regclass);


--
-- Name: deploys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deploys ALTER COLUMN id SET DEFAULT nextval('public.deploys_id_seq'::regclass);


--
-- Name: errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.errors ALTER COLUMN id SET DEFAULT nextval('public.errors_id_seq'::regclass);


--
-- Name: feedback_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_comments ALTER COLUMN id SET DEFAULT nextval('public.feedback_comments_id_seq'::regclass);


--
-- Name: feedback_conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_conversations ALTER COLUMN id SET DEFAULT nextval('public.feedback_conversations_id_seq'::regclass);


--
-- Name: feedback_customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_customers ALTER COLUMN id SET DEFAULT nextval('public.feedback_customers_id_seq'::regclass);


--
-- Name: feedback_snippets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_snippets ALTER COLUMN id SET DEFAULT nextval('public.feedback_snippets_id_seq'::regclass);


--
-- Name: feedback_user_flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_user_flags ALTER COLUMN id SET DEFAULT nextval('public.feedback_user_flags_id_seq'::regclass);


--
-- Name: follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows ALTER COLUMN id SET DEFAULT nextval('public.follows_id_seq'::regclass);


--
-- Name: goals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goals ALTER COLUMN id SET DEFAULT nextval('public.goals_id_seq'::regclass);


--
-- Name: measurements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements ALTER COLUMN id SET DEFAULT nextval('public.measurements_id_seq'::regclass);


--
-- Name: milestone_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestone_versions ALTER COLUMN id SET DEFAULT nextval('public.milestone_versions_id_seq'::regclass);


--
-- Name: milestones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestones ALTER COLUMN id SET DEFAULT nextval('public.milestones_id_seq'::regclass);


--
-- Name: nanoconf_presentations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nanoconf_presentations ALTER COLUMN id SET DEFAULT nextval('public.nanoconf_presentations_id_seq'::regclass);


--
-- Name: persistent_triggers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persistent_triggers ALTER COLUMN id SET DEFAULT nextval('public.persistent_triggers_id_seq'::regclass);


--
-- Name: project_quotas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_quotas ALTER COLUMN id SET DEFAULT nextval('public.project_quotas_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: pull_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pull_requests ALTER COLUMN id SET DEFAULT nextval('public.pull_requests_id_seq'::regclass);


--
-- Name: releases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases ALTER COLUMN id SET DEFAULT nextval('public.releases_id_seq'::regclass);


--
-- Name: roadmap_commits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_commits ALTER COLUMN id SET DEFAULT nextval('public.roadmap_commits_id_seq'::regclass);


--
-- Name: roadmap_milestone_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_milestone_versions ALTER COLUMN id SET DEFAULT nextval('public.roadmap_milestone_versions_id_seq'::regclass);


--
-- Name: roadmap_milestones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_milestones ALTER COLUMN id SET DEFAULT nextval('public.roadmap_milestones_id_seq'::regclass);


--
-- Name: roadmaps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmaps ALTER COLUMN id SET DEFAULT nextval('public.roadmaps_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sprints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sprints ALTER COLUMN id SET DEFAULT nextval('public.sprints_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: teams_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users ALTER COLUMN id SET DEFAULT nextval('public.teams_users_id_seq'::regclass);


--
-- Name: test_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_errors ALTER COLUMN id SET DEFAULT nextval('public.test_errors_id_seq'::regclass);


--
-- Name: test_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_results ALTER COLUMN id SET DEFAULT nextval('public.test_results_id_seq'::regclass);


--
-- Name: test_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs ALTER COLUMN id SET DEFAULT nextval('public.test_runs_id_seq'::regclass);


--
-- Name: testing_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.testing_notes ALTER COLUMN id SET DEFAULT nextval('public.testing_notes_id_seq'::regclass);


--
-- Name: tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests ALTER COLUMN id SET DEFAULT nextval('public.tests_id_seq'::regclass);


--
-- Name: ticket_queues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_queues ALTER COLUMN id SET DEFAULT nextval('public.ticket_queues_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: todo_list_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items ALTER COLUMN id SET DEFAULT nextval('public.todo_list_items_id_seq'::regclass);


--
-- Name: todo_lists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_lists ALTER COLUMN id SET DEFAULT nextval('public.todo_lists_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: value_statements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.value_statements ALTER COLUMN id SET DEFAULT nextval('public.value_statements_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: actions actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actions
    ADD CONSTRAINT actions_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: api_tokens api_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT api_tokens_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: authorizations authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: brakeman_scans brakeman_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brakeman_scans
    ADD CONSTRAINT brakeman_scans_pkey PRIMARY KEY (id);


--
-- Name: brakeman_warnings brakeman_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brakeman_warnings
    ADD CONSTRAINT brakeman_warnings_pkey PRIMARY KEY (id);


--
-- Name: checkins checkins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checkins
    ADD CONSTRAINT checkins_pkey PRIMARY KEY (id);


--
-- Name: commits commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits
    ADD CONSTRAINT commits_pkey PRIMARY KEY (id);


--
-- Name: deploys deploys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deploys
    ADD CONSTRAINT deploys_pkey PRIMARY KEY (id);


--
-- Name: errors errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.errors
    ADD CONSTRAINT errors_pkey PRIMARY KEY (id);


--
-- Name: feedback_comments feedback_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_comments
    ADD CONSTRAINT feedback_comments_pkey PRIMARY KEY (id);


--
-- Name: feedback_conversations feedback_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_conversations
    ADD CONSTRAINT feedback_conversations_pkey PRIMARY KEY (id);


--
-- Name: feedback_customers feedback_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_customers
    ADD CONSTRAINT feedback_customers_pkey PRIMARY KEY (id);


--
-- Name: feedback_snippets feedback_snippets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_snippets
    ADD CONSTRAINT feedback_snippets_pkey PRIMARY KEY (id);


--
-- Name: feedback_user_flags feedback_user_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_user_flags
    ADD CONSTRAINT feedback_user_flags_pkey PRIMARY KEY (id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (id);


--
-- Name: measurements measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_pkey PRIMARY KEY (id);


--
-- Name: milestone_versions milestone_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestone_versions
    ADD CONSTRAINT milestone_versions_pkey PRIMARY KEY (id);


--
-- Name: milestones milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestones
    ADD CONSTRAINT milestones_pkey PRIMARY KEY (id);


--
-- Name: nanoconf_presentations nanoconf_presentations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nanoconf_presentations
    ADD CONSTRAINT nanoconf_presentations_pkey PRIMARY KEY (id);


--
-- Name: persistent_triggers persistent_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persistent_triggers
    ADD CONSTRAINT persistent_triggers_pkey PRIMARY KEY (id);


--
-- Name: project_quotas project_quotas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_quotas
    ADD CONSTRAINT project_quotas_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: pull_requests pull_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pull_requests
    ADD CONSTRAINT pull_requests_pkey PRIMARY KEY (id);


--
-- Name: releases releases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);


--
-- Name: roadmap_commits roadmap_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_commits
    ADD CONSTRAINT roadmap_commits_pkey PRIMARY KEY (id);


--
-- Name: roadmap_milestone_versions roadmap_milestone_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_milestone_versions
    ADD CONSTRAINT roadmap_milestone_versions_pkey PRIMARY KEY (id);


--
-- Name: roadmap_milestones roadmap_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_milestones
    ADD CONSTRAINT roadmap_milestones_pkey PRIMARY KEY (id);


--
-- Name: roadmaps roadmaps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT roadmaps_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sprints sprints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sprints
    ADD CONSTRAINT sprints_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams_users teams_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams_users
    ADD CONSTRAINT teams_users_pkey PRIMARY KEY (id);


--
-- Name: test_errors test_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_errors
    ADD CONSTRAINT test_errors_pkey PRIMARY KEY (id);


--
-- Name: test_results test_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_results
    ADD CONSTRAINT test_results_pkey PRIMARY KEY (id);


--
-- Name: test_results test_results_unique_constraint; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_results
    ADD CONSTRAINT test_results_unique_constraint UNIQUE (test_run_id, test_id);


--
-- Name: test_runs test_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_runs
    ADD CONSTRAINT test_runs_pkey PRIMARY KEY (id);


--
-- Name: testing_notes testing_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.testing_notes
    ADD CONSTRAINT testing_notes_pkey PRIMARY KEY (id);


--
-- Name: tests tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (id);


--
-- Name: tests tests_unique_constraint; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tests
    ADD CONSTRAINT tests_unique_constraint UNIQUE (project_id, suite, name);


--
-- Name: ticket_queues ticket_queues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_queues
    ADD CONSTRAINT ticket_queues_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: todo_list_items todo_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items
    ADD CONSTRAINT todo_list_items_pkey PRIMARY KEY (id);


--
-- Name: todo_lists todo_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_lists
    ADD CONSTRAINT todo_lists_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: value_statements value_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.value_statements
    ADD CONSTRAINT value_statements_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_actions_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_actions_on_name ON public.actions USING btree (name);


--
-- Name: index_alerts_commits_on_alert_id_and_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_alerts_commits_on_alert_id_and_commit_id ON public.alerts_commits USING btree (alert_id, commit_id);


--
-- Name: index_alerts_on_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_closed_at ON public.alerts USING btree (closed_at);


--
-- Name: index_alerts_on_opened_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alerts_on_opened_at ON public.alerts USING btree (opened_at);


--
-- Name: index_alerts_on_type_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_alerts_on_type_and_key ON public.alerts USING btree (type, key);


--
-- Name: index_api_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_tokens_on_user_id ON public.api_tokens USING btree (user_id);


--
-- Name: index_api_tokens_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_tokens_on_value ON public.api_tokens USING btree (value);


--
-- Name: index_authorizations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authorizations_on_user_id ON public.authorizations USING btree (user_id);


--
-- Name: index_brakeman_warnings_on_project_id_and_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_brakeman_warnings_on_project_id_and_fingerprint ON public.brakeman_warnings USING btree (project_id, fingerprint);


--
-- Name: index_commits_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_project_id ON public.commits USING btree (project_id);


--
-- Name: index_commits_on_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_on_sha ON public.commits USING btree (sha);


--
-- Name: index_commits_on_unreachable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_unreachable ON public.commits USING btree (unreachable);


--
-- Name: index_commits_pull_requests_on_commit_id_and_pull_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_pull_requests_on_commit_id_and_pull_request_id ON public.commits_pull_requests USING btree (commit_id, pull_request_id);


--
-- Name: index_commits_releases_on_commit_id_and_release_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_releases_on_commit_id_and_release_id ON public.commits_releases USING btree (commit_id, release_id);


--
-- Name: index_commits_tasks_on_commit_id_and_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_tasks_on_commit_id_and_task_id ON public.commits_tasks USING btree (commit_id, task_id);


--
-- Name: index_commits_tickets_on_commit_id_and_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_tickets_on_commit_id_and_ticket_id ON public.commits_tickets USING btree (commit_id, ticket_id);


--
-- Name: index_commits_users_on_commit_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_users_on_commit_id_and_user_id ON public.commits_users USING btree (commit_id, user_id);


--
-- Name: index_deploys_on_environment_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deploys_on_environment_name ON public.deploys USING btree (environment_name);


--
-- Name: index_deploys_on_project_id_and_environment_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deploys_on_project_id_and_environment_name ON public.deploys USING btree (project_id, environment_name);


--
-- Name: index_errors_on_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_errors_on_sha ON public.errors USING btree (sha);


--
-- Name: index_feedback_comments_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_comments_on_conversation_id ON public.feedback_comments USING btree (conversation_id);


--
-- Name: index_feedback_comments_on_tsvector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_comments_on_tsvector ON public.feedback_conversations USING gin (__search_vector);


--
-- Name: index_feedback_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_comments_on_user_id ON public.feedback_comments USING btree (user_id);


--
-- Name: index_feedback_conversations_on_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_feedback_conversations_on_legacy_id ON public.feedback_conversations USING btree (legacy_id) WHERE (legacy_id IS NOT NULL);


--
-- Name: index_feedback_snippets_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_snippets_on_conversation_id ON public.feedback_snippets USING btree (conversation_id);


--
-- Name: index_feedback_snippets_on_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_snippets_on_search_vector ON public.feedback_snippets USING gin (search_vector);


--
-- Name: index_feedback_user_flags_on_user_id_and_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_feedback_user_flags_on_user_id_and_conversation_id ON public.feedback_user_flags USING btree (user_id, conversation_id);


--
-- Name: index_feedback_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_versions_on_created_at ON public.feedback_versions USING btree (created_at);


--
-- Name: index_feedback_versions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_versions_on_number ON public.feedback_versions USING btree (number);


--
-- Name: index_feedback_versions_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_versions_on_tag ON public.feedback_versions USING btree (tag);


--
-- Name: index_feedback_versions_on_user_id_and_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_versions_on_user_id_and_user_type ON public.feedback_versions USING btree (user_id, user_type);


--
-- Name: index_feedback_versions_on_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_versions_on_user_name ON public.feedback_versions USING btree (user_name);


--
-- Name: index_feedback_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_feedback_versions_on_versioned_id_and_versioned_type ON public.feedback_versions USING btree (versioned_id, versioned_type);


--
-- Name: index_follows_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_project_id ON public.follows USING btree (project_id);


--
-- Name: index_follows_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_user_id ON public.follows USING btree (user_id);


--
-- Name: index_goals_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_goals_on_project_id ON public.goals USING btree (project_id);


--
-- Name: index_goals_todo_lists_on_goal_id_and_todo_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_goals_todo_lists_on_goal_id_and_todo_list_id ON public.goals_todo_lists USING btree (goal_id, todo_list_id);


--
-- Name: index_measurements_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_name ON public.measurements USING btree (name);


--
-- Name: index_measurements_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_subject_type_and_subject_id ON public.measurements USING btree (subject_type, subject_id);


--
-- Name: index_measurements_on_taken_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_taken_at ON public.measurements USING btree (taken_at);


--
-- Name: index_measurements_on_taken_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_taken_on ON public.measurements USING btree (taken_on);


--
-- Name: index_milestone_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_milestone_versions_on_created_at ON public.milestone_versions USING btree (created_at);


--
-- Name: index_milestone_versions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_milestone_versions_on_number ON public.milestone_versions USING btree (number);


--
-- Name: index_milestone_versions_on_roadmap_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_milestone_versions_on_roadmap_commit_id ON public.milestone_versions USING btree (roadmap_commit_id);


--
-- Name: index_milestone_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_milestone_versions_on_versioned_id_and_versioned_type ON public.milestone_versions USING btree (versioned_id, versioned_type);


--
-- Name: index_milestones_on_destroyed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_milestones_on_destroyed_at ON public.milestones USING btree (destroyed_at);


--
-- Name: index_milestones_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_milestones_on_project_id ON public.milestones USING btree (project_id);


--
-- Name: index_project_quotas_on_project_id_and_week; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_quotas_on_project_id_and_week ON public.project_quotas USING btree (project_id, week);


--
-- Name: index_project_quotas_on_week; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_quotas_on_week ON public.project_quotas USING btree (week);


--
-- Name: index_projects_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_slug ON public.projects USING btree (slug);


--
-- Name: index_projects_roadmaps_on_project_id_and_roadmap_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_roadmaps_on_project_id_and_roadmap_id ON public.projects_roadmaps USING btree (project_id, roadmap_id);


--
-- Name: index_pull_requests_on_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pull_requests_on_closed_at ON public.pull_requests USING btree (closed_at);


--
-- Name: index_pull_requests_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pull_requests_on_project_id ON public.pull_requests USING btree (project_id);


--
-- Name: index_pull_requests_on_project_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pull_requests_on_project_id_and_number ON public.pull_requests USING btree (project_id, number);


--
-- Name: index_releases_on_deploy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_deploy_id ON public.releases USING btree (deploy_id);


--
-- Name: index_releases_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_project_id ON public.releases USING btree (project_id);


--
-- Name: index_releases_on_project_id_and_environment_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_project_id_and_environment_name ON public.releases USING btree (project_id, environment_name);


--
-- Name: index_releases_on_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_search_vector ON public.releases USING gin (search_vector);


--
-- Name: index_roadmap_milestone_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roadmap_milestone_versions_on_created_at ON public.roadmap_milestone_versions USING btree (created_at);


--
-- Name: index_roadmap_milestone_versions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roadmap_milestone_versions_on_number ON public.roadmap_milestone_versions USING btree (number);


--
-- Name: index_roadmap_milestone_versions_on_roadmap_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roadmap_milestone_versions_on_roadmap_commit_id ON public.roadmap_milestone_versions USING btree (roadmap_commit_id);


--
-- Name: index_roadmap_milestone_versions_on_versioned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roadmap_milestone_versions_on_versioned ON public.roadmap_milestone_versions USING btree (versioned_id, versioned_type);


--
-- Name: index_roadmap_milestones_on_milestone_id_and_roadmap_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roadmap_milestones_on_milestone_id_and_roadmap_id ON public.roadmap_milestones USING btree (milestone_id, roadmap_id);


--
-- Name: index_roadmaps_teams_on_team_id_and_roadmap_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roadmaps_teams_on_team_id_and_roadmap_id ON public.roadmaps_teams USING btree (team_id, roadmap_id);


--
-- Name: index_roles_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_user_id_and_project_id ON public.roles USING btree (user_id, project_id);


--
-- Name: index_roles_on_user_id_and_project_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_user_id_and_project_id_and_name ON public.roles USING btree (user_id, project_id, name);


--
-- Name: index_sprints_on_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sprints_on_end_date ON public.sprints USING btree (end_date);


--
-- Name: index_sprints_tasks_on_sprint_id_and_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sprints_tasks_on_sprint_id_and_task_id ON public.sprints_tasks USING btree (sprint_id, task_id);


--
-- Name: index_tasks_on_ticket_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tasks_on_ticket_id_and_number ON public.tasks USING btree (ticket_id, number);


--
-- Name: index_teams_users_on_team_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_teams_users_on_team_id_and_user_id ON public.teams_users USING btree (team_id, user_id);


--
-- Name: index_test_errors_on_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_test_errors_on_sha ON public.test_errors USING btree (sha);


--
-- Name: index_test_results_on_test_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_results_on_test_id ON public.test_results USING btree (test_id);


--
-- Name: index_test_results_on_test_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_results_on_test_run_id ON public.test_results USING btree (test_run_id);


--
-- Name: index_test_runs_on_commit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_runs_on_commit ON public.test_runs USING btree (sha);


--
-- Name: index_test_runs_on_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_test_runs_on_commit_id ON public.test_runs USING btree (commit_id);


--
-- Name: index_test_runs_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_test_runs_on_project_id ON public.test_runs USING btree (project_id);


--
-- Name: index_testing_notes_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_testing_notes_on_project_id ON public.testing_notes USING btree (project_id);


--
-- Name: index_testing_notes_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_testing_notes_on_ticket_id ON public.testing_notes USING btree (ticket_id);


--
-- Name: index_testing_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_testing_notes_on_user_id ON public.testing_notes USING btree (user_id);


--
-- Name: index_tests_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tests_on_project_id ON public.tests USING btree (project_id);


--
-- Name: index_ticket_queues_on_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ticket_queues_on_queue ON public.ticket_queues USING btree (queue);


--
-- Name: index_ticket_queues_on_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ticket_queues_on_ticket_id ON public.ticket_queues USING btree (ticket_id);


--
-- Name: index_tickets_on_destroyed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_destroyed_at ON public.tickets USING btree (destroyed_at);


--
-- Name: index_tickets_on_milestone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_milestone_id ON public.tickets USING btree (milestone_id);


--
-- Name: index_tickets_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_versions_on_created_at ON public.tickets_versions USING btree (created_at);


--
-- Name: index_tickets_versions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_versions_on_number ON public.tickets_versions USING btree (number);


--
-- Name: index_tickets_versions_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_versions_on_tag ON public.tickets_versions USING btree (tag);


--
-- Name: index_tickets_versions_on_user_id_and_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_versions_on_user_id_and_user_type ON public.tickets_versions USING btree (user_id, user_type);


--
-- Name: index_tickets_versions_on_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_versions_on_user_name ON public.tickets_versions USING btree (user_name);


--
-- Name: index_tickets_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_versions_on_versioned_id_and_versioned_type ON public.tickets_versions USING btree (versioned_id, versioned_type);


--
-- Name: index_todo_list_items_on_assigned_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_list_items_on_assigned_to_id ON public.todo_list_items USING btree (assigned_to_id);


--
-- Name: index_todo_list_items_on_authorization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_list_items_on_authorization_id ON public.todo_list_items USING btree (authorization_id);


--
-- Name: index_todo_list_items_on_completed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_list_items_on_completed_by_id ON public.todo_list_items USING btree (completed_by_id);


--
-- Name: index_todo_list_items_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_list_items_on_created_by_id ON public.todo_list_items USING btree (created_by_id);


--
-- Name: index_todo_list_items_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_list_items_on_remote_id ON public.todo_list_items USING btree (remote_id);


--
-- Name: index_todo_list_items_on_todolist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_list_items_on_todolist_id ON public.todo_list_items USING btree (todolist_id);


--
-- Name: index_todo_lists_on_authorization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_lists_on_authorization_id ON public.todo_lists USING btree (authorization_id);


--
-- Name: index_todo_lists_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_todo_lists_on_remote_id ON public.todo_lists USING btree (remote_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_authentication_token ON public.users USING btree (authentication_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_email_addresses; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email_addresses ON public.users USING btree (email_addresses);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_created_at ON public.versions USING btree (created_at);


--
-- Name: index_versions_on_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_number ON public.versions USING btree (number);


--
-- Name: index_versions_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_tag ON public.versions USING btree (tag);


--
-- Name: index_versions_on_user_id_and_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_user_id_and_user_type ON public.versions USING btree (user_id, user_type);


--
-- Name: index_versions_on_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_user_name ON public.versions USING btree (user_name);


--
-- Name: index_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_versioned_id_and_versioned_type ON public.versions USING btree (versioned_id, versioned_type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: todo_list_items cache_items_count_on_todo_list_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cache_items_count_on_todo_list_trigger AFTER INSERT OR DELETE OR UPDATE ON public.todo_list_items FOR EACH ROW EXECUTE PROCEDURE public.cache_items_count_on_todo_list();


--
-- Name: feedback_conversations create_snippet_for_conversation_on_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_snippet_for_conversation_on_insert_trigger AFTER INSERT ON public.feedback_conversations FOR EACH ROW EXECUTE PROCEDURE public.create_snippet_for_conversation();


--
-- Name: todo_list_items fk_rails_0e0067e526; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items
    ADD CONSTRAINT fk_rails_0e0067e526 FOREIGN KEY (created_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: goals_todo_lists fk_rails_1040255f10; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goals_todo_lists
    ADD CONSTRAINT fk_rails_1040255f10 FOREIGN KEY (goal_id) REFERENCES public.goals(id) ON DELETE CASCADE;


--
-- Name: goals fk_rails_17291b67f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT fk_rails_17291b67f3 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: todo_list_items fk_rails_2e5e833107; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items
    ADD CONSTRAINT fk_rails_2e5e833107 FOREIGN KEY (todolist_id) REFERENCES public.todo_lists(id) ON DELETE CASCADE;


--
-- Name: follows fk_rails_32479bd030; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_rails_32479bd030 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: todo_list_items fk_rails_3497ac4841; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items
    ADD CONSTRAINT fk_rails_3497ac4841 FOREIGN KEY (assigned_to_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: todo_list_items fk_rails_499b6292a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items
    ADD CONSTRAINT fk_rails_499b6292a6 FOREIGN KEY (authorization_id) REFERENCES public.authorizations(id) ON DELETE SET NULL;


--
-- Name: authorizations fk_rails_4ecef5b8c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorizations
    ADD CONSTRAINT fk_rails_4ecef5b8c5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: follows fk_rails_572bf69092; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_rails_572bf69092 FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: todo_list_items fk_rails_6ac4575b32; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_list_items
    ADD CONSTRAINT fk_rails_6ac4575b32 FOREIGN KEY (completed_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: feedback_snippets fk_rails_bde07ddc98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback_snippets
    ADD CONSTRAINT fk_rails_bde07ddc98 FOREIGN KEY (conversation_id) REFERENCES public.feedback_conversations(id) ON DELETE CASCADE;


--
-- Name: goals_todo_lists fk_rails_ce39dcc1f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.goals_todo_lists
    ADD CONSTRAINT fk_rails_ce39dcc1f3 FOREIGN KEY (todo_list_id) REFERENCES public.todo_lists(id) ON DELETE CASCADE;


--
-- Name: todo_lists fk_rails_ee7a587d4b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.todo_lists
    ADD CONSTRAINT fk_rails_ee7a587d4b FOREIGN KEY (authorization_id) REFERENCES public.authorizations(id) ON DELETE SET NULL;


--
-- Name: api_tokens fk_rails_f16b5e0447; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT fk_rails_f16b5e0447 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20120324185914'),
('20120324202224'),
('20120324212848'),
('20120324212946'),
('20120324230038'),
('20120406185643'),
('20120408155047'),
('20120417175450'),
('20120417175841'),
('20120417190504'),
('20120417195313'),
('20120417195433'),
('20120424212706'),
('20120501230243'),
('20120501231817'),
('20120501231948'),
('20120504143615'),
('20120525013703'),
('20120607124115'),
('20120626140242'),
('20120626150333'),
('20120626151320'),
('20120626152020'),
('20120626152949'),
('20120715230526'),
('20120715230922'),
('20120716010743'),
('20120726212620'),
('20120726231754'),
('20120804003344'),
('20120823025935'),
('20120826022643'),
('20120827190634'),
('20120913020218'),
('20120920023251'),
('20120922010212'),
('20121026014457'),
('20121027160548'),
('20121027171215'),
('20121104233305'),
('20121126005019'),
('20121214025558'),
('20121219202734'),
('20121220031008'),
('20121222170917'),
('20121222223325'),
('20121222223635'),
('20121224212623'),
('20121225175106'),
('20121225175107'),
('20121230173644'),
('20121230174234'),
('20130105200429'),
('20130106184327'),
('20130106185425'),
('20130119203853'),
('20130119204608'),
('20130119211540'),
('20130119212008'),
('20130120182026'),
('20130211015046'),
('20130302205014'),
('20130306023456'),
('20130306023613'),
('20130312224911'),
('20130319003918'),
('20130407195450'),
('20130407200624'),
('20130407220039'),
('20130407220937'),
('20130407221459'),
('20130416020627'),
('20130420151334'),
('20130420155332'),
('20130420172322'),
('20130420174002'),
('20130420174126'),
('20130427223925'),
('20130428005808'),
('20130504014802'),
('20130504135741'),
('20130505144446'),
('20130505162039'),
('20130505212838'),
('20130518224352'),
('20130518224406'),
('20130518224655'),
('20130518224722'),
('20130519163615'),
('20130525192607'),
('20130525222131'),
('20130526024851'),
('20130706141443'),
('20130710233849'),
('20130711004558'),
('20130711013156'),
('20130728191005'),
('20130806143651'),
('20130815232527'),
('20130914152419'),
('20130914155044'),
('20130921141449'),
('20131002005512'),
('20131002015547'),
('20131002145620'),
('20131003014023'),
('20131004015452'),
('20131004185618'),
('20131012152403'),
('20131013185636'),
('20131027214942'),
('20131112010815'),
('20131216014505'),
('20131223194246'),
('20140106212047'),
('20140106212305'),
('20140114014144'),
('20140217150735'),
('20140217160450'),
('20140217195942'),
('20140327020121'),
('20140401234330'),
('20140406183224'),
('20140406230121'),
('20140407010111'),
('20140411214022'),
('20140418133005'),
('20140419152214'),
('20140425141946'),
('20140427235508'),
('20140428023146'),
('20140429000919'),
('20140506032958'),
('20140506035755'),
('20140511024021'),
('20140515174322'),
('20140515200824'),
('20140516005310'),
('20140516012049'),
('20140517012626'),
('20140521014652'),
('20140526155845'),
('20140526162645'),
('20140526180608'),
('20140526180609'),
('20140606232907'),
('20140724231918'),
('20140806233301'),
('20140807212311'),
('20140810224209'),
('20140813010452'),
('20140815000804'),
('20140815022909'),
('20140821000627'),
('20140824194031'),
('20140824194526'),
('20140824211249'),
('20140831210254'),
('20140907005810'),
('20140907012329'),
('20140907013836'),
('20140907212311'),
('20140916230539'),
('20140921190022'),
('20140921201441'),
('20140921203932'),
('20140925021043'),
('20140927154728'),
('20140929004347'),
('20140929024130'),
('20141012023628'),
('20141027194819'),
('20141125162853'),
('20141128155140'),
('20141202004123'),
('20141226171730'),
('20150102192805'),
('20150113025408'),
('20150116153233'),
('20150119154013'),
('20150119155145'),
('20150220215154'),
('20150222205616'),
('20150222214124'),
('20150223013721'),
('20150302153319'),
('20150323004452'),
('20150323011050'),
('20150524203903'),
('20150603203744'),
('20150708235654'),
('20150711220519'),
('20150711220542'),
('20150805180939'),
('20150805233946'),
('20150806032230'),
('20150808161729'),
('20150808161805'),
('20150808162928'),
('20150808192103'),
('20150808193354'),
('20150809132417'),
('20150809201942'),
('20150815005551'),
('20150817232311'),
('20150818005716'),
('20150820023708'),
('20150902005758'),
('20150902005759'),
('20150902010629'),
('20150902010853'),
('20150916152641'),
('20150927014445'),
('20151024164701'),
('20151024170230'),
('20151108221505'),
('20151108223154'),
('20151108233510'),
('20151201042126'),
('20151202005557'),
('20151202011812'),
('20151205204922'),
('20151205214647'),
('20151205222043'),
('20151205223652'),
('20151206004534'),
('20151209004458'),
('20151209030113'),
('20151226154901'),
('20151226155305'),
('20151228183704'),
('20151228183705'),
('20151228183706'),
('20151228183708'),
('20160120145757'),
('20160202021439'),
('20160206214746'),
('20160207154530'),
('20160208233434'),
('20160225021717'),
('20160317140151'),
('20160419230411'),
('20160420000616'),
('20160421022627'),
('20160507135209'),
('20160507135846'),
('20160510233329'),
('20160520201427'),
('20160618181128'),
('20160625170737'),
('20160625203412'),
('20160625221840'),
('20160625230420'),
('20160704144651'),
('20160704173318'),
('20160711170921'),
('20160713204605'),
('20160715173039'),
('20160812233255'),
('20160813001242'),
('20160814024129'),
('20160815001515'),
('20160828204509'),
('20160905141815'),
('20160905160003'),
('20160913230232'),
('20160916191300'),
('20160916194521'),
('20160919233319'),
('20161102012059'),
('20161102012231'),
('20161107230732'),
('20170113164126'),
('20170113223920'),
('20170113224431'),
('20170113225759'),
('20170113230723'),
('20170113230944'),
('20170113231303'),
('20170113232119'),
('20170115003303'),
('20170115003536'),
('20170115150643'),
('20170116002818'),
('20170116210225'),
('20170118005958'),
('20170128161237'),
('20170130011016'),
('20170205004452'),
('20170206002030'),
('20170206002307'),
('20170206002718'),
('20170206002732'),
('20170209022159'),
('20170211232146'),
('20170213001453'),
('20170215012012'),
('20170216041034'),
('20170224025652'),
('20170225035649'),
('20170226201504'),
('20170226213622'),
('20170301014051'),
('20170307032041'),
('20170307035755'),
('20170310024505'),
('20170311033426'),
('20170311033629'),
('20170311152016'),
('20170314230755'),
('20170320002452'),
('20170323034420'),
('20170329030329'),
('20170329162815'),
('20170329164043'),
('20170502012341'),
('20170525233934'),
('20170811214556'),
('20181102202848'),
('20190103223906'),
('20190428023415');


