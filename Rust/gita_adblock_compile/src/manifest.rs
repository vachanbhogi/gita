use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct FiltersVersion {
    pub adblock_version: String,
    pub generated_at: String,
    pub lists: Vec<ListDigest>,
    pub resources_sha256: String,
    pub chunk_count: usize,
    pub rule_counts: RuleCounts,
}

#[derive(Debug, Serialize)]
pub struct ListDigest {
    pub name: String,
    pub sha256: String,
}

#[derive(Debug, Serialize)]
pub struct RuleCounts {
    pub content_blocking: usize,
}
