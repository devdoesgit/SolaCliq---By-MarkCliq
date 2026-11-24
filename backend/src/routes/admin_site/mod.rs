/*
    What the admin website reads (docs/features/admin-website.md, W2-W4)
    --------------------------------------------------------------------
    - `/orgs/{org_id}/admin/...`, the company's admin only
      (`OrgMember<Admins>`). Kept apart from the app's endpoints, whose
      roles and shapes don't change
    - each query names the company, and runs in its row-level security
      scope as well: another company's record is 404
    - the decisions are `routes/admin.rs`. Here: the reads, and the three
      writes only the website has (stage, price, settings)
    - files are 15-minute links. Of a payout account, only the last 4
      digits ever leave the server (owner, 2026-11-22)
*/

mod customers;
mod money;
mod overview;
mod settings;
mod tasks;

use serde::Serialize;
use utoipa::ToSchema;
use utoipa_axum::router::OpenApiRouter;
use uuid::Uuid;

use crate::{
    AppState,
    error::ApiResult,
    routes::uploads,
    stages::{self, Stages},
    storage::Storage,
};

pub fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .merge(customers::router())
        .merge(tasks::router())
        .merge(money::router())
        .merge(overview::router())
        .merge(settings::router())
}

const ERRORS: &str = "Error, as RFC 9457 problem details.";

// The contract's `AdminFile`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminFile {
    pub url: String,
    // As the sender declared it.
    pub content_type: String,
    pub size_bytes: i64,
}

impl AdminFile {
    fn sign(
        storage: Option<&Storage>,
        org_id: Uuid,
        key: &str,
        content_type: String,
        size_bytes: i64,
    ) -> ApiResult<Self> {
        Ok(AdminFile {
            url: uploads::read_url(storage, org_id, key)?,
            content_type,
            size_bytes,
        })
    }
}

// The contract's `AdminStage`.
#[derive(Debug, Serialize, ToSchema)]
pub struct AdminStage {
    pub index: i32,
    pub count: i32,
    pub name: String,
}

impl AdminStage {
    fn at(index: i32, stages: &Stages) -> Self {
        let index = index.clamp(1, stages::COUNT);
        AdminStage {
            index,
            count: stages::COUNT,
            name: stages.name_at(index).to_owned(),
        }
    }
}
