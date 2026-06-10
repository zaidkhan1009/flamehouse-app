# Flamehouse App

A Flutter-based console client for managing menus, categories, and inventory, connected to the `viral_bytes` FastAPI backend.

---

## 🛠️ Environment Switching & Branding

Configurations (API endpoints, app name, and environment flags) are segregated at the build level. 

### 1. The Environment Swapping Tool
Run [`switch_env.sh`](file:///Users/admin/Repo/flamehouse-app/switch_env.sh) to configure the target environment:
```bash
# Swaps to Dev environment configuration (Display Name: Flamehouse Dev)
./switch_env.sh dev

# Swaps to Staging/UAT environment configuration (Display Name: Flamehouse UAT)
./switch_env.sh staging

# Swaps to Production environment configuration (Display Name: Flamehouse)
./switch_env.sh prod
```

### 2. Git Branch Mapping
Maintain the environment consistency across branches:
- **`develop` branch:** Points to local dev configuration (localhost API).
- **`uat` branch:** Points to staging resources.
- **`main` branch:** Points to production resources.

---

## 💻 Local Testing with Local Backend

### 1. Local Database Setup (PostgreSQL)
Ensure you have a local PostgreSQL instance running:
```bash
# Start PostgreSQL service
brew services start postgresql@14

# Access database or run seed scripts
# Local database name: flamehouse_dev (Role: postgres, No password, sslmode=disable)
```

### 2. Run the Backend Server
In the `viral_bytes` project, start the FastAPI server:
```bash
.venv/bin/uvicorn main:app --host 0.0.0.0 --port 10000 --reload
```

### 3. Connect the Phone/Emulator to the Local Backend
Because your mobile device needs to reach the backend running on your Mac, use one of the following methods:

#### Option A: Using the Active Localtunnel (Physical Devices)
Expose the backend port `10000` to the internet using localtunnel:
```bash
npx -y localtunnel --port 10000
```
Copy the generated public URL (e.g. `https://fancy-cups-cough.loca.lt`) and paste it as the `API_BASE_URL` inside your client [`flamehouse-app/.env`](file:///Users/admin/Repo/flamehouse-app/.env) file.

#### Option B: Wi-Fi Local Connection (Physical Devices)
1. Ensure both your Mac and phone are on the same Wi-Fi network.
2. Find your Mac's local IP (e.g. `192.168.1.50`).
3. Set the `API_BASE_URL` in [`.env`](file:///Users/admin/Repo/flamehouse-app/.env):
   ```env
   API_BASE_URL=http://192.168.1.50:10000/api/v1
   ```

#### Option C: Emulators & Simulators
Emulators can access the host machine's loopback interface natively:
- **Android Emulator**: Set `API_BASE_URL=http://10.0.2.2:10000/api/v1`
- **iOS Simulator**: Set `API_BASE_URL=http://localhost:10000/api/v1`

---

## 📦 Building and Deploying

Use the utility script [`install_app.py`](file:///Users/admin/Repo/flamehouse-app/install_app.py) to switch environments, detect target physical devices, compile, and run the app:
```bash
# Run on Android in Dev mode
python3 install_app.py -p android -m dev

# Run on iOS in Staging/UAT mode
python3 install_app.py -p ios -m staging

# Run on Android in Release mode
python3 install_app.py -p android -m release
```

---

## 📤 Custom APK Sharing Naming Convention

When using the **Share App** feature from the Login Screen drawer menu on Android:
- The app automatically duplicates the running base APK into a temporary folder.
- It renames the file using the convention: `flamehouse_[env]_[version].apk` (e.g. `flamehouse_dev_1.0.0.apk`) before calling the Android share sheet.
- This helps you share specific environment builds cleanly with QA and other stakeholders.

---

## 🛑 Verification & Push Protection Rule

Before committing or pushing any feature or bug fix, you **must** verify that all code compiles, follows all lint rules, and passes all widget/unit tests:

1. **Verify Static Code Analysis**:
   ```bash
   /Users/admin/.flutter-sdk/bin/flutter analyze
   ```
2. **Verify Tests**:
   ```bash
   /Users/admin/.flutter-sdk/bin/flutter test
   ```

To automate this check, the project contains a pre-push git hook. If it's not active:
1. Copy the script to `.git/hooks/pre-push` inside the project.
2. Make it executable:
   ```bash
   chmod +x .git/hooks/pre-push
   ```
This hook will automatically block any `git push` if code analysis or unit tests fail.
