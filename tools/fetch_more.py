"""Public free Godot sources and engine-neutral PNG/FBX requested in the second batch."""
import concurrent.futures
import json
import fetch_requested

SPECS = {
    "fx_collection_free": ("https://heyheythere.itch.io/godot-fx-collection-free", "godot-fx-collection-free-assets.zip", "CC BY 4.0"),
    "rain_free": ("https://gennai.itch.io/free-rain-vfx-godot-4", "free-rain-vfx-godot-4-lite.zip", "Personal/commercial use; no redistribution of the pack"),
    "soygus_chest": ("https://soygus.itch.io/chest-looting-vfx", "chest-looting-vfx.zip", "Author's free release; consult upstream included license"),
    "storm_free": ("https://heyheythere.itch.io/storm-wind-3d-free", "storm-wind-3d-free-assets.zip", "CC BY 4.0"),
    "glyph_free": ("https://paradox-ai-creatives.itch.io/glyph-cities-free", "PARADOX_Novissime_GlyphCities_FreeSampler_v1.0.zip", "Personal/commercial use; no resale or redistribution of source assets"),
    "soygus_hologram": ("https://soygus.itch.io/hologram-vfx-godot", "hologram-vfx.zip", "Personal/commercial use and modification; no redistribution, resale or repackaging"),
    "christmas_assets": ("https://gameutb.itch.io/vfx-library-christmas", "VFX_library_Christmas_edition.zip", "Personal/commercial use; no inclusion in asset-type products (author's page comment)"),
    "brackeys_bundle": ("https://brackeysgames.itch.io/brackeys-vfx-bundle", "Brackeys VFX Bundle v1", "CC0"),
    "binbun_grass": ("https://binbun3d.itch.io/godot-grass", "Source Code", "CC0"),
    "soygus_card": ("https://soygus.itch.io/holographic-card-vfx-godot", "holographic-card-vfx.zip", "Personal/commercial use and modification; no redistribution, resale or repackaging"),
}

if __name__ == "__main__":
    fetch_requested.SPECS.update(SPECS)
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        jobs = {pool.submit(fetch_requested.fetch, key, key in ("christmas_assets", "brackeys_bundle")): key for key in SPECS}
        for job in concurrent.futures.as_completed(jobs):
            try:
                result = job.result()
            except Exception as error:
                result = {"id": jobs[job], "status": "failed", "reason": str(error)}
            results.append(result)
            print(json.dumps(result), flush=True)
    (fetch_requested.CACHE / "more_download_report.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
