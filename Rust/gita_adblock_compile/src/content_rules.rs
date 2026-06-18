use std::fs;
use std::path::Path;

use adblock::content_blocking::{ignore_previous_fp_documents, CbRule};
use adblock::lists::FilterSet;
use anyhow::{Context, Result};
use serde_json;

pub fn build_content_rules(filter_set: &FilterSet) -> Result<Vec<CbRule>> {
    let (mut rules, discarded) = filter_set
        .clone()
        .into_content_blocking()
        .map_err(|_| anyhow::anyhow!("into_content_blocking failed"))?;
    if !discarded.is_empty() {
        eprintln!(
            "content blocking: {} rule(s) could not be converted",
            discarded.len()
        );
    }
    rules.retain(is_ascii_rule);
    Ok(rules)
}

fn is_ascii_rule(rule: &CbRule) -> bool {
    rule.trigger.url_filter.is_ascii()
        && rule
            .trigger
            .if_domain
            .iter()
            .flatten()
            .all(|d| d.is_ascii())
        && rule
            .trigger
            .unless_domain
            .iter()
            .flatten()
            .all(|d| d.is_ascii())
        && rule
            .trigger
            .if_top_url
            .iter()
            .flatten()
            .all(|d| d.is_ascii())
        && rule
            .trigger
            .unless_top_url
            .iter()
            .flatten()
            .all(|d| d.is_ascii())
        && rule
            .action
            .selector
            .as_ref()
            .is_none_or(|s| s.is_ascii())
}

pub fn chunk_content_rules(rules: &[CbRule], chunk_size: usize) -> Vec<Vec<CbRule>> {
    if rules.is_empty() {
        return vec![];
    }
    rules
        .chunks(chunk_size.max(1))
        .map(|chunk| chunk.to_vec())
        .collect()
}

pub fn write_content_rule_chunks(
    output_dir: &Path,
    rules: &[CbRule],
    chunk_size: usize,
) -> Result<usize> {
    let mut chunks = chunk_content_rules(rules, chunk_size);
    let chunk_count = chunks.len();

    for existing in fs::read_dir(output_dir)? {
        let entry = existing?;
        let name = entry.file_name();
        let name = name.to_string_lossy();
        if name.starts_with("content-rules-") && name.ends_with(".json") {
            fs::remove_file(entry.path())?;
        }
    }

    for (index, chunk) in chunks.iter_mut().enumerate() {
        chunk.push(ignore_previous_fp_documents());
        let path = output_dir.join(format!("content-rules-{index}.json"));
        let json = serde_json::to_string(chunk).context("serialize content rules")?;
        fs::write(path, json)?;
    }

    Ok(chunk_count)
}
