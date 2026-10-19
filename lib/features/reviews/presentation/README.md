# Reviews presentation

T04 có reviewPreviewProvider(placeId) cho tối đa hai nhận xét trên chi tiết quán,
có loading/error/retry riêng. T09a AllReviewsScreen dùng reviewFeedControllerProvider
và capability ReviewFeedRepository cho summary/lọc/sort/phân trang độc lập.
RestaurantReviewCard chia sẻ adapter dữ liệu/route với preview. Xem docs/ALL_REVIEWS_UI.md.

T09a có danh sách review theo quán; T13 có form chấm sao/nội dung, chọn ảnh,
controller submit với loading/error/success và khóa gửi trùng. T14 có My Reviews,
edit/delete theo owner và dialog xác nhận. Review chỉ cho thao tác cá nhân sau Auth;
demo repository lưu trong RAM. Ảnh chọn từ thiết bị mới là preview vì upload backend chưa có contract.
