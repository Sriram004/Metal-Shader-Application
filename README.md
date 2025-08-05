# Metal-Shader-Application


A real-time video filter iOS app built with Metal, SwiftUI, and AVFoundation. Developed as part of the **Flam iOS Assignment (Challenge 2: Metal Shader Programming)**.

---

## 📱 Features
- Real-time camera feed rendering using `MTKView`
- Metal compute shaders:
  - ✅ Gaussian Blur
  - ✅ Edge Detection (Sobel)
  - ✅ Chromatic Aberration
  - ✅ Tone Mapping with exposure + gamma
- MVVM architecture using `SwiftUI`
- Modular shader dispatch system

---

## 🧱 Project Structure
```
MetalEffectsApp/
├── App.swift
├── SceneDelegate.swift
├── Info.plist
├── Resources/
│   └── Textures/ (optional sample textures)
├── Services/
│   └── MetalProcessor.swift
├── Shaders/
│   ├── GaussianBlur.metal
│   ├── EdgeDetection.metal
│   ├── ChromaticAberration.metal
│   └── ToneMapping.metal
├── ViewModel/
│   └── CameraViewModel.swift
├── Views/
│   └── CameraView.swift
```

---

## 🚀 How to Run
1. Open `MetalEffectsApp.xcodeproj` in **Xcode 14+**.
2. Run on a real iOS device (camera required).
3. Ensure `NSCameraUsageDescription` is accepted.
4. Switch filters via scrollable button bar at bottom.

---

## 🛠 Requirements
- iOS 14+
- Xcode 14+
- Swift 5.5+
- Metal-compatible device

---

## 👨‍💻 Author
**Sriram S**  
Flam iOS Assignment – Challenge 2

> *This app demonstrates real-time GPU effects, tone mapping, and visual computing using Apple's Metal framework.*
