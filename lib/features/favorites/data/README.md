# Favorites Data Layer

- `FirestoreFavoriteRepository`: Lưu và đồng bộ danh sách địa điểm yêu thích trên Cloud Firestore theo đường dẫn `users/{uid}/favorites/{placeKey}` (0-cost Spark).
- `MemoryFavoriteRepository`: Lưu trữ trong bộ nhớ đệm (RAM) phục vụ kiểm thử đơn vị và môi trường khi Firebase chưa khởi tạo.
