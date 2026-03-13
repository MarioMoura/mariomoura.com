---
title: "Scraping a full-resolution Project Zomboid map from a tile server"
date: 2026-03-13T10:00:00-03:00
tags:
  - python
  - project-zomboid
  - scraping
image: '/img/posts/pzcc-map-scraper.jpg'
comments: true
summary: "Scrapping b42map.com to make a high res image for my map editor."
params:
    dotfile: false
---

# Scraping a 20,000px map from a tile server

## Why

I was building [PZCC](https://pzcc.mariomoura.com), a visual tool for Project Zomboid server admins to select map regions to keep or purge. The tool needed a top-down map as a background for the canvas. This tool is by no means revolutionary, there were some for b41 and there's one for b42 [here](https://hdrcade-tylerfreeman.github.io/pz-b42-map-cleaner/).

The best top-down map I could find was [b42map.com](https://b42map.com). It renders beautifully in the browser because it uses a tiled image pyramid, only loading the tiles you can see at your current zoom. But there is no download button for the full image. So I wrote a scraper, thanks to them really and their amazing documentation.

## What we are working with

b42map.com uses **Deep Zoom Image (DZI)**, a format Microsoft created for Silverlight (No idea what that is, I'm probably too young). The idea is simple: take a massive image, slice it into a pyramid of tiles at multiple zoom levels, and serve them on demand.

The descriptor file `layer0.dzi` tells you everything:

```bash
curl https://b42map.com/map_data/base_top/layer0.dzi
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Image xmlns="http://schemas.microsoft.com/deepzoom/2008" TileSize="256" Overlap="0" Format="webp">
  <Size Width="19968" Height="16128"/>
</Image>
```

That is a 19,968 x 16,128 pixel image. About 322 million pixels. A single uncompressed RGBA version of it would be over 1.2GB. It is split into 256x256px tiles, organized in a pyramid where each level halves the resolution.

There is also a `map_info.json` with `cell_rects`:

```bash
curl https://b42map.com/map_data/base_top/map_info.json
```

These are rectangles describing which tiles actually contain map data. The PZ world is not a perfect rectangle, so many tiles at the edges are just black. This lets us skip them.

## The pyramid

DZI pyramids start at level 0 (a single 1x1 pixel) and go up to the max level (the full image). Each level doubles both dimensions:

```
Level 0:  1x1
Level 1:  2x2
...
Level 14: 9984x8064
Level 15: 19968x16128  <-- the one we want
```

At level 15, the image is split into a 78x63 grid of 256px tiles. That is 4,914 tiles total, but thanks to `cell_rects`, only 4,065 actually contain data.

Tile URLs follow a predictable pattern:

```
https://b42map.com/map_data/base_top/layer0_files/{level}/{col}_{row}.webp
```

## The scraper

The script is about 190 lines of Python. No exotic dependencies, just `Pillow` for image manipulation and `urllib` from the standard library.

The flow:

1. **Fetch metadata** -- download `layer0.dzi` and `map_info.json`
2. **Compute the pyramid** -- figure out dimensions at each level
3. **Filter tiles** -- use `cell_rects` to skip empty tiles
4. **Download in parallel** -- 20 threads, with caching so re-runs skip existing tiles
5. **Stitch** -- paste all tiles onto a single canvas and save as JPEG

The parallel download is the interesting part. Each tile is a small WebP image (typically 10-30KB), so the bottleneck is network latency, not bandwidth. Running 20 threads in parallel turns a 30-minute sequential crawl into a couple of minutes:

```python
with ThreadPoolExecutor(max_workers=20) as pool:
    futures = {
        pool.submit(fetch_tile, cx, cy, level, fmt, tile_dir): (cx, cy)
        for cx, cy in tiles_needed
    }
    for f in as_completed(futures):
        _, _, ok = f.result()
        if ok:
            downloaded += 1
        else:
            failed += 1
```

Tiles are cached to `/tmp/pz_tiles/level_{n}/` so you can re-run without re-downloading everything. This matters because stitching a 20K image takes a decent chunk of RAM and you do not want to wait for downloads again if the process crashes.

## Stitching

Once all tiles are on disk, stitching is straightforward. Create a black canvas at the full resolution, iterate over the tile files, parse the coordinates from the filename, and paste:

```python
out = Image.new("RGB", (cols * tile_size, rows * tile_size), (0, 0, 0))

for fname in os.listdir(tile_dir):
    parts = fname.replace(f".{fmt}", "").split("_")
    cx, cy = int(parts[0]), int(parts[1])
    tile = Image.open(os.path.join(tile_dir, fname))
    out.paste(tile, (cx * tile_size, cy * tile_size))

out.save(output_path, quality=95)
```

The final output: a single 95MB JPEG at 19,968 x 16,128 pixels. `Pillow` needs `MAX_IMAGE_PIXELS = None` to avoid its decompression bomb protection, which kicks in at ~179 million pixels. Ours is nearly double that.

## Three resolutions

One 95MB image is too heavy to load by default, so I created three versions for PZCC:

| Resolution | Dimensions | Size |
|-----------|-----------|------|
| Medium | 4,992 x 4,032 | 1.7MB |
| High | 9,984 x 8,064 | 8.1MB |
| Full | 19,968 x 16,128 | 95MB |

Medium and High are just ImageMagick downscales of the full version. PZCC defaults to Medium and lets you pick the others from a dropdown. The full version takes a moment to load, but once it does, you can zoom into individual buildings.

The scraper also supports fetching lower DZI levels directly with `--level`, which gives you the downscaled version without needing ImageMagick. But since I already had the full image, a quick `convert -resize 50%` was simpler.

## Running it

```bash
cd scraper/
pip install Pillow
python fetch_map.py -o ../src/map_full.jpg
```

That is it. The map *can* be seen on the live pzcc site now (although its very heavy).

In the end what I'm doing is unsophisticated but simpler, what b42map.com has is the exact solution for this kind of massive-image issue.
