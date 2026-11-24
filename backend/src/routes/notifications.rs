/*
    A person's notifications in one company (phase 7)
    --------------------------------------------------------------------
    - GET  /orgs/{org_id}/notifications       their feed there, newest first
    - POST /orgs/{org_id}/notifications/read  mark all of it read
    - any member of an active company (`OrgMember`); a person only ever
      sees their own rows, in that company only
    - the personal feed (no company) is /me/notifications, in profile.rs
*/

use axum::{Json, extract::State, http::StatusCode};
use utoipa_axum::{router::OpenApiRouter, routes};

use crate::{
    AppState,
    error::ApiResult,
    extract::ApiQuery,
    notify::{self, NotificationPage},
    org::OrgMember,
    page::Page,
    routes::profile::FeedQuery,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(org_notifications))
        .routes(routes!(read_org_notifications))
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/notifications",
    operation_id = "listNotifications",
    tag = "notifications",
    params(("org_id" = uuid::Uuid, Path, description = "The company."), FeedQuery),
    responses(
        (status = 200, description = "One page.", body = NotificationPage),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 422, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn org_notifications(
    State(state): State<AppState>,
    member: OrgMember,
    ApiQuery(q): ApiQuery<FeedQuery>,
) -> ApiResult<Json<NotificationPage>> {
    let page = Page::new(q.cursor.as_deref(), q.limit)?;
    let mut tx = member.begin(&state.db).await?;
    let feed = notify::page(&mut tx, member.user_id, Some(member.org_id), page).await?;
    tx.commit().await?;
    Ok(Json(feed))
}

#[utoipa::path(
    post,
    path = "/orgs/{org_id}/notifications/read",
    operation_id = "markNotificationsRead",
    tag = "notifications",
    params(("org_id" = uuid::Uuid, Path, description = "The company.")),
    responses(
        (status = 204, description = "Done."),
        (status = 401, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
        (status = 403, description = "Error, as RFC 9457 problem details.", body = crate::error::Problem,
            content_type = "application/problem+json"),
    ),
)]
async fn read_org_notifications(
    State(state): State<AppState>,
    member: OrgMember,
) -> ApiResult<StatusCode> {
    let mut tx = member.begin(&state.db).await?;
    notify::read_all(&mut tx, member.user_id, Some(member.org_id)).await?;
    tx.commit().await?;
    Ok(StatusCode::NO_CONTENT)
}
