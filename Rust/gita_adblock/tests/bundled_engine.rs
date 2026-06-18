use std::fs;
use std::path::PathBuf;

use adblock::engine::Engine;
use gita_adblock::{cosmetic_injections, load_engine};

fn engine_dat_path() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../gita/Resources/AdBlock/engine.dat")
}

#[test]
fn deserialize_bundled_engine_dat() {
    let path = engine_dat_path();
    assert!(
        path.is_file(),
        "missing bundled engine.dat at {}",
        path.display()
    );

    let bytes = fs::read(&path).expect("read engine.dat");
    let mut engine = Engine::default();
    engine
        .deserialize(&bytes)
        .expect("deserialize bundled engine.dat");
}

#[test]
fn spotify_cosmetics_from_bundled_engine() {
    let bytes = fs::read(engine_dat_path()).expect("read engine.dat");
    load_engine(bytes).expect("load engine via FFI");

    let injections = cosmetic_injections(
        "https://open.spotify.com/".to_string(),
        "open.spotify.com".to_string(),
        true,
    )
    .expect("cosmetic injections");

    assert!(
        !injections.hide_css.is_empty() || !injections.scriptlets_js.is_empty(),
        "expected Spotify cosmetic or scriptlet output from bundled engine"
    );
}
