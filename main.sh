#!/bin/sh

# =============================
#   CONFIG
# =============================

DATA_DIR="/data/local/tmp"
SCRIPT_DIR="$(pwd)"
FILES_DIR="$SCRIPT_DIR/files"
SAVED_DIR="$SCRIPT_DIR/saved"
BACKUP_DIR="$SCRIPT_DIR/saved-backup"
FIRST_SETUP_FLAG="$SCRIPT_DIR/.first_setup_done"

# URLs
CROSVM_URL="https://github.com/polygraphene/gunyah-on-sd-guide/releases/download/v0.0.2/crosvm-a16"
KERNEL_URL="https://github.com/polygraphene/gunyah-on-sd-guide/releases/download/v0.0.2/kernel"
LIBB_URL="https://github.com/polygraphene/gunyah-on-sd-guide/releases/download/v0.0.2/libbinder.so"
LIBB_NDK_URL="https://github.com/polygraphene/gunyah-on-sd-guide/releases/download/v0.0.2/libbinder_ndk.so"

ROOTFS_URL="https://dl.google.com/android/ferrochrome/3500000/aarch64/images.tar.gz"

RUN_SCRIPT_URL="https://raw.githubusercontent.com/Imacolombian346/gunyah-script/refs/heads/main/run-crosvm-net.sh"

EXPECTED_FILES="
crosvm-a16
images.tar.gz
kernel
libbinder.so
libbinder_ndk.so
root_part
run-crosvm-net.sh
"

# =============================
#  FUNCTIONS
# =============================

ensure_directories() {
    mkdir -p "$FILES_DIR" "$SAVED_DIR" "$BACKUP_DIR"
}

files_missing_in_tmp() {
    for f in $EXPECTED_FILES; do
        if [ ! -f "$DATA_DIR/$f" ]; then
            return 0
        fi
    done
    return 1
}

download_files_from_internet() {
    echo "Downloading required VM files..."

    curl -L -o "$FILES_DIR/crosvm-a16" "$CROSVM_URL"
    curl -L -o "$FILES_DIR/kernel" "$KERNEL_URL"
    curl -L -o "$FILES_DIR/libbinder.so" "$LIBB_URL"
    curl -L -o "$FILES_DIR/libbinder_ndk.so" "$LIBB_NDK_URL"
    curl -L -o "$FILES_DIR/images.tar.gz" "$ROOTFS_URL"
    curl -L -o "$FILES_DIR/run-crosvm-net.sh" "$RUN_SCRIPT_URL"

    echo "Extracting root_part..."
    tar -xf "$FILES_DIR/images.tar.gz" root_part -C "$FILES_DIR"

    chmod 777 "$FILES_DIR"/*

    echo ""
    echo "Download complete!"
    echo "Do you want to copy the downloaded files to /data/local/tmp and run the VM now? (y/n)"
    read r
    if [ "$r" = "y" ]; then
        copy_default_files
        ask_run
    fi
}

network_warning() {
    clear
    echo "=========================="
    echo "   IMPORTANT NETWORK NOTE"
    echo "=========================="
    echo ""
    echo "To enable internet inside the VM, follow ONLY the **second part**"
    echo "of this guide (INSIDE THE VM):"
    echo ""
    echo "  https://github.com/polygraphene/gunyah-on-sd-guide/blob/main/NETWORK.md"
    echo ""
    echo "⚠ DO NOT run the first part of the guide (the launch script)."
    echo "   → The VM already uses the modified run-crosvm-net.sh automatically."
    echo ""
    echo "⚠ The script already mounts the filesystem as READ-WRITE."
    echo "   → You won't get the rw mount error from the guide."
    echo ""
    echo "Press ENTER to continue..."
    read _wait
}

copy_default_files() {
    rm -rf "$DATA_DIR"/*
    cp "$FILES_DIR"/* "$DATA_DIR"
    chmod 777 "$DATA_DIR"/*
}

copy_saved_session() {
    rm -rf "$DATA_DIR"/*
    cp "$SAVED_DIR"/* "$DATA_DIR"
    chmod 777 "$DATA_DIR"/*
}

run_vm() {
    chmod +x "$DATA_DIR/run-crosvm-net.sh"
    "$DATA_DIR/run-crosvm-net.sh"
}

save_session() {
    echo "Saving session..."
    TS=$(date +%s)
    mkdir -p "$BACKUP_DIR/$TS"
    cp "$SAVED_DIR"/* "$BACKUP_DIR/$TS" 2>/dev/null

    cp "$DATA_DIR"/crosvm-a16 \
       "$DATA_DIR"/images.tar.gz \
       "$DATA_DIR"/kernel \
       "$DATA_DIR"/libbinder.so \
       "$DATA_DIR"/libbinder_ndk.so \
       "$DATA_DIR"/root_part \
       "$DATA_DIR"/run-crosvm-net.sh \
       "$SAVED_DIR"

    echo "Session saved!"
}

ask_run() {
    echo "Do you want to run the VM now? (y/n)"
    read x
    if [ "$x" = "y" ]; then
        run_vm

        while true; do
            echo ""
            echo "--- VM exited ---"
            echo "1) Run again"
            echo "2) Save session"
            echo "3) Return to main menu"
            printf "Choose an option: "
            read choice

            case "$choice" in
                1)
                    run_vm
                    ;;
                2)
                    save_session
                    ;;
                3)
                    return
                    ;;
                *)
                    echo "Invalid option."
                    ;;
            esac
        done
    fi
}

# =============================
#   FIRST SETUP
# =============================

first_setup() {
    ensure_directories

    if [ ! -f "$FIRST_SETUP_FLAG" ]; then
        echo "First-time setup detected."

        if files_missing_in_tmp; then
            echo "You do not have the VM files in $DATA_DIR."
            echo "Do you want to download them from the internet? (y/n)"
            read ans
            if [ "$ans" = "y" ]; then
                download_files_from_internet
                copy_default_files
            fi
        fi

        network_warning
        touch "$FIRST_SETUP_FLAG"
    fi
}

# =============================
#   MAIN MENU
# =============================

main_menu() {
    while true; do
        clear
        echo "=========================="
        echo "     Gunyah VM Manager"
        echo "=========================="
        echo "1) Load DEFAULT session"
        echo "2) Load SAVED session"
        echo "3) Execute directly (no copy)"
        echo "4) Download files from internet"
        echo "5) Exit"
        echo ""
        printf "Choose an option: "
        read option

        case "$option" in
            1)
                copy_default_files
                ask_run
                ;;
            2)
                if [ -z "$(ls -A $SAVED_DIR 2>/dev/null)" ]; then
                    echo "No saved session found."
                    sleep 2
                else
                    copy_saved_session
                    ask_run
                fi
                ;;
            3)
                ask_run
                ;;
            4)
                download_files_from_internet
                ;;
            5)
                exit 0
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

# =============================
#   START
# =============================

first_setup
main_menu
