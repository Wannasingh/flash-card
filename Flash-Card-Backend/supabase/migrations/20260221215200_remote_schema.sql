


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


CREATE SCHEMA IF NOT EXISTS "flashcard";


ALTER SCHEMA "flashcard" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "flashcard"."upload_profile_image"("p_user_id" bigint, "p_image_data" "bytea", "p_content_type" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_file_name TEXT;
    v_folder_path TEXT;
    v_storage_path TEXT;
    v_bucket_id TEXT := 'flashcard.profile.picture';
    v_object_id UUID;
BEGIN
    -- 1. Generate path: user_id/uuid.png
    v_folder_path := p_user_id::TEXT;
    v_file_name := gen_random_uuid()::TEXT || '.png';
    v_storage_path := v_folder_path || '/' || v_file_name;

    -- 2. Insert into storage.objects (direct table insert)
    -- This handles the physical storage reference in Supabase
    INSERT INTO storage.objects (
        bucket_id, 
        name, 
        owner, 
        metadata
    ) VALUES (
        v_bucket_id, 
        v_storage_path, 
        NULL, -- Owner can be NULL for anonymous/service-role uploads
        jsonb_build_object(
            'size', octet_length(p_image_data),
            'mimetype', p_content_type
        )
    ) RETURNING id INTO v_object_id;

    -- Note: In a production Supabase environment, the binary data usually goes to specialized storage (S3).
    -- However, for self-hosted/local, we might need to handle the binary specifically if NOT using the storage API.
    -- BUT, if using the storage API via SQL is preferred:
    -- We will store the path in our users table.

    -- 3. Update the user table
    UPDATE flashcard.users 
    SET 
        image_url = v_bucket_id || '/' || v_storage_path,
        image_source = 'MANUAL',
        image_updated_at = NOW()
    WHERE id = p_user_id;

    RETURN v_bucket_id || '/' || v_storage_path;
END;
$$;


ALTER FUNCTION "flashcard"."upload_profile_image"("p_user_id" bigint, "p_image_data" "bytea", "p_content_type" "text") OWNER TO "supabase_admin";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "flashcard"."badges" (
    "id" bigint NOT NULL,
    "code" character varying(50) NOT NULL,
    "name" character varying(255) NOT NULL,
    "description" "text" NOT NULL,
    "icon_url" "text",
    "category" character varying(20) NOT NULL
);


ALTER TABLE "flashcard"."badges" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."badges_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."badges_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."badges_id_seq" OWNED BY "flashcard"."badges"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."cards" (
    "id" bigint NOT NULL,
    "deck_id" bigint NOT NULL,
    "front_text" "text" NOT NULL,
    "back_text" "text" NOT NULL,
    "image_url" "text",
    "video_url" "text",
    "ar_model_url" "text",
    "meme_url" "text",
    "ai_mnemonic" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."cards" OWNER TO "supabase_admin";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."cards_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."cards_id_seq" OWNER TO "supabase_admin";


ALTER SEQUENCE "flashcard"."cards_id_seq" OWNED BY "flashcard"."cards"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."decks" (
    "id" bigint NOT NULL,
    "creator_id" bigint NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text",
    "tags" character varying(255)[],
    "is_public" boolean DEFAULT false,
    "price" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."decks" OWNER TO "supabase_admin";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."decks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."decks_id_seq" OWNER TO "supabase_admin";


ALTER SEQUENCE "flashcard"."decks_id_seq" OWNED BY "flashcard"."decks"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."flyway_schema_history" (
    "installed_rank" integer NOT NULL,
    "version" character varying(50),
    "description" character varying(200) NOT NULL,
    "type" character varying(20) NOT NULL,
    "script" character varying(1000) NOT NULL,
    "checksum" integer,
    "installed_by" character varying(100) NOT NULL,
    "installed_on" timestamp without time zone DEFAULT "now"() NOT NULL,
    "execution_time" integer NOT NULL,
    "success" boolean NOT NULL
);


ALTER TABLE "flashcard"."flyway_schema_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "flashcard"."refresh_tokens" (
    "id" bigint NOT NULL,
    "token" character varying(512) NOT NULL,
    "user_id" bigint NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."refresh_tokens" OWNER TO "supabase_admin";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."refresh_tokens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."refresh_tokens_id_seq" OWNER TO "supabase_admin";


ALTER SEQUENCE "flashcard"."refresh_tokens_id_seq" OWNED BY "flashcard"."refresh_tokens"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."roles" (
    "id" integer NOT NULL,
    "name" character varying(20)
);


ALTER TABLE "flashcard"."roles" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."roles_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."roles_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."roles_id_seq" OWNED BY "flashcard"."roles"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."store_items" (
    "id" bigint NOT NULL,
    "code" character varying(50) NOT NULL,
    "name" character varying(100) NOT NULL,
    "type" character varying(20) NOT NULL,
    "price" integer DEFAULT 0 NOT NULL,
    "visual_config" "text"
);


ALTER TABLE "flashcard"."store_items" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."store_items_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."store_items_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."store_items_id_seq" OWNED BY "flashcard"."store_items"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."study_progress" (
    "user_id" bigint NOT NULL,
    "card_id" bigint NOT NULL,
    "easiness_factor" real DEFAULT 2.5,
    "interval_days" integer DEFAULT 0,
    "repetitions" integer DEFAULT 0,
    "next_review_at" timestamp with time zone,
    "last_reviewed_at" timestamp with time zone
);


ALTER TABLE "flashcard"."study_progress" OWNER TO "supabase_admin";


CREATE TABLE IF NOT EXISTS "flashcard"."study_rooms" (
    "id" bigint NOT NULL,
    "room_code" character varying(10) NOT NULL,
    "host_id" bigint NOT NULL,
    "deck_id" bigint NOT NULL,
    "status" character varying(20) DEFAULT 'WAITING'::character varying,
    "mode" character varying(20) DEFAULT 'COOP'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."study_rooms" OWNER TO "supabase_admin";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."study_rooms_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."study_rooms_id_seq" OWNER TO "supabase_admin";


ALTER SEQUENCE "flashcard"."study_rooms_id_seq" OWNED BY "flashcard"."study_rooms"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."user_badges" (
    "id" bigint NOT NULL,
    "user_id" bigint NOT NULL,
    "badge_id" bigint NOT NULL,
    "awarded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."user_badges" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."user_badges_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."user_badges_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."user_badges_id_seq" OWNED BY "flashcard"."user_badges"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."user_decks" (
    "user_id" bigint NOT NULL,
    "deck_id" bigint NOT NULL,
    "is_favorite" boolean DEFAULT false,
    "acquired_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."user_decks" OWNER TO "supabase_admin";


CREATE TABLE IF NOT EXISTS "flashcard"."user_identities" (
    "id" bigint NOT NULL,
    "user_id" bigint NOT NULL,
    "provider" character varying(20) NOT NULL,
    "provider_user_id" character varying(255) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "flashcard"."user_identities" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."user_identities_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."user_identities_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."user_identities_id_seq" OWNED BY "flashcard"."user_identities"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."user_inventory" (
    "id" bigint NOT NULL,
    "user_id" bigint NOT NULL,
    "item_id" bigint NOT NULL,
    "acquired_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "flashcard"."user_inventory" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."user_inventory_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."user_inventory_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."user_inventory_id_seq" OWNED BY "flashcard"."user_inventory"."id";



CREATE TABLE IF NOT EXISTS "flashcard"."user_roles" (
    "user_id" bigint NOT NULL,
    "role_id" integer NOT NULL
);


ALTER TABLE "flashcard"."user_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "flashcard"."users" (
    "id" bigint NOT NULL,
    "email" character varying(255) NOT NULL,
    "password" character varying(255),
    "username" character varying(255) NOT NULL,
    "display_name" character varying(255),
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "last_login_at" timestamp with time zone,
    "image_source" character varying(20),
    "image_updated_at" timestamp with time zone,
    "coins" integer DEFAULT 0,
    "streak_days" integer DEFAULT 0,
    "last_study_date" "date",
    "total_xp" bigint DEFAULT 0,
    "weekly_xp" bigint DEFAULT 0,
    "active_aura_code" character varying(50),
    "active_skin_code" character varying(50)
);


ALTER TABLE "flashcard"."users" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "flashcard"."users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "flashcard"."users_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "flashcard"."users_id_seq" OWNED BY "flashcard"."users"."id";



ALTER TABLE ONLY "flashcard"."badges" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."badges_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."cards" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."cards_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."decks" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."decks_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."refresh_tokens" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."refresh_tokens_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."roles" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."roles_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."store_items" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."store_items_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."study_rooms" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."study_rooms_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."user_badges" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."user_badges_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."user_identities" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."user_identities_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."user_inventory" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."user_inventory_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."users" ALTER COLUMN "id" SET DEFAULT "nextval"('"flashcard"."users_id_seq"'::"regclass");



ALTER TABLE ONLY "flashcard"."badges"
    ADD CONSTRAINT "badges_code_key" UNIQUE ("code");



ALTER TABLE ONLY "flashcard"."badges"
    ADD CONSTRAINT "badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."cards"
    ADD CONSTRAINT "cards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."decks"
    ADD CONSTRAINT "decks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."flyway_schema_history"
    ADD CONSTRAINT "flyway_schema_history_pk" PRIMARY KEY ("installed_rank");



ALTER TABLE ONLY "flashcard"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_token_key" UNIQUE ("token");



ALTER TABLE ONLY "flashcard"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."store_items"
    ADD CONSTRAINT "store_items_code_key" UNIQUE ("code");



ALTER TABLE ONLY "flashcard"."store_items"
    ADD CONSTRAINT "store_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."study_progress"
    ADD CONSTRAINT "study_progress_pkey" PRIMARY KEY ("user_id", "card_id");



ALTER TABLE ONLY "flashcard"."study_rooms"
    ADD CONSTRAINT "study_rooms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."study_rooms"
    ADD CONSTRAINT "study_rooms_room_code_key" UNIQUE ("room_code");



ALTER TABLE ONLY "flashcard"."users"
    ADD CONSTRAINT "uk6dotkott2kjsp8vw4d0m25fb7" UNIQUE ("email");



ALTER TABLE ONLY "flashcard"."roles"
    ADD CONSTRAINT "uk_ofx66keruapi6vyqpv6f2or37" UNIQUE ("name");



ALTER TABLE ONLY "flashcard"."users"
    ADD CONSTRAINT "ukr43af9ap4edm43mmtq01oddj6" UNIQUE ("username");



ALTER TABLE ONLY "flashcard"."user_identities"
    ADD CONSTRAINT "uq_user_identities_provider_user" UNIQUE ("provider", "provider_user_id");



ALTER TABLE ONLY "flashcard"."user_identities"
    ADD CONSTRAINT "uq_user_identities_user_provider" UNIQUE ("user_id", "provider");



ALTER TABLE ONLY "flashcard"."user_badges"
    ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."user_decks"
    ADD CONSTRAINT "user_decks_pkey" PRIMARY KEY ("user_id", "deck_id");



ALTER TABLE ONLY "flashcard"."user_identities"
    ADD CONSTRAINT "user_identities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."user_inventory"
    ADD CONSTRAINT "user_inventory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "flashcard"."user_inventory"
    ADD CONSTRAINT "user_inventory_user_id_item_id_key" UNIQUE ("user_id", "item_id");



ALTER TABLE ONLY "flashcard"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "role_id");



ALTER TABLE ONLY "flashcard"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "flyway_schema_history_s_idx" ON "flashcard"."flyway_schema_history" USING "btree" ("success");



CREATE INDEX "idx_refresh_tokens_token" ON "flashcard"."refresh_tokens" USING "btree" ("token");



ALTER TABLE ONLY "flashcard"."cards"
    ADD CONSTRAINT "fk_cards_deck" FOREIGN KEY ("deck_id") REFERENCES "flashcard"."decks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."decks"
    ADD CONSTRAINT "fk_decks_creator" FOREIGN KEY ("creator_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."refresh_tokens"
    ADD CONSTRAINT "fk_refresh_tokens_user" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."study_progress"
    ADD CONSTRAINT "fk_study_progress_card" FOREIGN KEY ("card_id") REFERENCES "flashcard"."cards"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."study_progress"
    ADD CONSTRAINT "fk_study_progress_user" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."study_rooms"
    ADD CONSTRAINT "fk_study_rooms_deck" FOREIGN KEY ("deck_id") REFERENCES "flashcard"."decks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."study_rooms"
    ADD CONSTRAINT "fk_study_rooms_host" FOREIGN KEY ("host_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_badges"
    ADD CONSTRAINT "fk_user_badges_badge" FOREIGN KEY ("badge_id") REFERENCES "flashcard"."badges"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_badges"
    ADD CONSTRAINT "fk_user_badges_user" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_decks"
    ADD CONSTRAINT "fk_user_decks_deck" FOREIGN KEY ("deck_id") REFERENCES "flashcard"."decks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_decks"
    ADD CONSTRAINT "fk_user_decks_user" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_identities"
    ADD CONSTRAINT "fk_user_identities_user" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_inventory"
    ADD CONSTRAINT "fk_user_inventory_item" FOREIGN KEY ("item_id") REFERENCES "flashcard"."store_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_inventory"
    ADD CONSTRAINT "fk_user_inventory_user" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "flashcard"."user_roles"
    ADD CONSTRAINT "fkh8ciramu9cc9q3qcqiv4ue8a6" FOREIGN KEY ("role_id") REFERENCES "flashcard"."roles"("id");



ALTER TABLE ONLY "flashcard"."user_roles"
    ADD CONSTRAINT "fkhfh9dx7w3ubf1co1vdev94g3f" FOREIGN KEY ("user_id") REFERENCES "flashcard"."users"("id");





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
































































































































































































ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "service_role";































RESET ALL;
