--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

--
-- Name: test_result_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE test_result_status AS ENUM (
    'fail',
    'skip',
    'pass'
);


--
-- Name: =>; Type: OPERATOR; Schema: public; Owner: -
--

CREATE OPERATOR => (
    PROCEDURE = tconvert,
    LEFTARG = text,
    RIGHTARG = text
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE alerts (
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
    hours hstore DEFAULT ''::hstore,
    destroyed_at timestamp without time zone,
    checked_out_remotely boolean DEFAULT false,
    can_change_project boolean DEFAULT false,
    number integer,
    environment_name character varying(255),
    text character varying(255),
    requires_verification boolean DEFAULT false NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    suppressed boolean DEFAULT false NOT NULL
);


--
-- Name: alerts_commits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE alerts_commits (
    alert_id integer,
    commit_id integer
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alerts_id_seq OWNED BY alerts.id;


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE authorizations (
    id integer NOT NULL,
    name character varying NOT NULL,
    provider_id integer,
    scope character varying,
    access_token character varying,
    refresh_token character varying,
    secret character varying,
    expires_in integer,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;


--
-- Name: brakeman_scans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brakeman_scans (
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

CREATE SEQUENCE brakeman_scans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brakeman_scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brakeman_scans_id_seq OWNED BY brakeman_scans.id;


--
-- Name: brakeman_scans_warnings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brakeman_scans_warnings (
    scan_id integer,
    warning_id integer
);


--
-- Name: brakeman_warnings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE brakeman_warnings (
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

CREATE SEQUENCE brakeman_warnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brakeman_warnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE brakeman_warnings_id_seq OWNED BY brakeman_warnings.id;


--
-- Name: commits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits (
    id integer NOT NULL,
    release_id integer,
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

CREATE SEQUENCE commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: commits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE commits_id_seq OWNED BY commits.id;


--
-- Name: commits_pull_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits_pull_requests (
    commit_id integer,
    pull_request_id integer
);


--
-- Name: commits_releases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits_releases (
    commit_id integer,
    release_id integer
);


--
-- Name: commits_tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits_tasks (
    commit_id integer,
    task_id integer
);


--
-- Name: commits_tickets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits_tickets (
    commit_id integer,
    ticket_id integer
);


--
-- Name: commits_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits_users (
    commit_id integer,
    user_id integer
);


--
-- Name: consumer_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE consumer_tokens (
    id integer NOT NULL,
    user_id integer,
    type character varying(30),
    token character varying(1024),
    refresh_token character varying(255),
    secret character varying(255),
    expires_at integer,
    expires_in character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: consumer_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consumer_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consumer_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consumer_tokens_id_seq OWNED BY consumer_tokens.id;


--
-- Name: deploys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE deploys (
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

CREATE SEQUENCE deploys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deploys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deploys_id_seq OWNED BY deploys.id;


--
-- Name: errors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE errors (
    id integer NOT NULL,
    sha character varying NOT NULL,
    message text NOT NULL,
    backtrace text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE errors_id_seq OWNED BY errors.id;


--
-- Name: feedback_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedback_comments (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer,
    text text NOT NULL,
    plain_text text NOT NULL,
    attributed_to character varying(255) DEFAULT ''::character varying NOT NULL,
    tags text DEFAULT ''::text NOT NULL,
    import character varying(255),
    search_vector tsvector,
    ticket_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    customer_id integer
);


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedback_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedback_comments_id_seq OWNED BY feedback_comments.id;


--
-- Name: feedback_comments_user_flags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedback_comments_user_flags (
    id integer NOT NULL,
    user_id integer NOT NULL,
    comment_id integer NOT NULL,
    read boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: feedback_comments_user_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedback_comments_user_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_comments_user_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedback_comments_user_flags_id_seq OWNED BY feedback_comments_user_flags.id;


--
-- Name: feedback_customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedback_customers (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    attributions text[]
);


--
-- Name: feedback_customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedback_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedback_customers_id_seq OWNED BY feedback_customers.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE jobs (
    id integer NOT NULL,
    name character varying NOT NULL,
    started_at timestamp without time zone NOT NULL,
    finished_at timestamp without time zone,
    succeeded boolean,
    error_id integer
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- Name: measurements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE measurements (
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

CREATE SEQUENCE measurements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: measurements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE measurements_id_seq OWNED BY measurements.id;


--
-- Name: milestone_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE milestone_versions (
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

CREATE SEQUENCE milestone_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: milestone_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE milestone_versions_id_seq OWNED BY milestone_versions.id;


--
-- Name: milestones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE milestones (
    id integer NOT NULL,
    project_id integer NOT NULL,
    remote_id integer,
    name character varying(255) NOT NULL,
    tickets_count integer DEFAULT 0,
    completed_at timestamp without time zone,
    extended_attributes hstore DEFAULT ''::hstore NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    destroyed_at timestamp without time zone,
    start_date date,
    band integer DEFAULT 1 NOT NULL,
    end_date date,
    locked boolean DEFAULT false NOT NULL,
    closed_tickets_count integer DEFAULT 0 NOT NULL,
    lanes integer DEFAULT 1 NOT NULL,
    goal text,
    feedback_query character varying(255)
);


--
-- Name: milestones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE milestones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE milestones_id_seq OWNED BY milestones.id;


--
-- Name: nanoconf_presentations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE nanoconf_presentations (
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

CREATE SEQUENCE nanoconf_presentations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nanoconf_presentations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE nanoconf_presentations_id_seq OWNED BY nanoconf_presentations.id;


--
-- Name: oauth_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_providers (
    id integer NOT NULL,
    name character varying NOT NULL,
    site character varying NOT NULL,
    authorize_path character varying NOT NULL,
    token_path character varying NOT NULL,
    client_id character varying NOT NULL,
    client_secret character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_providers_id_seq OWNED BY oauth_providers.id;


--
-- Name: project_quotas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE project_quotas (
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

CREATE SEQUENCE project_quotas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_quotas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_quotas_id_seq OWNED BY project_quotas.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    color character varying(255) DEFAULT 'default'::character varying NOT NULL,
    retired_at timestamp without time zone,
    category character varying(255),
    version_control_name character varying(255) DEFAULT 'None'::character varying NOT NULL,
    ticket_tracker_name character varying(255) DEFAULT 'None'::character varying NOT NULL,
    ci_server_name character varying(255) DEFAULT 'None'::character varying NOT NULL,
    min_passing_verdicts integer DEFAULT 1 NOT NULL,
    error_tracker_name character varying(255) DEFAULT 'None'::character varying,
    extended_attributes hstore DEFAULT ''::hstore NOT NULL,
    code_climate_repo_token character varying(255) DEFAULT ''::character varying NOT NULL,
    last_ticket_tracker_sync_at timestamp without time zone,
    ticket_tracker_sync_started_at timestamp without time zone,
    view_options hstore DEFAULT ''::hstore NOT NULL,
    feature_states hstore DEFAULT ''::hstore NOT NULL,
    selected_features text[],
    head_sha character varying(255)
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: projects_roadmaps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects_roadmaps (
    project_id integer NOT NULL,
    roadmap_id integer NOT NULL
);


--
-- Name: pull_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pull_requests (
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

CREATE SEQUENCE pull_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pull_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pull_requests_id_seq OWNED BY pull_requests.id;


--
-- Name: releases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases (
    id integer NOT NULL,
    name character varying(255),
    commit0 character varying(255),
    commit1 character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    message text DEFAULT ''::text NOT NULL,
    deploy_id integer,
    project_id integer DEFAULT (-1) NOT NULL,
    environment_name character varying(255) DEFAULT 'Production'::character varying NOT NULL,
    release_changes text DEFAULT ''::text NOT NULL,
    commit_before_id integer,
    commit_after_id integer,
    search_vector tsvector
);


--
-- Name: releases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: releases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE releases_id_seq OWNED BY releases.id;


--
-- Name: releases_tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_tasks (
    release_id integer,
    task_id integer
);


--
-- Name: releases_tickets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE releases_tickets (
    release_id integer,
    ticket_id integer
);


--
-- Name: roadmap_commits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roadmap_commits (
    id integer NOT NULL,
    user_id integer NOT NULL,
    message character varying(255) NOT NULL,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    roadmap_id integer
);


--
-- Name: roadmap_commits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roadmap_commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmap_commits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roadmap_commits_id_seq OWNED BY roadmap_commits.id;


--
-- Name: roadmap_milestone_versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roadmap_milestone_versions (
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

CREATE SEQUENCE roadmap_milestone_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmap_milestone_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roadmap_milestone_versions_id_seq OWNED BY roadmap_milestone_versions.id;


--
-- Name: roadmap_milestones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roadmap_milestones (
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

CREATE SEQUENCE roadmap_milestones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmap_milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roadmap_milestones_id_seq OWNED BY roadmap_milestones.id;


--
-- Name: roadmaps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roadmaps (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: roadmaps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roadmaps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roadmaps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roadmaps_id_seq OWNED BY roadmaps.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
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

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE settings (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255) NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;


--
-- Name: sprints; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sprints (
    id integer NOT NULL,
    end_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    locked boolean DEFAULT false NOT NULL
);


--
-- Name: sprints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sprints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sprints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sprints_id_seq OWNED BY sprints.id;


--
-- Name: sprints_tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sprints_tasks (
    sprint_id integer NOT NULL,
    task_id integer NOT NULL,
    checked_out_at timestamp without time zone,
    checked_out_by_id integer
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tasks (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    number integer NOT NULL,
    description character varying(255),
    effort numeric(6,2),
    first_release_at timestamp without time zone,
    first_commit_at timestamp without time zone,
    sprint_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    project_id integer NOT NULL,
    completed_at timestamp without time zone
);


--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tasks_id_seq OWNED BY tasks.id;


--
-- Name: test_errors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE test_errors (
    id integer NOT NULL,
    sha character varying(255),
    output text
);


--
-- Name: test_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE test_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE test_errors_id_seq OWNED BY test_errors.id;


--
-- Name: test_results; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE test_results (
    id integer NOT NULL,
    test_run_id integer NOT NULL,
    test_id integer NOT NULL,
    status test_result_status NOT NULL,
    different boolean,
    duration double precision,
    error_id integer,
    new_test boolean
);


--
-- Name: test_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE test_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE test_results_id_seq OWNED BY test_results.id;


--
-- Name: test_runs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE test_runs (
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

CREATE SEQUENCE test_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE test_runs_id_seq OWNED BY test_runs.id;


--
-- Name: testing_notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE testing_notes (
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

CREATE SEQUENCE testing_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: testing_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE testing_notes_id_seq OWNED BY testing_notes.id;


--
-- Name: tests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tests (
    id integer NOT NULL,
    project_id integer NOT NULL,
    suite character varying(255) NOT NULL,
    name text NOT NULL
);


--
-- Name: tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tests_id_seq OWNED BY tests.id;


--
-- Name: ticket_queues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ticket_queues (
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

CREATE SEQUENCE ticket_queues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ticket_queues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ticket_queues_id_seq OWNED BY ticket_queues.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tickets (
    id integer NOT NULL,
    project_id integer,
    number integer NOT NULL,
    summary character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id integer,
    deployment character varying(255),
    last_release_at timestamp without time zone,
    expires_at timestamp without time zone,
    extended_attributes hstore DEFAULT ''::hstore NOT NULL,
    antecedents text[],
    tags character varying[],
    type character varying(255),
    closed_at timestamp without time zone,
    reporter_email character varying(255),
    reporter_id integer,
    milestone_id integer,
    destroyed_at timestamp without time zone,
    resolution character varying(255) DEFAULT ''::character varying NOT NULL,
    first_release_at timestamp without time zone,
    priority character varying(255) DEFAULT 'normal'::character varying NOT NULL,
    reopened_at timestamp without time zone,
    prerequisites integer[]
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tickets_id_seq OWNED BY tickets.id;


--
-- Name: user_credentials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_credentials (
    id integer NOT NULL,
    user_id integer,
    service character varying(255),
    login character varying(255),
    password bytea,
    password_key bytea,
    password_iv bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_credentials_id_seq OWNED BY user_credentials.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
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
    role character varying(255) DEFAULT 'Guest'::character varying,
    authentication_token character varying(255),
    administrator boolean DEFAULT false,
    unfuddle_id integer,
    first_name character varying(255),
    last_name character varying(255),
    retired_at timestamp without time zone,
    view_options hstore DEFAULT ''::hstore NOT NULL,
    email_addresses text[],
    invitation_created_at timestamp without time zone,
    environments_subscribed_to text[] DEFAULT '{}'::text[] NOT NULL,
    current_project_id integer,
    nickname character varying(255),
    username character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: value_statements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE value_statements (
    id integer NOT NULL,
    project_id integer NOT NULL,
    weight double precision NOT NULL,
    text character varying(255) NOT NULL
);


--
-- Name: value_statements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE value_statements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: value_statements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE value_statements_id_seq OWNED BY value_statements.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE versions (
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

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts ALTER COLUMN id SET DEFAULT nextval('alerts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brakeman_scans ALTER COLUMN id SET DEFAULT nextval('brakeman_scans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY brakeman_warnings ALTER COLUMN id SET DEFAULT nextval('brakeman_warnings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY commits ALTER COLUMN id SET DEFAULT nextval('commits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consumer_tokens ALTER COLUMN id SET DEFAULT nextval('consumer_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deploys ALTER COLUMN id SET DEFAULT nextval('deploys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY errors ALTER COLUMN id SET DEFAULT nextval('errors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedback_comments ALTER COLUMN id SET DEFAULT nextval('feedback_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedback_comments_user_flags ALTER COLUMN id SET DEFAULT nextval('feedback_comments_user_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedback_customers ALTER COLUMN id SET DEFAULT nextval('feedback_customers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY measurements ALTER COLUMN id SET DEFAULT nextval('measurements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY milestone_versions ALTER COLUMN id SET DEFAULT nextval('milestone_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY milestones ALTER COLUMN id SET DEFAULT nextval('milestones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY nanoconf_presentations ALTER COLUMN id SET DEFAULT nextval('nanoconf_presentations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_providers ALTER COLUMN id SET DEFAULT nextval('oauth_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_quotas ALTER COLUMN id SET DEFAULT nextval('project_quotas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pull_requests ALTER COLUMN id SET DEFAULT nextval('pull_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY releases ALTER COLUMN id SET DEFAULT nextval('releases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roadmap_commits ALTER COLUMN id SET DEFAULT nextval('roadmap_commits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roadmap_milestone_versions ALTER COLUMN id SET DEFAULT nextval('roadmap_milestone_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roadmap_milestones ALTER COLUMN id SET DEFAULT nextval('roadmap_milestones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roadmaps ALTER COLUMN id SET DEFAULT nextval('roadmaps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sprints ALTER COLUMN id SET DEFAULT nextval('sprints_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks ALTER COLUMN id SET DEFAULT nextval('tasks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY test_errors ALTER COLUMN id SET DEFAULT nextval('test_errors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY test_results ALTER COLUMN id SET DEFAULT nextval('test_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY test_runs ALTER COLUMN id SET DEFAULT nextval('test_runs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY testing_notes ALTER COLUMN id SET DEFAULT nextval('testing_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tests ALTER COLUMN id SET DEFAULT nextval('tests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ticket_queues ALTER COLUMN id SET DEFAULT nextval('ticket_queues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tickets ALTER COLUMN id SET DEFAULT nextval('tickets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_credentials ALTER COLUMN id SET DEFAULT nextval('user_credentials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY value_statements ALTER COLUMN id SET DEFAULT nextval('value_statements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: brakeman_scans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brakeman_scans
    ADD CONSTRAINT brakeman_scans_pkey PRIMARY KEY (id);


--
-- Name: brakeman_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY brakeman_warnings
    ADD CONSTRAINT brakeman_warnings_pkey PRIMARY KEY (id);


--
-- Name: commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY commits
    ADD CONSTRAINT commits_pkey PRIMARY KEY (id);


--
-- Name: consumer_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY consumer_tokens
    ADD CONSTRAINT consumer_tokens_pkey PRIMARY KEY (id);


--
-- Name: deploys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY deploys
    ADD CONSTRAINT deploys_pkey PRIMARY KEY (id);


--
-- Name: errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY errors
    ADD CONSTRAINT errors_pkey PRIMARY KEY (id);


--
-- Name: feedback_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feedback_comments
    ADD CONSTRAINT feedback_comments_pkey PRIMARY KEY (id);


--
-- Name: feedback_comments_user_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feedback_comments_user_flags
    ADD CONSTRAINT feedback_comments_user_flags_pkey PRIMARY KEY (id);


--
-- Name: feedback_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feedback_customers
    ADD CONSTRAINT feedback_customers_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY measurements
    ADD CONSTRAINT measurements_pkey PRIMARY KEY (id);


--
-- Name: milestone_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY milestone_versions
    ADD CONSTRAINT milestone_versions_pkey PRIMARY KEY (id);


--
-- Name: milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY milestones
    ADD CONSTRAINT milestones_pkey PRIMARY KEY (id);


--
-- Name: nanoconf_presentations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY nanoconf_presentations
    ADD CONSTRAINT nanoconf_presentations_pkey PRIMARY KEY (id);


--
-- Name: oauth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_providers
    ADD CONSTRAINT oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: project_quotas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_quotas
    ADD CONSTRAINT project_quotas_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: pull_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pull_requests
    ADD CONSTRAINT pull_requests_pkey PRIMARY KEY (id);


--
-- Name: releases_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);


--
-- Name: roadmap_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roadmap_commits
    ADD CONSTRAINT roadmap_commits_pkey PRIMARY KEY (id);


--
-- Name: roadmap_milestone_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roadmap_milestone_versions
    ADD CONSTRAINT roadmap_milestone_versions_pkey PRIMARY KEY (id);


--
-- Name: roadmap_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roadmap_milestones
    ADD CONSTRAINT roadmap_milestones_pkey PRIMARY KEY (id);


--
-- Name: roadmaps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roadmaps
    ADD CONSTRAINT roadmaps_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: sprints_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sprints
    ADD CONSTRAINT sprints_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: test_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_errors
    ADD CONSTRAINT test_errors_pkey PRIMARY KEY (id);


--
-- Name: test_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_results
    ADD CONSTRAINT test_results_pkey PRIMARY KEY (id);


--
-- Name: test_results_unique_constraint; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_results
    ADD CONSTRAINT test_results_unique_constraint UNIQUE (test_run_id, test_id);


--
-- Name: test_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_runs
    ADD CONSTRAINT test_runs_pkey PRIMARY KEY (id);


--
-- Name: testing_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY testing_notes
    ADD CONSTRAINT testing_notes_pkey PRIMARY KEY (id);


--
-- Name: tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tests
    ADD CONSTRAINT tests_pkey PRIMARY KEY (id);


--
-- Name: tests_unique_constraint; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tests
    ADD CONSTRAINT tests_unique_constraint UNIQUE (project_id, suite, name);


--
-- Name: ticket_queues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ticket_queues
    ADD CONSTRAINT ticket_queues_pkey PRIMARY KEY (id);


--
-- Name: tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: user_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_credentials
    ADD CONSTRAINT user_credentials_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: value_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY value_statements
    ADD CONSTRAINT value_statements_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_alerts_commits_on_alert_id_and_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_alerts_commits_on_alert_id_and_commit_id ON alerts_commits USING btree (alert_id, commit_id);


--
-- Name: index_alerts_on_closed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_alerts_on_closed_at ON alerts USING btree (closed_at);


--
-- Name: index_alerts_on_opened_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_alerts_on_opened_at ON alerts USING btree (opened_at);


--
-- Name: index_alerts_on_type_and_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_alerts_on_type_and_key ON alerts USING btree (type, key);


--
-- Name: index_brakeman_warnings_on_fingerprint; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_brakeman_warnings_on_fingerprint ON brakeman_warnings USING btree (fingerprint);


--
-- Name: index_commits_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_project_id ON commits USING btree (project_id);


--
-- Name: index_commits_on_sha; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commits_on_sha ON commits USING btree (sha);


--
-- Name: index_commits_on_unreachable; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_unreachable ON commits USING btree (unreachable);


--
-- Name: index_commits_pull_requests_on_commit_id_and_pull_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commits_pull_requests_on_commit_id_and_pull_request_id ON commits_pull_requests USING btree (commit_id, pull_request_id);


--
-- Name: index_commits_releases_on_commit_id_and_release_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commits_releases_on_commit_id_and_release_id ON commits_releases USING btree (commit_id, release_id);


--
-- Name: index_commits_tasks_on_commit_id_and_task_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commits_tasks_on_commit_id_and_task_id ON commits_tasks USING btree (commit_id, task_id);


--
-- Name: index_commits_tickets_on_commit_id_and_ticket_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commits_tickets_on_commit_id_and_ticket_id ON commits_tickets USING btree (commit_id, ticket_id);


--
-- Name: index_commits_users_on_commit_id_and_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commits_users_on_commit_id_and_user_id ON commits_users USING btree (commit_id, user_id);


--
-- Name: index_consumer_tokens_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_consumer_tokens_on_token ON consumer_tokens USING btree (token);


--
-- Name: index_deploys_on_environment_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deploys_on_environment_name ON deploys USING btree (environment_name);


--
-- Name: index_deploys_on_project_id_and_environment_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_deploys_on_project_id_and_environment_name ON deploys USING btree (project_id, environment_name);


--
-- Name: index_errors_on_sha; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_errors_on_sha ON errors USING btree (sha);


--
-- Name: index_feedback_comments_on_tsvector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feedback_comments_on_tsvector ON feedback_comments USING gin (search_vector);


--
-- Name: index_feedback_comments_user_flags_on_user_id_and_comment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_feedback_comments_user_flags_on_user_id_and_comment_id ON feedback_comments_user_flags USING btree (user_id, comment_id);


--
-- Name: index_jobs_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_name ON jobs USING btree (name);


--
-- Name: index_measurements_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_measurements_on_name ON measurements USING btree (name);


--
-- Name: index_measurements_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_measurements_on_subject_type_and_subject_id ON measurements USING btree (subject_type, subject_id);


--
-- Name: index_measurements_on_taken_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_measurements_on_taken_at ON measurements USING btree (taken_at);


--
-- Name: index_measurements_on_taken_on; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_measurements_on_taken_on ON measurements USING btree (taken_on);


--
-- Name: index_milestone_versions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestone_versions_on_created_at ON milestone_versions USING btree (created_at);


--
-- Name: index_milestone_versions_on_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestone_versions_on_number ON milestone_versions USING btree (number);


--
-- Name: index_milestone_versions_on_roadmap_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestone_versions_on_roadmap_commit_id ON milestone_versions USING btree (roadmap_commit_id);


--
-- Name: index_milestone_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestone_versions_on_versioned_id_and_versioned_type ON milestone_versions USING btree (versioned_id, versioned_type);


--
-- Name: index_milestones_on_destroyed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestones_on_destroyed_at ON milestones USING btree (destroyed_at);


--
-- Name: index_milestones_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestones_on_project_id ON milestones USING btree (project_id);


--
-- Name: index_project_quotas_on_project_id_and_week; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_project_quotas_on_project_id_and_week ON project_quotas USING btree (project_id, week);


--
-- Name: index_project_quotas_on_week; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_project_quotas_on_week ON project_quotas USING btree (week);


--
-- Name: index_projects_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_projects_on_slug ON projects USING btree (slug);


--
-- Name: index_projects_roadmaps_on_project_id_and_roadmap_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_projects_roadmaps_on_project_id_and_roadmap_id ON projects_roadmaps USING btree (project_id, roadmap_id);


--
-- Name: index_pull_requests_on_closed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pull_requests_on_closed_at ON pull_requests USING btree (closed_at);


--
-- Name: index_pull_requests_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pull_requests_on_project_id ON pull_requests USING btree (project_id);


--
-- Name: index_pull_requests_on_project_id_and_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_pull_requests_on_project_id_and_number ON pull_requests USING btree (project_id, number);


--
-- Name: index_releases_on_deploy_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_releases_on_deploy_id ON releases USING btree (deploy_id);


--
-- Name: index_releases_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_releases_on_project_id ON releases USING btree (project_id);


--
-- Name: index_releases_on_project_id_and_environment_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_releases_on_project_id_and_environment_name ON releases USING btree (project_id, environment_name);


--
-- Name: index_releases_on_search_vector; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_releases_on_search_vector ON releases USING gin (search_vector);


--
-- Name: index_releases_tasks_on_release_id_and_task_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_releases_tasks_on_release_id_and_task_id ON releases_tasks USING btree (release_id, task_id);


--
-- Name: index_releases_tickets_on_release_id_and_ticket_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_releases_tickets_on_release_id_and_ticket_id ON releases_tickets USING btree (release_id, ticket_id);


--
-- Name: index_roadmap_milestone_versions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roadmap_milestone_versions_on_created_at ON roadmap_milestone_versions USING btree (created_at);


--
-- Name: index_roadmap_milestone_versions_on_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roadmap_milestone_versions_on_number ON roadmap_milestone_versions USING btree (number);


--
-- Name: index_roadmap_milestone_versions_on_roadmap_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roadmap_milestone_versions_on_roadmap_commit_id ON roadmap_milestone_versions USING btree (roadmap_commit_id);


--
-- Name: index_roadmap_milestone_versions_on_versioned; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roadmap_milestone_versions_on_versioned ON roadmap_milestone_versions USING btree (versioned_id, versioned_type);


--
-- Name: index_roadmap_milestones_on_milestone_id_and_roadmap_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roadmap_milestones_on_milestone_id_and_roadmap_id ON roadmap_milestones USING btree (milestone_id, roadmap_id);


--
-- Name: index_roles_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_on_user_id_and_project_id ON roles USING btree (user_id, project_id);


--
-- Name: index_roles_on_user_id_and_project_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_on_user_id_and_project_id_and_name ON roles USING btree (user_id, project_id, name);


--
-- Name: index_sprints_on_end_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_sprints_on_end_date ON sprints USING btree (end_date);


--
-- Name: index_sprints_tasks_on_sprint_id_and_task_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_sprints_tasks_on_sprint_id_and_task_id ON sprints_tasks USING btree (sprint_id, task_id);


--
-- Name: index_tasks_on_ticket_id_and_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tasks_on_ticket_id_and_number ON tasks USING btree (ticket_id, number);


--
-- Name: index_test_errors_on_sha; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_test_errors_on_sha ON test_errors USING btree (sha);


--
-- Name: index_test_results_on_test_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_test_results_on_test_id ON test_results USING btree (test_id);


--
-- Name: index_test_results_on_test_run_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_test_results_on_test_run_id ON test_results USING btree (test_run_id);


--
-- Name: index_test_runs_on_commit; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_test_runs_on_commit ON test_runs USING btree (sha);


--
-- Name: index_test_runs_on_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_test_runs_on_commit_id ON test_runs USING btree (commit_id);


--
-- Name: index_test_runs_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_test_runs_on_project_id ON test_runs USING btree (project_id);


--
-- Name: index_testing_notes_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_testing_notes_on_project_id ON testing_notes USING btree (project_id);


--
-- Name: index_testing_notes_on_ticket_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_testing_notes_on_ticket_id ON testing_notes USING btree (ticket_id);


--
-- Name: index_testing_notes_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_testing_notes_on_user_id ON testing_notes USING btree (user_id);


--
-- Name: index_tests_on_project_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tests_on_project_id ON tests USING btree (project_id);


--
-- Name: index_ticket_queues_on_queue; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ticket_queues_on_queue ON ticket_queues USING btree (queue);


--
-- Name: index_ticket_queues_on_ticket_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ticket_queues_on_ticket_id ON ticket_queues USING btree (ticket_id);


--
-- Name: index_tickets_on_destroyed_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tickets_on_destroyed_at ON tickets USING btree (destroyed_at);


--
-- Name: index_tickets_on_milestone_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tickets_on_milestone_id ON tickets USING btree (milestone_id);


--
-- Name: index_tickets_on_resolution; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tickets_on_resolution ON tickets USING btree (resolution);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_email_addresses; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_email_addresses ON users USING btree (email_addresses);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_invitation_token ON users USING btree (invitation_token);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_invited_by_id ON users USING btree (invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_created_at ON versions USING btree (created_at);


--
-- Name: index_versions_on_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_number ON versions USING btree (number);


--
-- Name: index_versions_on_tag; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_tag ON versions USING btree (tag);


--
-- Name: index_versions_on_user_id_and_user_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_user_id_and_user_type ON versions USING btree (user_id, user_type);


--
-- Name: index_versions_on_user_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_user_name ON versions USING btree (user_name);


--
-- Name: index_versions_on_versioned_id_and_versioned_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_versions_on_versioned_id_and_versioned_type ON versions USING btree (versioned_id, versioned_type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20120324185914');

INSERT INTO schema_migrations (version) VALUES ('20120324202224');

INSERT INTO schema_migrations (version) VALUES ('20120324212848');

INSERT INTO schema_migrations (version) VALUES ('20120324212946');

INSERT INTO schema_migrations (version) VALUES ('20120324230038');

INSERT INTO schema_migrations (version) VALUES ('20120406185643');

INSERT INTO schema_migrations (version) VALUES ('20120408155047');

INSERT INTO schema_migrations (version) VALUES ('20120417175450');

INSERT INTO schema_migrations (version) VALUES ('20120417175841');

INSERT INTO schema_migrations (version) VALUES ('20120417190504');

INSERT INTO schema_migrations (version) VALUES ('20120417195313');

INSERT INTO schema_migrations (version) VALUES ('20120417195433');

INSERT INTO schema_migrations (version) VALUES ('20120424212706');

INSERT INTO schema_migrations (version) VALUES ('20120501230243');

INSERT INTO schema_migrations (version) VALUES ('20120501231817');

INSERT INTO schema_migrations (version) VALUES ('20120501231948');

INSERT INTO schema_migrations (version) VALUES ('20120504143615');

INSERT INTO schema_migrations (version) VALUES ('20120525013703');

INSERT INTO schema_migrations (version) VALUES ('20120607124115');

INSERT INTO schema_migrations (version) VALUES ('20120626140242');

INSERT INTO schema_migrations (version) VALUES ('20120626150333');

INSERT INTO schema_migrations (version) VALUES ('20120626151320');

INSERT INTO schema_migrations (version) VALUES ('20120626152020');

INSERT INTO schema_migrations (version) VALUES ('20120626152949');

INSERT INTO schema_migrations (version) VALUES ('20120715230526');

INSERT INTO schema_migrations (version) VALUES ('20120715230922');

INSERT INTO schema_migrations (version) VALUES ('20120716010743');

INSERT INTO schema_migrations (version) VALUES ('20120726212620');

INSERT INTO schema_migrations (version) VALUES ('20120726231754');

INSERT INTO schema_migrations (version) VALUES ('20120804003344');

INSERT INTO schema_migrations (version) VALUES ('20120823025935');

INSERT INTO schema_migrations (version) VALUES ('20120826022643');

INSERT INTO schema_migrations (version) VALUES ('20120827190634');

INSERT INTO schema_migrations (version) VALUES ('20120913020218');

INSERT INTO schema_migrations (version) VALUES ('20120920023251');

INSERT INTO schema_migrations (version) VALUES ('20120922010212');

INSERT INTO schema_migrations (version) VALUES ('20121026014457');

INSERT INTO schema_migrations (version) VALUES ('20121027160548');

INSERT INTO schema_migrations (version) VALUES ('20121027171215');

INSERT INTO schema_migrations (version) VALUES ('20121104233305');

INSERT INTO schema_migrations (version) VALUES ('20121126005019');

INSERT INTO schema_migrations (version) VALUES ('20121214025558');

INSERT INTO schema_migrations (version) VALUES ('20121219202734');

INSERT INTO schema_migrations (version) VALUES ('20121220031008');

INSERT INTO schema_migrations (version) VALUES ('20121222170917');

INSERT INTO schema_migrations (version) VALUES ('20121222223325');

INSERT INTO schema_migrations (version) VALUES ('20121222223635');

INSERT INTO schema_migrations (version) VALUES ('20121224212623');

INSERT INTO schema_migrations (version) VALUES ('20121225175106');

INSERT INTO schema_migrations (version) VALUES ('20121230173644');

INSERT INTO schema_migrations (version) VALUES ('20121230174234');

INSERT INTO schema_migrations (version) VALUES ('20130105200429');

INSERT INTO schema_migrations (version) VALUES ('20130106184327');

INSERT INTO schema_migrations (version) VALUES ('20130106185425');

INSERT INTO schema_migrations (version) VALUES ('20130119203853');

INSERT INTO schema_migrations (version) VALUES ('20130119204608');

INSERT INTO schema_migrations (version) VALUES ('20130119211540');

INSERT INTO schema_migrations (version) VALUES ('20130119212008');

INSERT INTO schema_migrations (version) VALUES ('20130120182026');

INSERT INTO schema_migrations (version) VALUES ('20130211015046');

INSERT INTO schema_migrations (version) VALUES ('20130302205014');

INSERT INTO schema_migrations (version) VALUES ('20130306023456');

INSERT INTO schema_migrations (version) VALUES ('20130306023613');

INSERT INTO schema_migrations (version) VALUES ('20130312224911');

INSERT INTO schema_migrations (version) VALUES ('20130319003918');

INSERT INTO schema_migrations (version) VALUES ('20130407195450');

INSERT INTO schema_migrations (version) VALUES ('20130407200624');

INSERT INTO schema_migrations (version) VALUES ('20130407220039');

INSERT INTO schema_migrations (version) VALUES ('20130407220937');

INSERT INTO schema_migrations (version) VALUES ('20130407221459');

INSERT INTO schema_migrations (version) VALUES ('20130416020627');

INSERT INTO schema_migrations (version) VALUES ('20130420151334');

INSERT INTO schema_migrations (version) VALUES ('20130420155332');

INSERT INTO schema_migrations (version) VALUES ('20130420172322');

INSERT INTO schema_migrations (version) VALUES ('20130420174002');

INSERT INTO schema_migrations (version) VALUES ('20130420174126');

INSERT INTO schema_migrations (version) VALUES ('20130427223925');

INSERT INTO schema_migrations (version) VALUES ('20130428005808');

INSERT INTO schema_migrations (version) VALUES ('20130504014802');

INSERT INTO schema_migrations (version) VALUES ('20130504135741');

INSERT INTO schema_migrations (version) VALUES ('20130505144446');

INSERT INTO schema_migrations (version) VALUES ('20130505162039');

INSERT INTO schema_migrations (version) VALUES ('20130505212838');

INSERT INTO schema_migrations (version) VALUES ('20130518224352');

INSERT INTO schema_migrations (version) VALUES ('20130518224406');

INSERT INTO schema_migrations (version) VALUES ('20130518224655');

INSERT INTO schema_migrations (version) VALUES ('20130518224722');

INSERT INTO schema_migrations (version) VALUES ('20130519163615');

INSERT INTO schema_migrations (version) VALUES ('20130525192607');

INSERT INTO schema_migrations (version) VALUES ('20130525222131');

INSERT INTO schema_migrations (version) VALUES ('20130526024851');

INSERT INTO schema_migrations (version) VALUES ('20130706141443');

INSERT INTO schema_migrations (version) VALUES ('20130710233849');

INSERT INTO schema_migrations (version) VALUES ('20130711004558');

INSERT INTO schema_migrations (version) VALUES ('20130711013156');

INSERT INTO schema_migrations (version) VALUES ('20130728191005');

INSERT INTO schema_migrations (version) VALUES ('20130806143651');

INSERT INTO schema_migrations (version) VALUES ('20130815232527');

INSERT INTO schema_migrations (version) VALUES ('20130914152419');

INSERT INTO schema_migrations (version) VALUES ('20130914155044');

INSERT INTO schema_migrations (version) VALUES ('20130921141449');

INSERT INTO schema_migrations (version) VALUES ('20131002005512');

INSERT INTO schema_migrations (version) VALUES ('20131002015547');

INSERT INTO schema_migrations (version) VALUES ('20131002145620');

INSERT INTO schema_migrations (version) VALUES ('20131003014023');

INSERT INTO schema_migrations (version) VALUES ('20131004015452');

INSERT INTO schema_migrations (version) VALUES ('20131004185618');

INSERT INTO schema_migrations (version) VALUES ('20131012152403');

INSERT INTO schema_migrations (version) VALUES ('20131013185636');

INSERT INTO schema_migrations (version) VALUES ('20131027214942');

INSERT INTO schema_migrations (version) VALUES ('20131112010815');

INSERT INTO schema_migrations (version) VALUES ('20131216014505');

INSERT INTO schema_migrations (version) VALUES ('20131223194246');

INSERT INTO schema_migrations (version) VALUES ('20140106212047');

INSERT INTO schema_migrations (version) VALUES ('20140106212305');

INSERT INTO schema_migrations (version) VALUES ('20140114014144');

INSERT INTO schema_migrations (version) VALUES ('20140217150735');

INSERT INTO schema_migrations (version) VALUES ('20140217160450');

INSERT INTO schema_migrations (version) VALUES ('20140217195942');

INSERT INTO schema_migrations (version) VALUES ('20140327020121');

INSERT INTO schema_migrations (version) VALUES ('20140401234330');

INSERT INTO schema_migrations (version) VALUES ('20140406183224');

INSERT INTO schema_migrations (version) VALUES ('20140406230121');

INSERT INTO schema_migrations (version) VALUES ('20140407010111');

INSERT INTO schema_migrations (version) VALUES ('20140411214022');

INSERT INTO schema_migrations (version) VALUES ('20140418133005');

INSERT INTO schema_migrations (version) VALUES ('20140419152214');

INSERT INTO schema_migrations (version) VALUES ('20140425141946');

INSERT INTO schema_migrations (version) VALUES ('20140427235508');

INSERT INTO schema_migrations (version) VALUES ('20140428023146');

INSERT INTO schema_migrations (version) VALUES ('20140429000919');

INSERT INTO schema_migrations (version) VALUES ('20140506032958');

INSERT INTO schema_migrations (version) VALUES ('20140506035755');

INSERT INTO schema_migrations (version) VALUES ('20140511024021');

INSERT INTO schema_migrations (version) VALUES ('20140515174322');

INSERT INTO schema_migrations (version) VALUES ('20140515200824');

INSERT INTO schema_migrations (version) VALUES ('20140516005310');

INSERT INTO schema_migrations (version) VALUES ('20140516012049');

INSERT INTO schema_migrations (version) VALUES ('20140517012626');

INSERT INTO schema_migrations (version) VALUES ('20140521014652');

INSERT INTO schema_migrations (version) VALUES ('20140526155845');

INSERT INTO schema_migrations (version) VALUES ('20140526162645');

INSERT INTO schema_migrations (version) VALUES ('20140526180608');

INSERT INTO schema_migrations (version) VALUES ('20140606232907');

INSERT INTO schema_migrations (version) VALUES ('20140724231918');

INSERT INTO schema_migrations (version) VALUES ('20140806233301');

INSERT INTO schema_migrations (version) VALUES ('20140807212311');

INSERT INTO schema_migrations (version) VALUES ('20140810224209');

INSERT INTO schema_migrations (version) VALUES ('20140813010452');

INSERT INTO schema_migrations (version) VALUES ('20140815000804');

INSERT INTO schema_migrations (version) VALUES ('20140815022909');

INSERT INTO schema_migrations (version) VALUES ('20140821000627');

INSERT INTO schema_migrations (version) VALUES ('20140824194031');

INSERT INTO schema_migrations (version) VALUES ('20140824194526');

INSERT INTO schema_migrations (version) VALUES ('20140824211249');

INSERT INTO schema_migrations (version) VALUES ('20140831210254');

INSERT INTO schema_migrations (version) VALUES ('20140907005810');

INSERT INTO schema_migrations (version) VALUES ('20140907012329');

INSERT INTO schema_migrations (version) VALUES ('20140907013836');

INSERT INTO schema_migrations (version) VALUES ('20140907212311');

INSERT INTO schema_migrations (version) VALUES ('20140916230539');

INSERT INTO schema_migrations (version) VALUES ('20140921190022');

INSERT INTO schema_migrations (version) VALUES ('20140921201441');

INSERT INTO schema_migrations (version) VALUES ('20140921203932');

INSERT INTO schema_migrations (version) VALUES ('20140925021043');

INSERT INTO schema_migrations (version) VALUES ('20140927154728');

INSERT INTO schema_migrations (version) VALUES ('20140929004347');

INSERT INTO schema_migrations (version) VALUES ('20140929024130');

INSERT INTO schema_migrations (version) VALUES ('20141012023628');

INSERT INTO schema_migrations (version) VALUES ('20141027194819');

INSERT INTO schema_migrations (version) VALUES ('20141125162853');

INSERT INTO schema_migrations (version) VALUES ('20141128155140');

INSERT INTO schema_migrations (version) VALUES ('20141202004123');

INSERT INTO schema_migrations (version) VALUES ('20141226171730');

INSERT INTO schema_migrations (version) VALUES ('20150102192805');

INSERT INTO schema_migrations (version) VALUES ('20150113025408');

INSERT INTO schema_migrations (version) VALUES ('20150116153233');

INSERT INTO schema_migrations (version) VALUES ('20150119154013');

INSERT INTO schema_migrations (version) VALUES ('20150119155145');

INSERT INTO schema_migrations (version) VALUES ('20150220215154');

INSERT INTO schema_migrations (version) VALUES ('20150222205616');

INSERT INTO schema_migrations (version) VALUES ('20150222214124');

INSERT INTO schema_migrations (version) VALUES ('20150223013721');

INSERT INTO schema_migrations (version) VALUES ('20150302153319');

INSERT INTO schema_migrations (version) VALUES ('20150323004452');

INSERT INTO schema_migrations (version) VALUES ('20150323011050');

INSERT INTO schema_migrations (version) VALUES ('20150524203903');

INSERT INTO schema_migrations (version) VALUES ('20150603203744');

INSERT INTO schema_migrations (version) VALUES ('20150708235654');

INSERT INTO schema_migrations (version) VALUES ('20150711220519');

INSERT INTO schema_migrations (version) VALUES ('20150711220542');

INSERT INTO schema_migrations (version) VALUES ('20150805180939');

INSERT INTO schema_migrations (version) VALUES ('20150805233946');

INSERT INTO schema_migrations (version) VALUES ('20150806032230');

INSERT INTO schema_migrations (version) VALUES ('20150808161729');

INSERT INTO schema_migrations (version) VALUES ('20150808161805');

INSERT INTO schema_migrations (version) VALUES ('20150808162928');

INSERT INTO schema_migrations (version) VALUES ('20150808192103');

INSERT INTO schema_migrations (version) VALUES ('20150808193354');

INSERT INTO schema_migrations (version) VALUES ('20150809132417');

INSERT INTO schema_migrations (version) VALUES ('20150809201942');

INSERT INTO schema_migrations (version) VALUES ('20150815005551');

INSERT INTO schema_migrations (version) VALUES ('20150817232311');

INSERT INTO schema_migrations (version) VALUES ('20150818005716');

INSERT INTO schema_migrations (version) VALUES ('20150820023708');

INSERT INTO schema_migrations (version) VALUES ('20150902005758');

INSERT INTO schema_migrations (version) VALUES ('20150902010629');

INSERT INTO schema_migrations (version) VALUES ('20150902010853');

INSERT INTO schema_migrations (version) VALUES ('20150916152641');

INSERT INTO schema_migrations (version) VALUES ('20150927014445');

INSERT INTO schema_migrations (version) VALUES ('20151024164701');

INSERT INTO schema_migrations (version) VALUES ('20151024170230');

INSERT INTO schema_migrations (version) VALUES ('20151108221505');

INSERT INTO schema_migrations (version) VALUES ('20151108223154');

INSERT INTO schema_migrations (version) VALUES ('20151108233510');

INSERT INTO schema_migrations (version) VALUES ('20151201042126');

INSERT INTO schema_migrations (version) VALUES ('20151202005557');

INSERT INTO schema_migrations (version) VALUES ('20151202011812');

INSERT INTO schema_migrations (version) VALUES ('20151205204922');

INSERT INTO schema_migrations (version) VALUES ('20151205214647');

INSERT INTO schema_migrations (version) VALUES ('20151205222043');

INSERT INTO schema_migrations (version) VALUES ('20151205223652');

INSERT INTO schema_migrations (version) VALUES ('20151206004534');

INSERT INTO schema_migrations (version) VALUES ('20151209004458');

INSERT INTO schema_migrations (version) VALUES ('20151209030113');

INSERT INTO schema_migrations (version) VALUES ('20151226154901');

INSERT INTO schema_migrations (version) VALUES ('20151226155305');

INSERT INTO schema_migrations (version) VALUES ('20151228183704');

INSERT INTO schema_migrations (version) VALUES ('20160120145757');

INSERT INTO schema_migrations (version) VALUES ('20160202021439');

INSERT INTO schema_migrations (version) VALUES ('20160206214746');

INSERT INTO schema_migrations (version) VALUES ('20160207154530');

INSERT INTO schema_migrations (version) VALUES ('20160208233434');

INSERT INTO schema_migrations (version) VALUES ('20160225021717');

INSERT INTO schema_migrations (version) VALUES ('20160317140151');

INSERT INTO schema_migrations (version) VALUES ('20160419230411');

INSERT INTO schema_migrations (version) VALUES ('20160420000616');

INSERT INTO schema_migrations (version) VALUES ('20160421022627');

INSERT INTO schema_migrations (version) VALUES ('20160507135209');

INSERT INTO schema_migrations (version) VALUES ('20160507135846');

INSERT INTO schema_migrations (version) VALUES ('20160510233329');

INSERT INTO schema_migrations (version) VALUES ('20160520201427');

