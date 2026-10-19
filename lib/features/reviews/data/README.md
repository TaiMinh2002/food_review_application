# Reviews data

DemoReviewRepository cấp preview và capability đọc T09a (summary, filter, sort,
paging) bằng bốn nhận xét minh họa; vẫn từ chối create.
Khi nối backend, thay qua reviewRepositoryProvider, triển khai ReviewFeedRepository;
áp dụng scope/filter/order/count/limit tại query. Summary toàn bộ quán tính phía server,
không suy histogram từ average hoặc trang hiện tại. Xem docs/ALL_REVIEWS_UI.md.

Thêm FirestoreReviewRepository và mapper Timestamp khi triển khai backend.
Image upload service sử dụng HTTP client inject được, không gọi network từ widget.
Đọc docs/BACKEND_SETUP.md về ownership, ảnh mồ côi và server timestamp.
