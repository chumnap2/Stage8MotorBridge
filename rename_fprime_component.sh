#!/bin/bash
# rename_fprime_component.sh
# Safely rename Stage8MotorBridge → FPrimeMotorBridge

OLD_NAME="Stage8MotorBridge"
NEW_NAME="FPrimeMotorBridge"
COMP_DIR="$PWD/Components/$OLD_NAME"
NEW_DIR="$PWD/Components/$NEW_NAME"

echo "1️⃣ Backing up original component..."
cp -r "$COMP_DIR" "${COMP_DIR}_backup"
echo "Backup created at ${COMP_DIR}_backup"

echo "2️⃣ Renaming component folder..."
mv "$COMP_DIR" "$NEW_DIR"
echo "Renamed $COMP_DIR → $NEW_DIR"

echo "3️⃣ Updating CMakeLists.txt..."
CMAKE_FILE="$PWD/CMakeLists.txt"
if [ -f "$CMAKE_FILE" ]; then
    sed -i "s|$OLD_NAME|$NEW_NAME|g" "$CMAKE_FILE"
    echo "✅ Updated $CMAKE_FILE"
fi

echo "4️⃣ Updating .fpp and XML files inside component..."
find "$NEW_DIR" -type f \( -name "*.fpp" -o -name "*.xml" \) -exec sed -i "s|$OLD_NAME|$NEW_NAME|g" {} +
echo "✅ .fpp and XML files updated"

echo "5️⃣ Update any shell scripts referencing the old component path..."
for SCRIPT in create_motorbridge*.sh; do
    [ -f "$SCRIPT" ] && sed -i "s|$OLD_NAME|$NEW_NAME|g" "$SCRIPT" && echo "✅ Updated $SCRIPT"
done

echo "6️⃣ Done! Test build now:"
echo "   cd ~/fprime && rm -rf build && mkdir build && cd build && cmake .. && make"

echo "All done. Old component is safely backed up as ${COMP_DIR}_backup."
