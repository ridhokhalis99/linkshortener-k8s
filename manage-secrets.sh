echo "=== Kubernetes Secrets Helper ==="
echo "This script helps you encode secrets for Kubernetes"
echo ""

encode_secret() {
    echo -n "$1" | base64
}

decode_secret() {
    echo "$1" | base64 -d
}

echo "Choose an option:"
echo "1. Encode a secret"
echo "2. Decode a secret (for verification)"
echo "3. Generate random password"
echo "4. Exit"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        read -p "Enter the secret to encode: " -s secret
        echo ""
        encoded=$(encode_secret "$secret")
        echo "Encoded secret: $encoded"
        ;;
    2)
        read -p "Enter the base64 encoded secret to decode: " encoded
        decoded=$(decode_secret "$encoded")
        echo "Decoded secret: $decoded"
        ;;
    3)
        password=$(openssl rand -base64 12)
        echo "Generated password: $password"
        encoded=$(encode_secret "$password")
        echo "Base64 encoded: $encoded"
        ;;
    4)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
