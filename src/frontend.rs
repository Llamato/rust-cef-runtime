//! Frontend URL resolution.

use cef::CefString;
use std::path::PathBuf;

/// Resolves the frontend URL to load.
///
/// Priority:
/// 1. CEF_DEV_URL environment variable (dev server)
/// 2. assets/index.html from project root (cargo run / examples)
/// 3. assets/index.html next to the executable (release)
pub fn resolve() -> CefString {
    // Dev server override
    if let Ok(url) = std::env::var("CEF_DEV_URL") {
        return CefString::from(url.as_str());
    }

    // Cargo dev: use project root
    if let Ok(manifest_dir) = std::env::var("CARGO_MANIFEST_DIR") {
        let html = PathBuf::from(manifest_dir)
            .join("assets")
            .join("index.html");

        if html.exists() {
            return CefString::from(
                format!("file://{}", html.display()).as_str()
            );
        }
    }

    // Release: assets next to executable
    let exe = std::env::current_exe().unwrap();
    let dir = exe.parent().unwrap();
    let html = dir.join("assets").join("index.html");

    CefString::from(format!("file://{}", html.display()).as_str())
}
