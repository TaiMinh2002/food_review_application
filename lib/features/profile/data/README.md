# Profile data

T18: FirebaseProfileRepository cập nhật tên/ảnh qua Firebase Auth; DeviceProfilePhotoRepository
chọn ảnh/upload Cloudinary. Firestore mapper/repository cho username/bio/khu vực còn thiếu.
Public profile chỉ có displayName/photoUrl; email lấy từ phiên Auth cho chính chủ.
Không thêm repository rỗng trước khi có thao tác dữ liệu cần dùng.
