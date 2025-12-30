# 🎨 Documentation du Système de Thème TOKSE

## Vue d'ensemble

Le système de thème TOKSE offre une expérience utilisateur moderne avec support du **mode sombre et clair**. Les couleurs sont inspirées des applications les plus populaires (Instagram, Telegram, TikTok) et utilisent des gradients vibrants pour une meilleure expérience visuelle.

---

## 🏗️ Architecture

### ThemeContext (`src/context/ThemeContext.tsx`)

Le contexte global gère l'état du thème et met à jour automatiquement les couleurs à travers l'application.

**Fonctionnalités:**
- ✅ Sauvegarde automatique du thème dans `AsyncStorage`
- ✅ Chargement du thème au démarrage
- ✅ Hook `useTheme()` pour accéder au thème dans n'importe quel composant
- ✅ Fonction `toggleTheme()` pour basculer entre les modes

**Structure du contexte:**
```typescript
interface ThemeColors {
  background: string;
  backgroundSecondary: string;
  text: string;
  textSecondary: string;
  textTertiary: string;
  border: string;
  card: string;
  cardSecondary: string;
  accent: string;
  accentLight: string;
  accentDark: string;
  success: string;
  warning: string;
  error: string;
  info: string;
  shadow: string;
  gradient: string;
}
```

---

## 🎨 Palettes de Couleurs

### Mode Sombre (Dark Mode)
```
Background principal:     #0a0e27 (Très noir)
Background secondaire:    #1a1f3a (Noir foncé)
Texte principal:          #ffffff (Blanc pur)
Texte secondaire:         #b0b3c1 (Gris clair)
Texte tertiaire:          #727681 (Gris moyen)
Couleur accentuelle:      #f72585 (Rose/Magenta vibrant)
Accent clair:             #ff006e (Rouge vif)
Accent sombre:            #b01560 (Magenta profond)
Succès:                   #00f5aa (Cyan vif)
Avertissement:            #ffd60a (Jaune vif)
Erreur:                   #ff006e (Rouge)
Info:                     #0096c7 (Bleu)
```

### Mode Clair (Light Mode)
```
Background principal:     #ffffff (Blanc pur)
Background secondaire:    #f5f5f5 (Gris très clair)
Texte principal:          #000000 (Noir pur)
Texte secondaire:         #65676b (Gris foncé)
Texte tertiaire:          #8a8d91 (Gris moyen)
Couleur accentuelle:      #f72585 (Rose/Magenta - idem dark)
Accent clair:             #ff006e (Rouge vif - idem dark)
Accent sombre:            #b01560 (Magenta profond - idem dark)
Succès:                   #00a854 (Vert)
Avertissement:            #ff7a45 (Orange)
Erreur:                   #ff4d4f (Rouge clair)
Info:                     #1890ff (Bleu clair)
```

---

## 🚀 Utilisation

### 1️⃣ Importer le hook dans un composant

```typescript
import { useTheme } from '../src/context/ThemeContext';

export default function MyComponent() {
  const { colors, theme, toggleTheme } = useTheme();
  
  return (
    <View style={{ backgroundColor: colors.background }}>
      {/* contenu */}
    </View>
  );
}
```

### 2️⃣ Appliquer les couleurs aux styles

```typescript
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a2e', // ❌ Non - couleur fixe
  },
});

// ✅ Meilleur - utiliser colors dynamiques
<View style={[styles.container, { backgroundColor: colors.background }]}>
```

### 3️⃣ Ajouter un bouton de basculement de thème

```typescript
<TouchableOpacity onPress={toggleTheme}>
  <Text>{theme === 'dark' ? '☀️' : '🌙'}</Text>
</TouchableOpacity>
```

---

## 📱 Écrans mis à jour

