# Reviews presentation

T04 có reviewPreviewProvider(placeId) cho tối đa hai nhận xét trên chi tiết quán,
có loading/error/retry riêng. T09a AllReviewsScreen dùng reviewFeedControllerProvider
và capability ReviewFeedRepository cho summary/lọc/sort/phân trang độc lập.
RestaurantReviewCard chia sẻ adapter dữ liệu/route với preview. Xem docs/ALL_REVIEWS_UI.md.

Giai đoạn tiếp theo: danh sách review, form chấm sao/nội dung, chọn ảnh,
controller submit với loading/error/success và khóa gửi trùng.
T13 chỉ cho tạo review sau Auth; validate và giữ nội dung draft khi submit lỗi. Ảnh chọn từ thiết bị mới là preview vì upload backend chưa có contract.
