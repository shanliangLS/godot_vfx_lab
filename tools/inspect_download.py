from fetch_assets import CACHE, client, request
import re
s = (CACHE / "download_page.html").read_text(encoding="utf-8")
for url in re.findall(r'<script[^>]*src="([^"]+)', s):
    print("JS", url, flush=True)
    if "bundle.min" in url:
        source = request(client(), url).decode()
        (CACHE / "itch.js").write_text(source, encoding="utf-8")
        for match in re.findall(r'.{0,200}(?:upload_id|/file/|/download/).{0,250}', source):
            print(match, flush=True)
