use std::fs;
use std::path::Path;

use anyhow::{bail, Context, Result};
use sha2::{Digest, Sha256};

pub fn download_or_load_cached(
    cache_dir: &Path,
    name: &str,
    url: &str,
    offline: bool,
) -> Result<String> {
    let cache_path = cache_dir.join(format!("{name}.txt"));
    if offline {
        return fs::read_to_string(&cache_path)
            .with_context(|| format!("offline cache missing for {name} at {}", cache_path.display()));
    }

    if cache_path.is_file() {
        let cached = fs::read_to_string(&cache_path)?;
        if !cached.is_empty() {
            eprintln!("using cached {name}");
            return Ok(cached);
        }
    }

    eprintln!("downloading {name} from {url}");
    let response = reqwest::blocking::get(url)
        .with_context(|| format!("GET {url}"))?;
    if !response.status().is_success() {
        bail!("GET {url} failed with status {}", response.status());
    }
    let body = response.text().context("read response body")?;
    fs::write(&cache_path, &body)?;
    Ok(body)
}

pub fn sha256_hex(bytes: &[u8]) -> String {
    let digest = Sha256::digest(bytes);
    format!("{:x}", digest)
}
