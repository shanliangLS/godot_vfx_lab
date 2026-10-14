"""Fetch selected official demos and public shader examples."""
from fetch_assets import ROOT, client, request, safe_extract
import concurrent.futures
import hashlib
import html
import json
from pathlib import Path
import re


def official_particles():
    repository = "godotengine/godot-demo-projects"
    branch = "4.7"
    opener = client()
    try:
        tree = json.loads(request(opener, "https://api.github.com/repos/" + repository + "/git/trees/" + branch + "?recursive=1"))
    except Exception:
        branch = "master"
        tree = json.loads(request(opener, "https://api.github.com/repos/" + repository + "/git/trees/" + branch + "?recursive=1"))
    files = [x["path"] for x in tree["tree"] if x["type"] == "blob" and (x["path"].startswith("3d/particles/") or x["path"] == "LICENSE.md")]
    folder = ROOT / "vendor" / "official_particles"
    def download(path):
        relative = path[len("3d/particles/"):] if path.startswith("3d/particles/") else path
        target = folder / relative
        if target.exists(): return
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(request(client(), "https://raw.githubusercontent.com/" + repository + "/" + branch + "/" + path))
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        pending = [pool.submit(download, path) for path in files]
        errors = []
        for future in concurrent.futures.as_completed(pending):
            try: future.result()
            except Exception as error: errors.append(str(error))
    (folder / "PROVENANCE.json").write_text(json.dumps({"url":"https://github.com/" + repository, "branch":branch, "commit":tree["sha"], "license":"MIT", "files":files}, indent=2), encoding="utf-8")
    if errors: raise RuntimeError("; ".join(errors))
    print("FETCHED official_particles", len(files), flush=True)


def simple_laser():
    url = "https://godotshaders.com/shader/simple-laser-shader-sls/"
    page = request(client(), url).decode()
    blocks = re.findall(r'<pre[^>]*>(.*?)</pre>', page, re.S)
    code = next(html.unescape(re.sub(r"<[^>]+>", "", text)) for text in blocks if "shader_type" in text)
    folder = ROOT / "vendor" / "simple_laser"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "laser.gdshader").write_text(code, encoding="utf-8")
    (folder / "SOURCE-LICENSE.txt").write_text("Shader code CC0; page media is excluded.\n" + url, encoding="utf-8")
    (folder / "PROVENANCE.json").write_text(json.dumps({"url":url, "license":"CC0", "sha256":hashlib.sha256(code.encode()).hexdigest()}, indent=2), encoding="utf-8")
    print("FETCHED simple_laser", len(code), flush=True)


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(official_particles), pool.submit(simple_laser)]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as error:
                print("FAILED extras:", error, flush=True)
