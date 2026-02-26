# Real-Time WhatsApp OTP Implementation Guide

## ✅ Implementation Complete!

This guide explains how to send real-time OTP via WhatsApp to Bangladeshi phone numbers.

---

## 🎯 What's Implemented

### 1. **Flutter App (Client)**
- **New Service**: `lib/services/whatsapp_otp_service.dart`
  - Supports both mock mode (testing) and production mode
  - Validates Bangladeshi phone numbers
  - Formats numbers to international standard (+880)
  - Handles errors gracefully

### 2. **Backend Examples**
- **Node.js/Express**: `backend_examples/nodejs_express/`
  - Complete server implementation with Twilio
  - OTP storage and verification
  - Expiration handling (5 minutes)

---

## 📱 How It Works

### Flow:
```
1. User enters phone number (e.g., 01712345678)
2. App generates 6-digit OTP
3. App calls backend API
4. Backend sends WhatsApp message via Twilio
5. User receives OTP on WhatsApp
6. User enters OTP in app
7. App verifies OTP with backend
8. User is logged in
```

---

## 🚀 Quick Start (Testing)

### Current Status: MOCK MODE ✓
The app is currently in **mock mode** which means:
- ✅ OTP is generated
- ✅ Phone number is validated
- ✅ OTP is printed to console (for testing)
- ❌ No actual WhatsApp message sent

### To Test:
1. Run the app: `flutter run`
2. Enter a Bangladeshi phone number
3. Click "Send OTP via WhatsApp"
4. Check the console/terminal for the OTP
5. Enter the OTP in the app

---

## 🔧 Production Setup

### Step 1: Get Twilio Account

1. **Sign up for Twilio**:
   - Visit: https://www.twilio.com/try-twilio
   - Get $15 free credit (enough for ~1000 messages)

2. **Enable WhatsApp**:
   - Go to: https://console.twilio.com/us1/develop/sms/try-it-out/whatsapp-learn
   - Follow the WhatsApp sandbox setup
   - Note your WhatsApp number (e.g., `whatsapp:+14155238886`)

3. **Get Credentials**:
   - Account SID: Found on your Twilio Console Dashboard
   - Auth Token: Found on your Twilio Console Dashboard

### Step 2: Deploy Backend

#### Option A: Deploy to Heroku (Recommended for beginners)

```bash
cd backend_examples/nodejs_express

# Install Heroku CLI
# Visit: https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login

# Create app
heroku create care-people-otp-backend

# Set environment variables
heroku config:set TWILIO_ACCOUNT_SID=your_sid
heroku config:set TWILIO_AUTH_TOKEN=your_token
heroku config:set TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886

# Deploy
git init
git add .
git commit -m "Initial commit"
git push heroku main

# Your backend URL will be: https://care-people-otp-backend.herokuapp.com
```

#### Option B: Deploy to Railway (Modern alternative)

```bash
# Visit: https://railway.app
# Connect your GitHub repo
# Add environment variables in Railway dashboard
# Railway will auto-deploy
```

#### Option C: Run Locally (For testing)

```bash
cd backend_examples/nodejs_express

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your Twilio credentials
nano .env

# Run server
npm start

# Server runs on http://localhost:3000
```

### Step 3: Update Flutter App

1. **Update Backend URL**:
   
   In `lib/services/whatsapp_otp_service.dart`, change line 13:
   ```dart
   static const String _backendUrl = 'https://your-backend-url.herokuapp.com';
   ```

2. **Disable Mock Mode**:
   
   Change line 17:
   ```dart
   static const bool _useMockMode = false;
   ```

3. **Rebuild App**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 📝 Usage in Code

### Send OTP:
```dart
import 'package:care_people/services/whatsapp_otp_service.dart';

// Send OTP
final response = await WhatsAppOTPService.sendOTP(
  phoneNumber: '01712345678',
);

if (response.success) {
  print('OTP sent: ${response.otp}');
  print('Message ID: ${response.messageId}');
} else {
  print('Error: ${response.message}');
}
```

### Verify OTP:
```dart
final isValid = await WhatsAppOTPService.verifyOTP(
  phoneNumber: '01712345678',
  enteredOTP: '123456',
  sentOTP: storedOTP,
);

if (isValid) {
  // Login successful
} else {
  // Invalid OTP
}
```

---

## 💰 Pricing

### Twilio WhatsApp Business API:
- **Sandbox (Testing)**: FREE
- **Production**:
  - Bangladesh: ~$0.005 - $0.01 per message
  - 1000 messages ≈ $5-10
  - Pay-as-you-go, no monthly fees

### Alternatives:
- **MessageBird**: Similar pricing
- **Vonage**: Similar pricing
- **360Dialog**: Requires business verification

---

## 🔒 Security Best Practices

### ✅ DO:
- Store API keys on backend only
- Use HTTPS for all API calls
- Implement rate limiting (max 3 OTPs per hour per number)
- Add OTP expiration (5 minutes)
- Delete OTP after verification
- Use secure random number generation

### ❌ DON'T:
- Store API keys in Flutter app
- Send OTP directly from app
- Allow unlimited OTP requests
- Store OTPs permanently
- Use predictable OTP patterns

---

## 🧪 Testing

### Test Phone Numbers (Twilio Sandbox):
1. Join sandbox by sending message to Twilio number
2. Follow instructions in WhatsApp
3. Your number is now verified for testing

### Testing Checklist:
- [ ] Valid Bangladeshi number (01XXXXXXXXX)
- [ ] Invalid number format
- [ ] Network error handling
- [ ] OTP expiration (5 minutes)
- [ ] Wrong OTP entry
- [ ] Multiple OTP requests

---

## 🐛 Troubleshooting

### Error: "Failed to send OTP"
- Check backend is running
- Verify Twilio credentials
- Check internet connection

### Error: "Invalid phone number"
- Ensure number starts with 01
- Must be 11 digits
- Remove spaces/dashes

### Error: "WhatsApp not available"
- Only in mock mode or emulator
- Real devices will receive messages

### OTP not received:
- Check phone number is correct
- Verify Twilio sandbox is active
- Check Twilio console for delivery status

---

## 📚 Additional Resources

### Documentation:
- Twilio WhatsApp: https://www.twilio.com/docs/whatsapp
- Flutter http: https://pub.dev/packages/http
- Bangladesh phone format: +880 1X XXXX XXXX

### Support:
- Twilio Support: https://support.twilio.com
- Flutter Docs: https://flutter.dev

---

## 🎉 Current Features

✅ Real-time OTP generation  
✅ Bangladeshi phone number validation  
✅ WhatsApp message formatting  
✅ Mock mode for testing  
✅ Production-ready backend example  
✅ Error handling  
✅ OTP expiration  
✅ Secure verification  

---

## 🔄 Next Steps

1. **For Testing**: Use mock mode (already enabled)
2. **For Production**: 
   - Set up Twilio account
   - Deploy backend
   - Update app configuration
   - Test with real numbers
   - Deploy app

---

## 📞 Support

If you need help:
1. Check the troubleshooting section
2. Review Twilio documentation
3. Check backend logs
4. Verify phone number format

---

**Last Updated**: February 27, 2026  
**Version**: 1.0.0  
**Status**: Ready for production with backend setup
