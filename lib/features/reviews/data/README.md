# Reviews data

T04 đã có DemoReviewRepository chỉ cấp preview minh họa và từ chối create.
Khi nối backend, thay qua reviewRepositoryProvider; áp dụng limit tại query.

Thêm FirestoreReviewRepository và mapper Timestamp khi triển khai backend.
Image upload service sử dụng HTTP client inject được, không gọi network từ widget.
Đọc docs/BACKEND_SETUP.md về ownership, ảnh mồ côi và server timestamp.
