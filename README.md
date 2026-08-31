# 🧶 Handora — AI Digital Shop Assistant for Indian Artisans

**Smart India Hackathon (SIH) Project**

Handora is a mobile app that helps Indian artisans sell their handmade products online through ONDC — even if they've never used a computer. Just point the camera at a product, and AI does the rest.

---

## 🎯 The Problem

Millions of Indian artisans (potters, weavers, toy makers) create beautiful products but struggle to sell online because:
- They can't type product listings in English
- They don't know how to set competitive prices
- They have no idea how to manage orders or talk to buyers digitally
- Internet connectivity is unreliable in rural areas

## 💡 Our Solution

**Snap a photo → AI creates the listing → Sell on ONDC.**

Handora uses **Gemini AI** to turn a simple camera photo into a complete product listing with title, description, category, and a realistic local market price — all in both Hindi and English. No typing needed.

---

## ✨ Key Features

### 📸 AI-Powered Catalog Creation
- Take a photo of any handmade product
- **Gemini Vision AI** identifies the item and generates:
  - Product title (English + Hindi)
  - Description and category
  - Realistic price based on **Delhi local market rates** (not inflated global prices)
- Saved to local SQLite + synced to Supabase cloud

### 🎤 Voice-First Experience
- **Voice Assistant** on the Help screen — ask questions by speaking in Hindi or English
- **Edit by Voice** — tap any product and say *"कीमत 500 रुपये कर दो"* (set price to ₹500) to update it
- AI understands natural Hindi/English speech and updates the product automatically
- Text-to-Speech reads back confirmations aloud

### 📦 Order Management
- Track orders through their lifecycle: **New → Processing → Shipped → Delivered**
- Each order shows buyer name, phone number, product details, and amount
- One-tap status updates saved instantly to SQLite

### 💬 WhatsApp Buyer Messaging
- Tap **"Send WhatsApp Update"** on any order
- Generates a polite bilingual message with order details and current status
- Opens WhatsApp directly via `wa.me` deep link — no API key needed

### 🔄 Offline-First with Auto Sync
- Works without internet — all data saved locally in SQLite
- When network returns, products automatically sync to Supabase cloud
- Visual indicators: amber **"Pending Sync"** badge or green **"Live on ONDC"** badge
- Sync banner on Catalog screen: *"3 items pending cloud sync. Tap to sync now."*

### 🌐 Fully Bilingual (Hindi + English)
- Every screen, button, and AI response works in both languages
- Toggle between English and Hindi with one tap
- Voice assistant responds in the language you speak

### 🎨 Polished UI
- Dark and Light theme support
- Animated shimmer loading cards during AI processing
- Celebratory success animations when products are added
- Before → After comparisons when voice edits are applied

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Provider |
| Local Database | SQLite (sqflite) |
| Cloud Backend | Supabase (PostgreSQL + Storage) |
| AI Engine | Google Gemini 2.5 Flash (Vision + Audio) |
| Voice Recording | record package |
| Text-to-Speech | flutter_tts |
| WhatsApp | url_launcher (wa.me deep links) |
| Network Monitoring | connectivity_plus |
| Charts | fl_chart |

---

## 📁 Project Structure

```
lib/
├── l10n/           # Bilingual strings (English + Hindi)
├── models/         # Data models (Product, Order)
├── providers/      # State management (AppState, DataProvider)
├── screens/        # App screens
│   ├── home_screen.dart      # Dashboard with sales overview + recent orders
│   ├── catalog_screen.dart   # Product grid with sync status
│   ├── capture_screen.dart   # Camera → AI → Save product flow
│   ├── growth_screen.dart    # Revenue analytics charts
│   └── help_screen.dart      # Voice assistant
├── services/
│   ├── database_helper.dart       # SQLite CRUD, migrations, settings
│   ├── supabase_service.dart      # Cloud storage + database sync
│   ├── supabase_gateway.dart      # Injectable seam over Supabase (testing)
│   ├── gemini_client.dart         # Gemini transport (proxy or direct)
│   ├── gemini_service.dart        # AI vision + voice processing
│   ├── voice_assistant_service.dart # Audio recording + TTS
│   └── whatsapp_service.dart      # WhatsApp deep link messaging
├── theme/          # Colors, typography, dark/light themes
├── utils/
│   └── rupees.dart                # Indian digit grouping (₹1,00,000)
├── widgets/        # Reusable UI components
│   ├── product_card.dart          # Product tile with sync badges
│   ├── edit_voice_info_modal.dart # Voice-edit bottom sheet
│   ├── order_details_modal.dart   # Order management + WhatsApp
│   ├── recent_orders.dart         # Order list on Home
│   ├── shimmer_product_card.dart  # Loading skeleton
│   └── success_feedback_widgets.dart # Animated celebrations
└── main.dart       # App entry point

assets/fonts/       # Inter + Noto Sans Devanagari, bundled for offline use
supabase/functions/gemini/  # Edge Function keeping the Gemini key server-side
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.1`
- **JDK 17** — required for the Android Gradle build
- Android Studio or VS Code
- Android emulator or physical device

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/harshit18523/artisan-project.git
cd artisan-project

# 2. Create a .env file (see .env.example for reference)
cp .env.example .env
# Fill in your Supabase URL, Supabase Anon Key, and Gemini API Key

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run

# 5. Build release APK
flutter build apk --release
```

### Environment Variables (`.env`)

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# Set ONE of the following for Gemini access.

# Preferred — Edge Function that holds the API key server-side:
#   supabase secrets set GEMINI_API_KEY=<your key>
#   supabase functions deploy gemini
GEMINI_PROXY_URL=https://your-project.supabase.co/functions/v1/gemini

# Fallback for local demos. Note that `.env` is bundled into the APK, so this
# key is extractable by anyone holding the build — don't ship it.
GEMINI_API_KEY=your-google-gemini-api-key
```

---

## 👥 Team

Built for **Smart India Hackathon (SIH)** — empowering rural Indian artisans with AI-driven digital commerce tools.

---

## 📄 License

This project is built for the SIH hackathon demonstration.
