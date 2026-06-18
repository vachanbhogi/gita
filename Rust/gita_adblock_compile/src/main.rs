mod config;
mod content_rules;
mod download;
mod manifest;

use std::fs;
use std::path::{Path, PathBuf};

use adblock::engine::Engine;
use adblock::lists::{FilterSet, ParseOptions};
use adblock::resources::Resource;
use anyhow::{Context, Result};
use clap::Parser;

use crate::config::ListsConfig;
use crate::content_rules::write_content_rule_chunks;
use crate::download::{download_or_load_cached, sha256_hex};
use crate::manifest::FiltersVersion;

const CHUNK_SIZE: usize = 40_000;
const ADBLOCK_VERSION: &str = "0.12.5";

#[derive(Parser, Debug)]
#[command(about = "Compile adblock filter lists into Gita WebKit artifacts")]
struct Args {
    /// Output directory for content-rules-*.json, engine.dat, filters-version.json
    #[arg(long, default_value = "gita/Resources/AdBlock")]
    output: PathBuf,

    /// Use cached lists in cache/ instead of downloading
    #[arg(long)]
    offline: bool,

    /// Path to lists.toml
    #[arg(long, default_value = "lists.toml")]
    lists: PathBuf,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let lists_path = resolve_lists_path(&args.lists)?;
    let config = ListsConfig::load(&lists_path)?;
    let cache_dir = lists_path
        .parent()
        .context("lists.toml has no parent directory")?
        .join("cache");

    fs::create_dir_all(&cache_dir)?;
    fs::create_dir_all(&args.output)?;

    let mut list_digests = Vec::new();
    let mut filter_set = FilterSet::new(true);

    for list in &config.lists {
        let body = download_or_load_cached(&cache_dir, &list.name, &list.url, args.offline)
            .with_context(|| format!("failed to load filter list {}", list.name))?;
        let digest = sha256_hex(body.as_bytes());
        list_digests.push((list.name.clone(), digest));
        filter_set.add_filter_list(&body, ParseOptions::default());
        eprintln!("loaded list {} ({} bytes)", list.name, body.len());
    }

    let resources_body = download_or_load_cached(
        &cache_dir,
        &config.resources.name,
        &config.resources.url,
        args.offline,
    )
    .context("failed to load resources")?;
    let resources_sha256 = sha256_hex(resources_body.as_bytes());
    let resources: Vec<Resource> =
        serde_json::from_str(&resources_body).context("failed to parse resources.json")?;
    eprintln!(
        "loaded {} resources ({} bytes)",
        resources.len(),
        resources_body.len()
    );

    let cb_rules = content_rules::build_content_rules(&filter_set)?;
    let chunk_count = write_content_rule_chunks(&args.output, &cb_rules, CHUNK_SIZE)?;
    eprintln!(
        "wrote {} content rule chunk(s) ({} total rules)",
        chunk_count,
        cb_rules.len()
    );

    let mut engine = Engine::from_filter_set(filter_set, true);
    engine.use_resources(resources);
    let engine_dat = engine.serialize();
    let engine_path = args.output.join("engine.dat");
    fs::write(&engine_path, &engine_dat)?;
    eprintln!("wrote engine.dat ({} bytes)", engine_dat.len());

    let manifest = FiltersVersion {
        adblock_version: ADBLOCK_VERSION.to_string(),
        generated_at: chrono_now_rfc3339(),
        lists: list_digests
            .into_iter()
            .map(|(name, sha256)| manifest::ListDigest { name, sha256 })
            .collect(),
        resources_sha256,
        chunk_count,
        rule_counts: manifest::RuleCounts {
            content_blocking: cb_rules.len(),
        },
    };
    let manifest_path = args.output.join("filters-version.json");
    fs::write(
        &manifest_path,
        serde_json::to_string_pretty(&manifest)?,
    )?;
    eprintln!("wrote filters-version.json");

    Ok(())
}

fn resolve_lists_path(lists: &Path) -> Result<PathBuf> {
    if lists.is_absolute() && lists.is_file() {
        return Ok(lists.to_path_buf());
    }
    if lists.is_file() {
        return Ok(std::env::current_dir()?.join(lists));
    }

    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let from_crate = manifest_dir.join(lists);
    if from_crate.is_file() {
        return Ok(from_crate);
    }

    anyhow::bail!("lists.toml not found at {}", lists.display());
}

fn chrono_now_rfc3339() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    format!("{secs}")
}
