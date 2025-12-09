#!/bin/bash
# Test Twilio WhatsApp Integration for Face Attendance
# WARNING: Replace credentials with environment variables in production!

echo "🔐 Twilio WhatsApp Message Test"
echo "================================"
echo ""

# Check if credentials are set
if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ]; then
    echo "⚠️  WARNING: Using hardcoded credentials (INSECURE!)"
    echo "    For production, use environment variables:"
    echo "    export TWILIO_ACCOUNT_SID=your_sid"
    echo "    export TWILIO_AUTH_TOKEN=your_token"
    echo ""
    
    # Hardcoded for testing (REMOVE IN PRODUCTION!)
    TWILIO_ACCOUNT_SID="REDACTED_TWILIO_SID"
    TWILIO_AUTH_TOKEN="REDACTED_TWILIO_TOKEN"
fi

TWILIO_WHATSAPP_FROM="whatsapp:+14155238886"
CONTENT_SID="HXb5b62575e6e4ff6129ad7c8efe1f983e"

echo "Testing message to parent..."
echo ""

# Test 1: Simple content template message
echo "📤 Test 1: Sending content template message"
PARENT_NUMBER="whatsapp:+60177383777"
STUDENT_NAME="demo01-student01"
DATE="12/8"
TIME="3:15 PM"

curl "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json" \
    -X POST \
    --data-urlencode "To=${PARENT_NUMBER}" \
    --data-urlencode "From=${TWILIO_WHATSAPP_FROM}" \
    --data-urlencode "ContentSid=${CONTENT_SID}" \
    --data-urlencode "ContentVariables={\"1\":\"${DATE}\",\"2\":\"${TIME}\"}" \
    -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
    -s -w "\n\nHTTP Status: %{http_code}\n" | jq '.'

echo ""
echo "✅ Test complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Check parent's WhatsApp for message"
echo "   2. Verify template variables rendered correctly"
echo "   3. Test with actual face detection picture URL"
echo ""
echo "🔒 Security reminder:"
echo "   • Rotate these credentials in Twilio console"
echo "   • Use environment variables in production"
echo "   • Never commit credentials to git"
