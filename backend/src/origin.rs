/*
    Writes must come from the website itself
    --------------------------------------------------------------------
    - the website's cookie goes with a request from any *.markcliq.com
      page: SameSite=Lax stops other sites, not sibling subdomains. So a
      form there could approve or pay as the logged-in admin (QA A8)
    - GET, HEAD and OPTIONS pass: they change nothing
    - a bearer token passes: a page can't make a browser attach one
    - else the browser says where the request came from:
        - Sec-Fetch-Site: only same-origin (or none, typed by the person)
        - older browsers, Origin: its host must be the request's Host
        - neither header: not a browser, so no cookie was borrowed
    - 403 `auth.cross_origin`. Log in is covered too, so another page
      can't log someone into the sender's account
*/

use axum::{
    extract::Request,
    http::{HeaderMap, Method, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};

use crate::{error::ApiError, extract::bearer_token};

pub async fn same_origin(req: Request, next: Next) -> Response {
    let read = matches!(*req.method(), Method::GET | Method::HEAD | Method::OPTIONS);
    if read || bearer_token(req.headers()).is_some() || from_here(req.headers()) {
        return next.run(req).await;
    }
    ApiError::new(
        StatusCode::FORBIDDEN,
        "auth.cross_origin",
        "This request didn't come from the website",
    )
    .into_response()
}

fn from_here(headers: &HeaderMap) -> bool {
    if let Some(site) = headers.get("sec-fetch-site") {
        return site == "same-origin" || site == "none";
    }
    let Some(origin) = headers.get(header::ORIGIN) else {
        return true;
    };
    let host = headers.get(header::HOST).and_then(|h| h.to_str().ok());
    let origin = origin
        .to_str()
        .ok()
        .and_then(|o| o.split_once("://"))
        .map(|(_, host)| host);
    origin.is_some() && origin == host
}
