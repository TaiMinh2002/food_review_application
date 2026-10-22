"""Build a bounded, attribution-ready OSM food-place package from a PBF.

Install pyosmium in a local virtual environment. This tool runs on a developer
machine; it is never included in the mobile app or called by app users.
"""

import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path

import osmium


SOURCE_URL = "https://download.geofabrik.de/asia/vietnam-latest.osm.pbf"
AMENITIES = {"restaurant", "cafe", "fast_food", "food_court"}
TAG_KEYS = {
    "amenity", "name", "name:vi", "description", "addr:full",
    "addr:housenumber", "addr:street", "addr:suburb", "addr:city",
    "disused:amenity", "abandoned:amenity", "disused", "abandoned",
}
EXTRACT_BOUNDS = {"south": 20.82, "west": 105.60, "north": 21.18, "east": 106.04}
SUPPORTED_BOUNDS = {"south": 20.88, "west": 105.66, "north": 21.12, "east": 105.98}


def inside(lat, lon, bounds):
    return bounds["south"] <= lat <= bounds["north"] and bounds["west"] <= lon <= bounds["east"]


def center(points):
    valid = [(lat, lon) for lat, lon in points if -90 <= lat <= 90 and -180 <= lon <= 180]
    if not valid:
        return None
    return ((min(p[0] for p in valid) + max(p[0] for p in valid)) / 2,
            (min(p[1] for p in valid) + max(p[1] for p in valid)) / 2)


class FoodPlaceCollector(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.elements = {}
        self.skipped_geometry = 0

    def _add(self, element_type, osm_id, tags, point):
        if point is None or osm_id <= 0:
            self.skipped_geometry += 1
            return
        lat, lon = point
        if not inside(lat, lon, EXTRACT_BOUNDS):
            return
        selected = {key: tags.get(key) for key in sorted(TAG_KEYS) if tags.get(key)}
        if selected.get("amenity") not in AMENITIES:
            return
        if selected.get("disused") == "yes" or selected.get("abandoned") == "yes":
            return
        if selected.get("disused:amenity") or selected.get("abandoned:amenity"):
            return
        if not (selected.get("name:vi") or selected.get("name")):
            return
        self.elements[(element_type, osm_id)] = {
            "type": element_type, "id": osm_id, "lat": round(lat, 7),
            "lon": round(lon, 7), "tags": selected,
        }

    def node(self, node):
        if node.tags.get("amenity") not in AMENITIES:
            return
        if node.location.valid():
            self._add("node", node.id, node.tags, (node.location.lat, node.location.lon))

    def way(self, way):
        if way.tags.get("amenity") not in AMENITIES:
            return
        point = center((node.lat, node.lon) for node in way.nodes if node.location.valid())
        self._add("way", way.id, way.tags, point)

    def area(self, area):
        if area.tags.get("amenity") not in AMENITIES:
            return
        points = ((node.lat, node.lon) for ring in area.outer_rings()
                  for node in ring if node.location.valid())
        point = center(points)
        self._add("way" if area.from_way() else "relation", area.orig_id(), area.tags, point)


def source_checksums(path):
    md5 = hashlib.md5()
    sha256 = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            md5.update(chunk)
            sha256.update(chunk)
    return md5.hexdigest(), sha256.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="OSM .pbf or .osm extract")
    parser.add_argument("output", type=Path, help="JSON package inside assets/osm")
    parser.add_argument("--source-url", default=SOURCE_URL)
    parser.add_argument("--source-timestamp",
                        help="Only for test extracts without a PBF timestamp")
    parser.add_argument("--checksum-file", type=Path,
                        help="Geofabrik .md5 file used to verify the PBF")
    args = parser.parse_args()

    if not args.input.is_file():
        parser.error("input extract does not exist")
    reader = osmium.io.Reader(str(args.input))
    source_timestamp = args.source_timestamp or reader.header().get("osmosis_replication_timestamp")
    reader.close()
    try:
        datetime.strptime(source_timestamp, "%Y-%m-%dT%H:%M:%SZ")
    except (TypeError, ValueError):
        parser.error("a UTC source timestamp is required")
    md5, checksum = source_checksums(args.input)
    if args.checksum_file:
        expected_md5 = args.checksum_file.read_text(encoding="ascii").split()[0].lower()
        if md5 != expected_md5:
            parser.error("source MD5 does not match the checksum file")
    collector = FoodPlaceCollector()
    collector.apply_file(str(args.input), locations=True)
    elements = [collector.elements[key] for key in sorted(collector.elements)]
    if not elements:
        parser.error("no named food places found in the extract bounds")
    payload = {
        "schemaVersion": 1,
        "regionId": "hanoi-urban",
        "sourceUrl": args.source_url,
        "sourceTimestamp": source_timestamp,
        "sourceSha256": checksum,
        "license": "ODbL-1.0",
        "attribution": "© OpenStreetMap contributors",
        "supportedBounds": SUPPORTED_BOUNDS,
        "extractBounds": EXTRACT_BOUNDS,
        "elements": elements,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
                           encoding="utf-8")
    print(f"{len(elements)} places, {args.output.stat().st_size} bytes, "
          f"{collector.skipped_geometry} skipped geometries")


if __name__ == "__main__":
    main()
