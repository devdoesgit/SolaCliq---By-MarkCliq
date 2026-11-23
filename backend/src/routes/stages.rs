/*
    Each company's install stages (F19)
    --------------------------------------------------------------------
    - every member reads them: the app and the website name stages with
      them, and a new task fills from its stage's template
    - the company's admin changes one stage at a time: its name, its
      checklist and the photos it asks for. Always 7 (`crate::stages`)
    - tasks keep what they were made with; a template change is for the
      next task
*/

use axum::{Json, extract::State};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use utoipa_axum::{router::OpenApiRouter, routes};

use crate::{
    AppState,
    error::{ApiError, ApiResult},
    extract::{ApiJson, ApiPath},
    org::{Admins, OrgMember},
    stages::{self, Stages},
};

const ERRORS: &str = "Error, as RFC 9457 problem details.";

const NAME_MAX: usize = 40;
const CHECKLIST_MAX: usize = 20;
const CHECK_MAX: usize = 120;
const PHOTOS_MAX: usize = 8;
const PHOTO_MAX: usize = 60;

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(list_stages))
        .routes(routes!(set_stage))
}

// The contract's `Stage`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Stage {
    pub index: i32,
    pub name: String,
    pub checklist: Vec<String>,
    pub photos: Vec<String>,
}

// The contract's `StageList`.
#[derive(Debug, Serialize, ToSchema)]
pub struct StageList {
    pub stages: Vec<Stage>,
}

impl From<Stages> for StageList {
    fn from(stages: Stages) -> Self {
        StageList {
            stages: stages
                .templates()
                .iter()
                .zip(1..)
                .map(|(t, index)| Stage {
                    index,
                    name: t.name.clone(),
                    checklist: t.checklist.clone(),
                    photos: t.photos.clone(),
                })
                .collect(),
        }
    }
}

// The contract's `StageTemplateSet`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct StageTemplateSet {
    pub name: String,
    pub checklist: Vec<String>,
    pub photos: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct StagePath {
    index: i32,
}

#[utoipa::path(
    get,
    path = "/orgs/{org_id}/stages",
    operation_id = "listStages",
    tag = "stages",
    params(("org_id" = Uuid, Path, description = "The company.")),
    responses(
        (status = 200, description = "The 7 stages, in order.", body = StageList),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn list_stages(
    State(state): State<AppState>,
    member: OrgMember,
) -> ApiResult<Json<StageList>> {
    let mut tx = member.begin(&state.db).await?;
    let stages = stages::load(&mut tx).await?;
    tx.commit().await?;
    Ok(Json(stages.into()))
}

/*
    Trimmed, blanks dropped, each kept once in its first place. Too
    many, or one too long, is a 422 on that field
*/
fn clean(field: &str, items: &[String], most: usize, longest: usize) -> ApiResult<Vec<String>> {
    let mut out: Vec<String> = Vec::new();
    for item in items.iter().map(|i| i.trim()).filter(|i| !i.is_empty()) {
        if item.chars().count() > longest {
            return Err(ApiError::validation(Vec::new())
                .field(field, format!("Each one is up to {longest} characters.")));
        }
        if !out.iter().any(|o| o == item) {
            out.push(item.to_owned());
        }
    }
    if out.len() > most {
        return Err(ApiError::validation(Vec::new()).field(field, format!("Up to {most}.")));
    }
    Ok(out)
}

#[utoipa::path(
    put,
    path = "/orgs/{org_id}/admin/stages/{index}",
    operation_id = "adminSetStage",
    tag = "stages",
    params(
        ("org_id" = Uuid, Path, description = "The company."),
        ("index" = i32, Path, description = "The stage, from 1 to 7.", minimum = 1, maximum = 7),
    ),
    request_body = StageTemplateSet,
    responses(
        (status = 200, description = "All 7 stages, after the change.", body = StageList),
        (status = 401, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 403, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 404, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
        (status = 422, description = ERRORS, body = crate::error::Problem, content_type = "application/problem+json"),
    ),
)]
async fn set_stage(
    State(state): State<AppState>,
    admin: OrgMember<Admins>,
    ApiPath(path): ApiPath<StagePath>,
    ApiJson(req): ApiJson<StageTemplateSet>,
) -> ApiResult<Json<StageList>> {
    if !(1..=stages::COUNT).contains(&path.index) {
        return Err(ApiError::not_found());
    }
    let name = req.name.trim();
    if name.is_empty() || name.chars().count() > NAME_MAX {
        return Err(
            ApiError::validation(Vec::new()).field("name", format!("1 to {NAME_MAX} characters."))
        );
    }
    let checklist = clean("checklist", &req.checklist, CHECKLIST_MAX, CHECK_MAX)?;
    let photos = clean("photos", &req.photos, PHOTOS_MAX, PHOTO_MAX)?;

    let mut tx = admin.begin(&state.db).await?;
    sqlx::query(
        "INSERT INTO org_stages (org_id, position, name, checklist, photos, updated_by)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (org_id, position) DO UPDATE
         SET name = $3, checklist = $4, photos = $5, updated_by = $6, updated_at = now()",
    )
    .bind(admin.org_id)
    .bind(path.index as i16)
    .bind(name)
    .bind(&checklist)
    .bind(&photos)
    .bind(admin.user_id)
    .execute(&mut *tx)
    .await?;
    let stages = stages::load(&mut tx).await?;
    tx.commit().await?;
    tracing::info!(org_id = %admin.org_id, by = %admin.user_id, index = path.index, "stage template changed");
    Ok(Json(stages.into()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn s(items: &[&str]) -> Vec<String> {
        items.iter().map(|i| (*i).to_owned()).collect()
    }

    #[test]
    fn blanks_go_and_repeats_are_kept_once() {
        let out = clean(
            "checklist",
            &s(&[" Fix rails ", "", "  ", "Fix rails", "Torque"]),
            20,
            120,
        )
        .unwrap();
        assert_eq!(out, s(&["Fix rails", "Torque"]));
    }

    #[test]
    fn too_many_or_too_long_is_refused() {
        assert!(clean("photos", &s(&["a", "b", "c"]), 2, 60).is_err());
        assert!(clean("photos", &s(&[&"x".repeat(61)]), 8, 60).is_err());
        // Repeats don't count towards the most.
        assert!(clean("photos", &s(&["a", "a", "a"]), 1, 60).is_ok());
    }
}
