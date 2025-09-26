# 📄 Dépendances Required pour le PDF

Pour que le bouton de téléchargement PDF fonctionne, ajoutez ces dépendances dans votre `pubspec.yaml` :

```yaml
dependencies:
  # ... vos dépendances existantes ...
  
  # PDF Generation
  pdf: ^3.10.4
  path_provider: ^2.1.1
  
  # Partage de fichiers
  share_plus: ^7.2.1
  
  # Permissions
  permission_handler: ^11.0.1

dev_dependencies:
  # ... vos dev dependencies existantes ...
```

Puis exécutez :
```bash
flutter pub get
```

## Permissions Android

Ajoutez dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## Permissions iOS

Ajoutez dans `ios/Runner/Info.plist` :

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette app a besoin d'accéder aux photos pour partager les rapports PDF</string>
```
