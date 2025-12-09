#!/bin/bash
# Deploy Firestore Security Rules

echo "🔒 Deploying Firestore Security Rules"
echo "====================================="
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo ""
    echo "Install it with:"
    echo "  npm install -g firebase-tools"
    echo ""
    exit 1
fi

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Not logged in to Firebase"
    echo "Please login first:"
    echo ""
    firebase login
    echo ""
fi

# Get current project
CURRENT_PROJECT=$(firebase use 2>&1 | grep "Active project" | awk '{print $NF}' | tr -d '()')

if [ -z "$CURRENT_PROJECT" ]; then
    echo "⚠️  No Firebase project selected"
    echo ""
    echo "Available projects:"
    firebase projects:list
    echo ""
    read -p "Enter project ID: " PROJECT_ID
    firebase use "$PROJECT_ID"
else
    echo "📋 Current project: $CURRENT_PROJECT"
    echo ""
    read -p "Continue with this project? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

echo ""
echo "📄 Firestore Rules Preview:"
echo "─────────────────────────────"
cat firestore.rules | head -30
echo "..."
echo "─────────────────────────────"
echo ""

read -p "Deploy these rules? (y/n): " DEPLOY_CONFIRM

if [ "$DEPLOY_CONFIRM" = "y" ]; then
    echo ""
    echo "🚀 Deploying..."
    firebase deploy --only firestore:rules
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Firestore rules deployed successfully!"
        echo ""
        echo "📋 What changed:"
        echo "  • Added read access to faceDataMeta collection"
        echo "  • Added login-pictures collection rules"
        echo "  • Authenticated staff can now read face data version"
        echo ""
        echo "🔄 The permission error should be resolved now."
    else
        echo ""
        echo "❌ Deployment failed!"
        echo "Check the error message above."
    fi
else
    echo ""
    echo "Cancelled."
fi
