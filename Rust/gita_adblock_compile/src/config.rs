use std::fs;
use std::path::Path;

use anyhow::{Context, Result};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct ListsConfig {
    pub lists: Vec<ListSource>,
    pub resources: ResourceSource,
}

#[derive(Debug, Deserialize)]
pub struct ListSource {
    pub name: String,
    pub url: String,
}

#[derive(Debug, Deserialize)]
pub struct ResourceSource {
    pub name: String,
    pub url: String,
}

impl ListsConfig {
    pub fn load(path: &Path) -> Result<Self> {
        let text = fs::read_to_string(path)
            .with_context(|| format!("read {}", path.display()))?;
        toml::from_str(&text).context("parse lists.toml")
    }
}