| Écran | Statut | Notes |
|-------|--------|-------|
| `app/login.tsx` | ✅ Complet | Gradient Instagram + couleurs thème |
| `app/signup.tsx` | ✅ Complet | Gradient + écran OTP themé |
| `app/profile.tsx` | ✅ Complet | Bouton toggle thème + couleurs |
| `app/feed.tsx` | 🟡 Partiel | À intégrer |
| `app/(tabs)/index.tsx` | 🟡 Partiel | À intégrer |
| `app/(tabs)/explore.tsx` | ⭕ Non commencé | À faire |
| `app/(tabs)/feed.tsx` | 🟡 Partiel | À intégrer |

---

## 🎯 Caractéristiques de Design

### Gradients
L'application utilise des gradients modernes pour les en-têtes et boutons principaux:
- **Gradient primaire**: `#f72585 → #00d9ff` (Rose à Cyan)
- **Direction**: De haut-gauche vers bas-droite (135°)

### Coins arrondis
- Boutons: `borderRadius: 12`
- Cartes: `borderRadius: 12`
- Inputs: `borderRadius: 12`

### Ombres
- **Mode sombre**: `rgba(0, 0, 0, 0.8)`
- **Mode clair**: `rgba(0, 0, 0, 0.1)`

### Espacement
- Padding standard: `16-20px`
- Gap entre éléments: `12-16px`

---

## 🔄 Stockage Persistant

Le thème sélectionné est automatiquement sauvegardé dans `AsyncStorage`:
```typescript
// Clé: 'tokse_theme'
// Valeurs: 'dark' | 'light'
```

**Chargement automatique au démarrage** de l'application.

---

## 📖 Exemple complet

```tsx
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useTheme } from '../src/context/ThemeContext';
import { LinearGradient } from 'expo-linear-gradient';

export default function ExampleScreen() {
  const { colors, theme, toggleTheme } = useTheme();

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      {/* En-tête gradient */}
      <LinearGradient
        colors={['#f72585', '#00d9ff']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.header}
      >
        <Text style={styles.title}>Mon Application</Text>
      </LinearGradient>

      {/* Contenu */}
      <View style={[styles.card, { backgroundColor: colors.card }]}>
        <Text style={[styles.text, { color: colors.text }]}>
          Bienvenue dans TOKSE!
        </Text>
      </View>

      {/* Bouton toggle thème */}
      <TouchableOpacity
        style={[styles.button, { backgroundColor: colors.accent }]}
        onPress={toggleTheme}
      >
        <Text style={styles.buttonText}>
          {theme === 'dark' ? '☀️ Mode Clair' : '🌙 Mode Sombre'}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingTop: 40,
    paddingBottom: 30,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: '900',
    color: '#fff',
  },
  card: {
    margin: 20,
    padding: 16,
    borderRadius: 12,
  },
  text: {
    fontSize: 16,
  },
  button: {
    margin: 20,
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
```

---

## ✨ Prochaines étapes

1. **Intégrer le thème dans les écrans manquants**
   - `app/(tabs)/explore.tsx`
   - `app/(tabs)/feed.tsx`
   - `app/signalement.tsx`

2. **Ajouter des animations de transition**
   - Transition smooth lors du changement de thème

3. **Améliorer le design**
   - Cartes avec ombres plus prononcées
   - Animations au scroll
   - Icônes cohérentes

4. **Ajouter des presets de thème supplémentaires**
   - Thème bleu (pour les variantes)
   - Thème rose (pour les variantes)

---

## 📝 Notes de performance

- Le thème est chargé une fois au démarrage
- Le contexte utilise `useCallback` pour éviter les rendus inutiles
- Les couleurs sont recalculées seulement lors du changement de thème

---

## 🎓 Bonnes pratiques

✅ **À faire:**
- Utiliser `colors.background` au lieu de couleurs fixées
- Placer les valeurs de couleur dans les styles dynamiques
- Toujours fournir des alternatives de couleur pour le thème clair

❌ **À éviter:**
- Hardcoder les couleurs directement
- Ignorer les thèmes utilisateur
- Utiliser des couleurs qui ne contrastent pas bien

---

**Créé le**: 12 November 2025
**Version**: 1.0
**Inspiré par**: Instagram, Telegram, TikTok
