/*
    Production database and its logins, run once as the postgres superuser:

      sudo -u postgres psql -v ON_ERROR_STOP=1 \
        -v owner_pw="$(openssl rand -hex 24)" ... (see deploy/README.md)

    - solacliq: owns the database and runs the migrations (DATABASE_URL).
      Not a superuser. CREATEROLE and the admin option on solacliq_app
      are what the row-level security migration needs (it re-creates and
      grants that role)
    - solacliq_app: no login; the policies and table grants are for it
    - solacliq_api: the login the server answers requests with
      (APP_DATABASE_URL); owns nothing, so every policy applies to it
*/
CREATE ROLE solacliq LOGIN CREATEROLE PASSWORD :'owner_pw';
CREATE ROLE solacliq_app NOLOGIN;
GRANT solacliq_app TO solacliq WITH ADMIN OPTION;
CREATE ROLE solacliq_api LOGIN PASSWORD :'api_pw';
GRANT solacliq_app TO solacliq_api;
CREATE DATABASE solacliq OWNER solacliq;
