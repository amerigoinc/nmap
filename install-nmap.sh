#!/bin/bash
# NMAP Installer for CI Package Manager
set -e

echo "🔧 Installing nmap from source..."

# Check dependencies
check_dependencies() {
    local deps=("gcc" "make" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "❌ Missing dependency: $dep"
            echo "💡 Install with: sudo apt install $dep"
            return 1
        fi
    done
    return 0
}

# Clone nmap
clone_nmap() {
    local temp_dir=$(mktemp -d)
    echo "📥 Cloning nmap from GitHub..."
    
    git clone https://github.com/nmap/nmap.git "$temp_dir"
    cd "$temp_dir"
    
    # Configure and build
    echo "🛠️  Configuring nmap..."
    ./configure --prefix="$HOME/.ci/packages/nmap" --without-zenmap
    
    echo "🔨 Building nmap (this may take a few minutes)..."
    make -j$(nproc)
    
    echo "📦 Installing to CI packages directory..."
    make install
    
    # Copy to CI packages
    mkdir -p "$HOME/.ci/packages/nmap"
    cp -r "$temp_dir"/* "$HOME/.ci/packages/nmap/" 2>/dev/null || true
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Create nmap launcher
create_launcher() {
    cat > "$HOME/.ci/apps/nmap" << 'LAUNCHER'
#!/bin/bash
# NMAP Launcher for CI Package Manager
export PATH="$HOME/.ci/packages/nmap/bin:$PATH"
export MANPATH="$HOME/.ci/packages/nmap/share/man:$MANPATH"
exec "$HOME/.ci/packages/nmap/bin/nmap" "$@"
LAUNCHER

    chmod +x "$HOME/.ci/apps/nmap"
    ln -sf "$HOME/.ci/apps/nmap" "$HOME/.ci/bin/nmap"
}

# Main installation
main() {
    echo "🚀 NMAP Installation for CI Package Manager"
    echo "==========================================="
    
    if ! check_dependencies; then
        echo "❌ Please install missing dependencies first"
        exit 1
    fi
    
    clone_nmap
    create_launcher
    
    echo ""
    echo "🎉 NMAP installed successfully!"
    echo "💡 Usage: nmap --help"
    echo "💡 Example: nmap -sS 192.168.1.1"
}

main "$@"
