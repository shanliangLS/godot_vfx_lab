"""Download the explicitly requested public free samples, then check native Godot content."""
import concurrent.futures
import hashlib
import html
import io
import json
import re
import time
import zipfile
from fetch_assets import ROOT, CACHE, client, request, safe_extract

SPECS = {
    "binbun_electric": ("https://binbun3d.itch.io/electric-fx", "Free", "CC0"),
    "binbun_loot": ("https://binbun3d.itch.io/loot-vfx", "Loot VFX", "CC0"),
    "binbun_status": ("https://binbun3d.itch.io/status-fx", "Free", "CC0"),
    "binbun_elemental": ("https://binbun3d.itch.io/elemental-magic-fx", "Free", "CC0"),
    "binbun_dark": ("https://binbun3d.itch.io/dark-magic-fx", "Free", "CC0"),
    "berry_hit_free": ("https://berryhibiscus.itch.io/hit-vfx-pack-30-stylized-impact-effects-for-godot-4", "FreeHitVfx.zip", "Personal/commercial use; no asset-pack redistribution, NFT use or generative-model training"),
    "soygus_tornado": ("https://soygus.itch.io/tornado-vfx-godot", "tornado vfx.zip", "Personal/commercial use and modification; no redistribution, resale or repackaging"),
    "starter_lite": ("https://alekseiramirov.itch.io/starter-vfx-pack-essential-juice-for-godot-lite-edition", "Starter Vfx Pack Lite", "CC0 / MIT (author page)"),
    "magic_circles_free": ("https://heyheythere.itch.io/magic-circles-3d-free", "magic-circles-3d-free-assets.zip", "CC BY 4.0"),
    "arcflux_lite": ("https://gennai.itch.io/arcflux-lite", "arcflux-lite-lite.zip", "Personal/commercial use; no redistribution of the pack"),
    "soygus_shield": ("https://soygus.itch.io/shield-force-vfx", "shield-vfx.zip", "Personal/commercial use and modification; no redistribution, resale or repackaging"),
}

def fetch(key, allow_assets=False):
    url, filename, license_name = SPECS[key]
    folder = ROOT / "vendor" / key
    if (folder / "PROVENANCE.json").exists():
        return {"id": key, "status": "cached"}
    opener = client()
    page = request(opener, url).decode()
    (CACHE / (key + "_source.html")).write_text(page, encoding="utf-8")
    token = re.search(r'name="csrf_token"\s+value="([^"]+)', page)
    data = {"csrf_token": html.unescape(token.group(1))} if token else {}
    if "generate_download_url" in page:
        download_url = json.loads(request(opener, url + "/download_url?fresh=" + str(time.time_ns()), data, url))["url"]
        download_page = request(opener, download_url, referer=url + "/purchase").decode()
    else:
        download_url, download_page = url, page
    uploads = re.findall(r'data-upload_id="(\d+)".*?<strong[^>]*title="([^"]+)"', download_page, re.S)
    if not uploads:
        # itch's own checkout frontend supports the central route when a subdomain
        # generated URL redirects to the product page instead of the free download list.
        game_id = re.search(r'content="games/(\d+)"', page)
        if game_id:
            central = request(opener, "https://itch.io").decode()
            central_token = re.search(r'name="csrf_token"\s+value="([^"]+)', central)
            if central_token:
                central_payload = {"csrf_token": html.unescape(central_token.group(1))}
                download_url = json.loads(request(opener, "https://itch.io/game/download_url/" + game_id.group(1), central_payload, url + "/purchase"))["url"]
                download_page = request(opener, download_url, referer=url + "/purchase").decode()
                uploads = re.findall(r'data-upload_id="(\d+)".*?<strong[^>]*title="([^"]+)"', download_page, re.S)
    selected = [item for item in uploads if html.unescape(item[1]) == filename]
    if len(selected) != 1:
        (CACHE / (key + "_download.html")).write_text(download_page, encoding="utf-8")
        raise ValueError("Expected public free file %r; available files: %r" % (filename, [html.unescape(item[1]) for item in uploads]))
    token2 = re.search(r'name="csrf_token"\s+value="([^"]+)', download_page)
    payload = {"csrf_token": html.unescape(token2.group(1))} if token2 else data
    link = json.loads(request(opener, url + "/file/" + selected[0][0], payload, download_url))["url"]
    blob = request(opener, link, referer=download_url)
    (CACHE / (key + ".zip")).write_bytes(blob)
    with zipfile.ZipFile(io.BytesIO(blob)) as archive:
        names = archive.namelist()
    native = [name for name in names if name.endswith((".gd", ".tscn", ".gdshader"))]
    assets = [name for name in names if name.lower().endswith((".png", ".fbx"))]
    if not native and not (allow_assets and assets):
        result = {"id": key, "status": "excluded", "reason": "Download contains no native Godot scripts, scenes or shaders", "files": names}
        (CACHE / (key + "_inspection.json")).write_text(json.dumps(result, indent=2), encoding="utf-8")
        return result
    digest = safe_extract(blob, folder)
    record = {"id": key, "url": url, "file": filename, "sha256": digest, "license": license_name, "fetched": "2026-10-14", "native_godot_files": len(native)}
    if allow_assets:
        record["importable_assets"] = len(assets)
    (folder / "PROVENANCE.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    (folder / "SOURCE-LICENSE.txt").write_text("Author page license: " + license_name + "\nSource: " + url + "\nRetrieved: 2026-10-14\n", encoding="utf-8")
    return {"id": key, "status": "downloaded", "bytes": len(blob), "native_files": native[:18]}

if __name__ == "__main__":
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        jobs = {pool.submit(fetch, key): key for key in SPECS}
        for job in concurrent.futures.as_completed(jobs):
            try:
                result = job.result()
            except Exception as error:
                result = {"id": jobs[job], "status": "failed", "reason": str(error)}
            results.append(result)
            print(json.dumps(result), flush=True)
    (CACHE / "requested_download_report.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
