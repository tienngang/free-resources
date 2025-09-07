#!/bin/bash
# Script mount lại ổ NTFS với quyền ghi bằng ntfs-3g
# Hiển thị danh sách có đánh số, chọn bằng số cho nhanh.
# Mặc định chọn 0 nếu Enter
# Cài đặt homebrew nếu chưa có:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Cài macFUSE:
# brew install --cask macfuse
# cần shutdown Mac, nhấn giữ nút nguồn chờ hiện ra Startup Option, login vào -> Utility -> Security -> Allow Extension...
# Cài ntfs-3g
# brew install ntfs-3g



while true; do
  clear
  echo "🔍 Đang tìm ổ NTFS..."
  NTFS_LIST=$(diskutil list | grep Windows_NTFS)

  if [ -z "$NTFS_LIST" ]; then
    echo "❌ Chưa tìm thấy ổ NTFS nào."
    echo "👉 Gắn USB/ổ cứng NTFS vào, hoặc nhập 'a' để thoát."
    read -t 5 -p "Lựa chọn (Enter để thử lại / a để abort): " CHOICE
    if [ "$CHOICE" = "a" ]; then
      echo "🛑 Thoát script."
      exit 0
    fi
    continue
  fi

  echo "Danh sách thiết bị NTFS:"
  IFS=$'\n' read -rd '' -a devices <<<"$NTFS_LIST"

  for i in "${!devices[@]}"; do
    echo "[$i] ${devices[$i]}"
  done

  echo
  read -p "👉 Nhập số thiết bị (Enter = 0 / a = abort): " CHOICE

  if [ "$CHOICE" = "a" ]; then
    echo "🛑 Thoát script."
    exit 0
  fi

  # Nếu không nhập gì thì chọn 0
  if [ -z "$CHOICE" ]; then
    CHOICE=0
  fi

  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -ge "${#devices[@]}" ]; then
    echo "❌ Lựa chọn không hợp lệ."
    sleep 2
    continue
  fi

  DEVLINE="${devices[$CHOICE]}"
  DEVNAME=$(echo "$DEVLINE" | awk '{print $NF}')
  DEVICE="/dev/$DEVNAME"

  # Lấy nhãn volume
  VOLNAME=$(diskutil info "$DEVICE" | grep "Volume Name" | awk -F: '{print $2}' | xargs)
  if [ -z "$VOLNAME" ]; then
    VOLNAME="NTFS_$DEVNAME"
  fi

  MOUNT_POINT="/Volumes/$VOLNAME"

  echo "➡️ Umount $DEVICE..."
  sudo umount "$DEVICE" 2>/dev/null
  diskutil unmount "$DEVICE" 2>/dev/null

  echo "➡️ Mount lại bằng ntfs-3g..."
  sudo mkdir -p "$MOUNT_POINT"
  sudo ntfs-3g "$DEVICE" "$MOUNT_POINT" \
    -olocal -oallow_other -o auto_xattr -o streams_interface=openxattr \
    -o volname="$VOLNAME" -o big_writes

  if [ $? -eq 0 ]; then
    echo "✅ Đã mount lại thành công: $MOUNT_POINT"
    exit 0
  else
    echo "❌ Mount thất bại. Thử lại..."
    sleep 2
  fi
done
