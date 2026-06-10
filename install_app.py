#!/usr/bin/env python3
import sys
import argparse
import subprocess
import time

def run_cmd(cmd, check=True, capture=False):
    print(f"Executing: {' '.join(cmd)}")
    if capture:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if check and result.returncode != 0:
            print(f"Error executing command: {' '.join(cmd)}")
            print(result.stderr)
            sys.exit(1)
        return result.stdout
    else:
        result = subprocess.run(cmd)
        if check and result.returncode != 0:
            print(f"Command failed with exit code: {result.returncode}")
            sys.exit(result.returncode)
        return result.returncode

def switch_env(mode):
    env_map = {
        "dev": "dev",
        "staging": "staging",
        "release": "prod"
    }
    env_name = env_map.get(mode)
    if not env_name:
        print(f"Unknown mode: {mode}")
        sys.exit(1)
    run_cmd(["./switch_env.sh", env_name])

def get_connected_devices():
    output = run_cmd(["/Users/admin/.flutter-sdk/bin/flutter", "devices"], capture=True)
    devices = []
    for line in output.splitlines():
        if "•" in line:
            parts = [p.strip() for p in line.split("•")]
            if len(parts) >= 3:
                name_info = parts[0]
                device_id = parts[1]
                platform = parts[2].lower()
                devices.append({
                    "name": name_info,
                    "id": device_id,
                    "platform": platform
                })
    return devices

def launch_emulator(emulator_id):
    print(f"Launching emulator: {emulator_id}...")
    subprocess.Popen(["/Users/admin/.flutter-sdk/bin/flutter", "emulators", "--launch", emulator_id],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    print("Waiting for device to boot and connect...")
    for _ in range(30):
        time.sleep(2)
        devices = get_connected_devices()
        for d in devices:
            if emulator_id == "apple_ios_simulator" and "ios" in d["platform"] and "simulator" in d["name"].lower():
                print(f"iOS Simulator is online: {d['name']} ({d['id']})")
                return d["id"]
            if emulator_id == "Pixel_6_API_35" and "android" in d["platform"]:
                print(f"Android Emulator is online: {d['name']} ({d['id']})")
                return d["id"]
    print("Timeout waiting for emulator to connect.")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Build and install/run Flamehouse app on various platforms.")
    parser.add_argument("-p", "--platform", choices=["android", "ios", "desktop", "web"], required=True,
                        help="Target platform")
    parser.add_argument("-m", "--mode", choices=["dev", "staging", "release"], required=True,
                        help="Build mode / environment mapping")
    parser.add_argument("-d", "--device", help="Specific device ID (optional)")
    
    args = parser.parse_args()
    
    # 1. Switch environment
    switch_env(args.mode)
    
    # 2. Find device/target
    devices = get_connected_devices()
    target_device = None
    
    if args.device:
        target_device = args.device
        print(f"Using specified device: {target_device}")
    else:
        platform_devices = []
        for d in devices:
            if args.platform == "android" and "android" in d["platform"]:
                platform_devices.append(d)
            elif args.platform == "ios" and "ios" in d["platform"]:
                platform_devices.append(d)
            elif args.platform == "desktop" and "macos" in d["platform"]:
                platform_devices.append(d)
            elif args.platform == "web" and "web" in d["platform"]:
                platform_devices.append(d)
                
        if platform_devices:
            # Prioritize physical/wireless devices over simulators/emulators
            selected = platform_devices[0]
            for d in platform_devices:
                if args.platform == "ios" and "simulator" not in d["name"].lower():
                    selected = d
                    break
            target_device = selected["id"]
            print(f"Auto-detected connected device for {args.platform}: {selected['name']} ({target_device})")
        else:
            if args.platform == "android":
                target_device = launch_emulator("Pixel_6_API_35")
            elif args.platform == "ios":
                target_device = launch_emulator("apple_ios_simulator")
            elif args.platform == "desktop":
                target_device = "macos"
            elif args.platform == "web":
                target_device = "chrome"
            else:
                print(f"No connected devices found for platform: {args.platform}")
                sys.exit(1)
                
    # 3. Determine build mode parameter
    mode_flag = "--debug"
    if args.mode == "release":
        mode_flag = "--release"
        
    # 4. Run the app
    cmd = ["/Users/admin/.flutter-sdk/bin/flutter", "run", "-d", target_device, mode_flag]
    print(f"Running application on device {target_device}...")
    run_cmd(cmd)

if __name__ == "__main__":
    main()
