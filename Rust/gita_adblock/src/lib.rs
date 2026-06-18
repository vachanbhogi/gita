use adblock::cosmetic_filter_cache::UrlSpecificResources;
use adblock::engine::Engine;
use adblock::request::{Request, RequestError};
use once_cell::sync::OnceCell;
use std::sync::Mutex;
use thiserror::Error;

static ENGINE: OnceCell<Mutex<Engine>> = OnceCell::new();

#[derive(Debug, Error, uniffi::Error)]
pub enum AdblockError {
    #[error("engine not loaded")]
    NotLoaded,
    #[error("failed to deserialize engine")]
    DeserializeFailed,
    #[error("engine lock poisoned")]
    LockPoisoned,
    #[error("invalid request")]
    InvalidRequest,
}

#[derive(Debug, uniffi::Record)]
pub struct CosmeticInjections {
    pub hide_css: String,
    pub scriptlets_js: String,
}

fn engine_guard() -> Result<std::sync::MutexGuard<'static, Engine>, AdblockError> {
    let cell = ENGINE.get().ok_or(AdblockError::NotLoaded)?;
    cell.lock().map_err(|_| AdblockError::LockPoisoned)
}

#[uniffi::export]
pub fn load_engine(bytes: Vec<u8>) -> Result<(), AdblockError> {
    let mut engine = Engine::default();
    engine
        .deserialize(&bytes)
        .map_err(|_| AdblockError::DeserializeFailed)?;
    ENGINE
        .set(Mutex::new(engine))
        .map_err(|_| AdblockError::DeserializeFailed)?;
    Ok(())
}

#[uniffi::export]
pub fn cosmetic_injections(
    url: String,
    _tab_host: String,
    is_main_frame: bool,
) -> Result<CosmeticInjections, AdblockError> {
    if !is_main_frame {
        return Ok(CosmeticInjections {
            hide_css: String::new(),
            scriptlets_js: String::new(),
        });
    }

    let engine = engine_guard()?;
    let resources = engine.url_cosmetic_resources(&url);
    Ok(CosmeticInjections {
        hide_css: format_hide_css(&resources),
        scriptlets_js: resources.injected_script.clone(),
    })
}

#[uniffi::export]
pub fn check_network_url(
    url: String,
    source_url: String,
    resource_type: String,
) -> Result<bool, AdblockError> {
    let request = Request::new(&url, &source_url, &resource_type)
        .map_err(|_: RequestError| AdblockError::InvalidRequest)?;
    let engine = engine_guard()?;
    Ok(engine.check_network_request(&request).matched)
}

fn format_hide_css(resources: &UrlSpecificResources) -> String {
    if resources.hide_selectors.is_empty() {
        return String::new();
    }

    let joined = resources.hide_selectors.iter().cloned().collect::<Vec<_>>().join(", ");
    format!("{joined} {{ display: none !important; }}")
}

uniffi::setup_scaffolding!();

#[cfg(test)]
mod tests {
    use super::*;
    use adblock::engine::Engine;
    use adblock::lists::{FilterSet, ParseOptions};

    #[test]
    fn round_trip_engine_and_spotify_cosmetics() {
        let mut filter_set = FilterSet::new(true);
        filter_set
            .add_filter("open.spotify.com##.ad-banner", ParseOptions::default())
            .expect("add filter");
        let engine = Engine::from_filter_set(filter_set, true);
        let bytes = engine.serialize();
        load_engine(bytes).expect("load serialized engine");

        let injections = cosmetic_injections(
            "https://open.spotify.com/".to_string(),
            "open.spotify.com".to_string(),
            true,
        )
        .expect("cosmetic injections");
        assert!(
            !injections.hide_css.is_empty() || !injections.scriptlets_js.is_empty(),
            "expected cosmetic output for spotify URL"
        );
    }
}
