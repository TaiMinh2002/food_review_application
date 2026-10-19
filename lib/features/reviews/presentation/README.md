# Reviews presentation

T04 đã có reviewPreviewProvider(placeId) cho tối đa hai nhận xét trên chi tiết quán,
có loading/error/retry riêng; đây chưa phải màn All Reviews.

Giai đoạn tiếp theo: danh sách review, form chấm sao/nội dung, chọn ảnh,
controller submit với loading/error/success và khóa gửi trùng.
Chỉ cho tạo review sau Auth; validate và giữ draft khi upload lỗi.
