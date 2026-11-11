//! The OpenAPI spec generated from the handlers, served at `/api/docs`.
//! CI compares it with the committed ../api/openapi.yaml.

use axum::Router;
use utoipa::{
    Modify, OpenApi,
    openapi::security::{ApiKey, ApiKeyValue, HttpAuthScheme, HttpBuilder, SecurityScheme},
};
use utoipa_scalar::{Scalar, Servable};

use crate::{
    API_PREFIX, AppState,
    error::{FieldError, Problem},
};

#[derive(OpenApi)]
#[openapi(
    info(title = "SolaCliq API"),
    servers((url = "/api/v1")),
    components(schemas(Problem, FieldError)),
    // Every endpoint needs a login unless it says `security(())`.
    security(("bearer" = []), ("cookie" = [])),
    modifiers(&AuthSchemes),
)]
pub struct ApiDoc;

/// Declares the two ways to log in that `security` above refers to.
struct AuthSchemes;

impl Modify for AuthSchemes {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        let components = openapi.components.get_or_insert_with(Default::default);
        components.add_security_scheme(
            "bearer",
            SecurityScheme::Http(HttpBuilder::new().scheme(HttpAuthScheme::Bearer).build()),
        );
        components.add_security_scheme(
            "cookie",
            SecurityScheme::ApiKey(ApiKey::Cookie(ApiKeyValue::new(
                crate::extract::SESSION_COOKIE,
            ))),
        );
    }
}

/// The full spec, with every route registered in `routes::router()`.
pub fn spec() -> utoipa::openapi::OpenApi {
    crate::routes::router().into_openapi()
}

pub fn spec_json() -> String {
    spec().to_pretty_json().expect("spec serialises")
}

pub fn docs(spec: utoipa::openapi::OpenApi) -> Router<AppState> {
    debug_assert_eq!(API_PREFIX, "/api/v1", "update servers() above too");
    Router::new().merge(Scalar::with_url("/api/docs", spec))
}
