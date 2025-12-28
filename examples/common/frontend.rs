//! Frontend URL resolution for examples.

use cef::CefString;
use std::path::PathBuf;

/// Resolves the frontend application to load.
///
/// Priority:
/// 1. CEF_DEV_URL (live dev server)
/// 2. CEF_APP_PATH (custom frontend directory)
/// 3. examples/<name>/index.html (cargo run)
/// 4. assets/index.html next to the executable (release)
pub fn resolve(default_example: &str) -> CefString {
    // Dev server override
    if let Ok(url) = std::env::var("CEF_DEV_URL") {
        return CefString::from(url.as_str());
    }

    // Custom frontend directory override
    let app_path = std::env::var("CEF_APP_PATH")
        .unwrap_or_else(|_| format!("examples/{default_example}"));

    // Cargo dev: use project root
    if let Ok(manifest_dir) = std::env::var("CARGO_MANIFEST_DIR") {
        let html = PathBuf::from(manifest_dir)
            .join(app_path)
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
