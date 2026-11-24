/*
    A company's install stages (F19)
    --------------------------------------------------------------------
    - always `COUNT`, in order; a company can only rename them and set
      their templates, so a stored stage number never changes meaning
    - a stage without a row in `org_stages` has its `DEFAULT` name and an
      empty template
    - read inside the caller's company scope, like every company table
*/

use sqlx::PgConnection;

use crate::error::ApiResult;

pub const COUNT: i32 = 7;

// The standard names, until a company changes them.
pub const DEFAULT: [&str; COUNT as usize] = [
    "Site survey",
    "Structure",
    "Panel installation",
    "Wiring and inverter",
    "Earthing",
    "Net meter",
    "Handover",
];

// One stage: its name and what a new task at it asks for.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Template {
    pub name: String,
    pub checklist: Vec<String>,
    pub photos: Vec<String>,
}

// The company's stages, in order.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Stages(Vec<Template>);

impl Default for Stages {
    fn default() -> Self {
        Stages(
            DEFAULT
                .iter()
                .map(|name| Template {
                    name: (*name).to_owned(),
                    checklist: Vec::new(),
                    photos: Vec::new(),
                })
                .collect(),
        )
    }
}

impl Stages {
    // The name of a stage from 1, or None outside 1..=COUNT.
    pub fn name(&self, index: i32) -> Option<&str> {
        let i = usize::try_from(index).ok()?.checked_sub(1)?;
        self.0.get(i).map(|t| t.name.as_str())
    }

    // The name of a stage, with the index brought into 1..=COUNT.
    pub fn name_at(&self, index: i32) -> &str {
        self.name(index.clamp(1, COUNT)).unwrap_or_default()
    }

    // "Stage 2 · Structure", for an index from 1.
    pub fn line(&self, index: i32) -> Option<String> {
        Some(format!("Stage {index} · {}", self.name(index)?))
    }

    pub fn names(&self) -> Vec<String> {
        self.0.iter().map(|t| t.name.clone()).collect()
    }

    pub fn templates(&self) -> &[Template] {
        &self.0
    }
}

/*
    The stages of the company whose scope `conn` is in (`app_org_id()`).
    Outside a company scope there are none, so the defaults come back
*/
pub async fn load(conn: &mut PgConnection) -> ApiResult<Stages> {
    let rows: Vec<(i16, String, Vec<String>, Vec<String>)> = sqlx::query_as(
        "SELECT position, name, checklist, photos FROM org_stages
         WHERE org_id = app_org_id()",
    )
    .fetch_all(conn)
    .await?;
    let mut stages = Stages::default();
    for (position, name, checklist, photos) in rows {
        if let Some(slot) = usize::try_from(position - 1)
            .ok()
            .and_then(|i| stages.0.get_mut(i))
        {
            *slot = Template {
                name,
                checklist,
                photos,
            };
        }
    }
    Ok(stages)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_names_and_lines() {
        let s = Stages::default();
        assert_eq!(s.line(1).unwrap(), "Stage 1 · Site survey");
        assert_eq!(s.line(2).unwrap(), "Stage 2 · Structure");
        assert_eq!(s.line(7).unwrap(), "Stage 7 · Handover");
        assert!(s.line(0).is_none());
        assert!(s.line(8).is_none());
        assert_eq!(s.name_at(99), "Handover");
        assert_eq!(s.name_at(-3), "Site survey");
        assert_eq!(s.names().len(), COUNT as usize);
    }
}
