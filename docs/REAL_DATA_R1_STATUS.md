# R1 — Gói quán OSM Hà Nội và bản đồ 5 km

Ngày kiểm tra: 22/10/2026. Nhánh `feat/map-ui` được rebase trên `origin/dev` sau khi R0 được merge.

## Nguồn và phạm vi

- Nguồn: [Geofabrik Vietnam OSM PBF](https://download.geofabrik.de/asia/vietnam.html), dữ liệu đến `2026-10-21T20:21:46Z`, bản tải 315 MiB. MD5 tải về khớp tệp `.md5` của Geofabrik. PBF chỉ lưu ngoài repo; asset phát hành là `assets/osm/hanoi_urban_places.json` (~501 KiB), có SHA-256 nguồn, ngày dữ liệu, URL, ODbL và attribution.
- Công cụ `tools/build_osm_region.py` dùng pyosmium 4.3.2 trên máy phát triển. Gói giữ node, way và multipolygon relation có tên và `amenity` thuộc restaurant/cafe/fast_food/food_court. Way/relation lấy điểm đại diện là tâm bbox của hình học; không phải lối vào hay khoảng cách đi bộ.
- Gói chứa 3.072 POI: 2.724 node, 346 way, 2 relation. Có 1.786 POI với ít nhất một trường địa chỉ. Không có rating, review, ảnh, giá hoặc menu do app tự tạo.
- Tâm GPS/tâm bản đồ được hỗ trợ trong bbox `20.88–21.12 N, 105.66–105.98 E`; gói có lề dữ liệu xung quanh để truy vấn đủ 5 km. Ngoài vùng này Map báo chưa hỗ trợ và có nút mở khu vực Chợ Phùng Khoang; không gọi public Overpass hoặc trả quán demo.

## Đối chiếu 5 km

| Tâm thử | POI trong 5 km | Địa chỉ có trường OSM |
| --- | ---: | ---: |
| Chợ Phùng Khoang `20.9859, 105.7938` | 556 | 304 |
| Cách tâm trên 0,018° vĩ độ `21.0039, 105.7938` | 936 | 544 |
| Cách tâm đông 0,020° kinh độ `20.9859, 105.8138` | 839 | 557 |

Tại Chợ Phùng Khoang có 245 restaurant, 245 cafe, 62 fast_food và 4 food_court. Ví dụ dữ liệu gần tâm: Youone Hotdog (~353 m), Supremacy (~391 m), Căng tin (~463 m). Đây là tên và tọa độ được trích từ OSM, **chưa phải xác minh thực địa**. Độ đầy đủ, quán đóng cửa hoặc tag sai vẫn cần kiểm tra thủ công trên thiết bị.

## Luồng đã nối

- Map dùng asset OSM theo mặc định. Repository dựng chỉ mục ô lưới một lần, lọc khoảng cách đường chim bay tối đa 5 km rồi áp dụng viewport và giới hạn 50 marker/lượt. Bộ đếm `+` cho biết còn kết quả; kéo/zoom và bấm “Tìm vùng này” để tìm tiếp.
- GPS bị từ chối có lựa chọn thủ công “Xem quán quanh Chợ Phùng Khoang”. Thẻ quán OSM hiển thị tên, loại, địa chỉ nếu có và chỉ đường ngoài; ẩn đánh giá, giá, lưu quán và chi tiết khi các luồng backend tương ứng chưa có. Bộ lọc đòi rating/giá/món bị ẩn trên Map thật.
- Test đã kiểm tra gói thực, đúng 556 ID trong 5 km, node/way/relation, lọc khoảng cách, tìm tên không dấu, asset load đồng thời, vùng chưa hỗ trợ, lỗi gói và giao diện không GPS.

## Còn thiếu trước khi R1 hoàn tất

- Home/Search/Category/Detail còn nguồn demo và thuộc các branch tính năng tương ứng; chưa đồng bộ context khám phá giữa Home/Map. Chưa import catalog Firestore nên chưa mở ghi review/favorite thật.
- Chưa nghiệm thu GPS, tải nền và mở chỉ đường trên Android/iOS thực tế; chưa xác minh ít nhất vài quán quen tại Chợ Phùng Khoang bằng quan sát thực địa. 50 marker gần nhất không phải toàn bộ 556 POI; cần phân trang/cluster nếu muốn hiện hết ở một lần tìm.
- Vùng ngoài bbox hỗ trợ cần gói bổ sung. Không dùng public Overpass làm backend production.

## Tái tạo gói

```sh
python3 -m venv /tmp/food-review-osm-venv
/tmp/food-review-osm-venv/bin/pip install -r tools/requirements-osm.txt
# Tải vietnam-latest.osm.pbf và .md5 từ Geofabrik; kiểm tra checksum trước khi chạy.
/tmp/food-review-osm-venv/bin/python tools/build_osm_region.py \
  /tmp/vietnam-latest.osm.pbf assets/osm/hanoi_urban_places.json \
  --checksum-file /tmp/vietnam-latest.osm.pbf.md5
```

Sau mỗi lần tái tạo, đo lại ba tâm, cập nhật số đếm và test gói. Giữ PBF gốc ngoài Git; chỉ commit gói Hà Nội đã lọc với thông tin nguồn và [giấy phép ODbL](https://opendatacommons.org/licenses/odbl/1-0/).
