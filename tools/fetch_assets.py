"""Fetch only public free upstream files; retain provenance and licenses."""
import argparse
import concurrent.futures
import hashlib
import html
import http.cookiejar
import json
from pathlib import Path
import re
import time
import urllib.parse
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "downloads"
CACHE.mkdir(exist_ok=True)
PACKS = {
    "binbun_hit": ("https://binbun3d.itch.io/hit-fx", "Hit FX Free"),
    "binbun_battle": ("https://binbun3d.itch.io/battle-fx", "Free"),
    "binbun_beam": ("https://binbun3d.itch.io/beam-vfx", "Free"),
    "binbun_projectiles": ("https://binbun3d.itch.io/magic-projectiles-vfx", "MagicProjectilesVFX.zip"),
    "binbun_flame": ("https://binbun3d.itch.io/flame-fx", "Flame FX Free"),
    "inspired_projectiles": ("https://inspiredsloth.itch.io/projectile-effects", "Projectile Effects Vol. 1"),
    "reeboo_free": ("https://reebo0.itch.io/stylized-vfx-godot-free", "REEBOO_Stylized_VFX_Free_Sample_v1.2.zip"),
}


def client():
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def request(opener, url, data=None, referer=None):
    headers = {"User-Agent": "Mozilla/5.0 GodotAssetPreview/1.0"}
    if referer:
        headers["Referer"] = referer
    payload = urllib.parse.urlencode(data).encode() if data is not None else None
    if data is not None:
        headers["X-Requested-With"] = "XMLHttpRequest"
    for attempt in range(3):
        try:
            return opener.open(urllib.request.Request(url, data=payload, headers=headers), timeout=35).read()
        except Exception:
            if attempt == 2:
                raise
            time.sleep(1)


def inspect_page(url):
    opener = client()
    page = request(opener, url).decode()
    (CACHE / (url.rsplit("/", 1)[-1] + ".html")).write_text(page, encoding="utf-8")
    for tag in re.findall(r"<script.*?</script>", page, re.S):
        if "init" in tag or "game_id" in tag:
            print(tag[-5000:])
    print("UPLOADS", re.findall(r'.{0,150}upload_id.{0,250}', page))
    token = re.search(r'name="csrf_token"\s+value="([^"]+)', page)
    if not token:
        token = re.search(r'"csrf_token":"([^"]+)', page)
    data = {"csrf_token": html.unescape(token.group(1))} if token else {}
    result = request(opener, url + "/download_url", data, url).decode()
    print("DOWNLOAD RESPONSE", result[:1000])
    download_url = json.loads(result)["url"]
    download_page = request(opener, download_url).decode()
    (CACHE / "download_page.html").write_text(download_page, encoding="utf-8")
    print("DOWNLOAD LINKS", re.findall(r'.{0,200}(?:upload_id|file_link|data-upload_id).{0,350}', download_page))


def safe_extract(blob, folder, excluded_parts=()):
    folder.mkdir(parents=True, exist_ok=True)
    archive = CACHE / (folder.name + ".zip")
    archive.write_bytes(blob)
    with zipfile.ZipFile(archive) as z:
        for item in z.infolist():
            target = (folder / item.filename).resolve()
            if folder.resolve() not in target.parents and target != folder.resolve():
                raise ValueError("Unsafe archive path")
        for item in z.infolist():
            if not any(part in excluded_parts for part in Path(item.filename).parts):
                z.extract(item, folder)
    return hashlib.sha256(blob).hexdigest()


def fetch_itch(key):
    url, filename = PACKS[key]
    opener = client()
    page = request(opener, url).decode()
    token = re.search(r'name="csrf_token"\s+value="([^"]+)', page)
    data = {"csrf_token": html.unescape(token.group(1))} if token else {}
    if "generate_download_url" in page:
        download_url = json.loads(request(opener, url + "/download_url", data, url))["url"]
        download_page = request(opener, download_url).decode()
    else:
        download_url, download_page = url, page
    uploads = re.findall(r'data-upload_id="(\d+)".*?<strong[^>]*title="([^"]+)"', download_page, re.S)
    selected = [x for x in uploads if html.unescape(x[1]) == filename]
    if not selected:
        (CACHE / (key + "_failed.html")).write_text(download_page, encoding="utf-8")
        raise ValueError("Free file not found: " + repr(uploads))
    game_id = re.search(r'content="games/(\d+)"', page).group(1)
    token2 = re.search(r'name="csrf_token"\s+value="([^"]+)', download_page)
    payload = {"csrf_token": html.unescape(token2.group(1))} if token2 else data
    response = request(opener, url + "/file/" + selected[0][0], payload, download_url)
    link = json.loads(response)["url"]
    blob = request(opener, link, referer=download_url)
    digest = safe_extract(blob, ROOT / "vendor" / key)
    license_name = "custom; personal/commercial project use; no asset redistribution" if key == "reeboo_free" else "CC0"
    record = {"id": key, "url": url, "file": filename, "sha256": digest, "license": license_name, "fetched": "2026-10-14"}
    (ROOT / "vendor" / key / "PROVENANCE.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    (ROOT / "vendor" / key / "SOURCE-LICENSE.txt").write_text("Upstream license: " + license_name + "\nSource: " + url + "\n", encoding="utf-8")
    print("FETCHED", key, len(blob), flush=True)
    return record


def fetch_github(key, repository, branch="main"):
    if (ROOT / "vendor" / key / "PROVENANCE.json").exists():
        return
    blob = request(client(), "https://codeload.github.com/" + repository + "/zip/refs/heads/" + branch)
    folder = ROOT / "vendor" / key
    digest = safe_extract(blob, folder)
    inner = next(p for p in folder.iterdir() if p.is_dir())
    for child in list(inner.iterdir()):
        child.rename(folder / child.name)
    inner.rmdir()
    record = {"id": key, "url": "https://github.com/" + repository, "branch": branch, "sha256": digest, "fetched": "2026-10-14"}
    (folder / "PROVENANCE.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print("FETCHED", key, len(blob), flush=True)
    return record


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--inspect")
    parser.add_argument("--pack")
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()
    if args.inspect:
        inspect_page(args.inspect)
    if args.pack:
        fetch_itch(args.pack)
    if args.all:
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            futures = {pool.submit(fetch_itch, key): key for key in PACKS}
            futures[pool.submit(fetch_github, "gpu_trail", "celyk/GPUTrail")] = "gpu_trail"
            futures[pool.submit(fetch_github, "motion_trail", "metanoia83/Godot-4.0-Motion-Trail", "main")] = "motion_trail"
            for future in concurrent.futures.as_completed(futures):
                try:
                    future.result()
                except Exception as error:
                    print("FAILED", futures[future], str(error), flush=True)
