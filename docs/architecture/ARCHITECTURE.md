# 📚 Architecture du projet Tokse

## Vue d'ensemble

Tokse est une application React Native construite avec Expo Router pour la gestion des signalements citoyens.

## Structure des dossiers

```
Tokse_Project/
├── app/                          # Routes Expo Router (navigation file-based)
│   ├── _layout.tsx              # Layout racine
│   ├── (auth)/                  # Routes d'authentification
│   ├── (tabs)/                  # Routes avec navigation tabs
│   ├── splash.tsx
│   ├── login.tsx
│   ├── signup.tsx
│   ├── feed.tsx
│   ├── signalement.tsx
│   └── profile.tsx
│
├── src/                          # Code source principal
│   ├── components/              # Composants réutilisables
│   │   ├── buttons/            # Boutons (CategoryButton, etc.)
│   │   ├── cards/              # Cartes (SignalementCard, etc.)
│   │   ├── logos/              # Logos (ToKSELogo, SplashLogo, etc.)
│   │   └── index.ts            # Export centralisé
│   │
│   ├── context/                 # Contextes React
│   │   └── ThemeContext.tsx    # Gestion du thème
│   │
│   ├── hooks/                   # Hooks personnalisés
│   │   ├── useSignalements.ts  # Gestion des signalements
│   │   ├── useFelicitations.ts # Gestion des likes
│   │   └── index.ts
│   │
│   ├── services/                # Logique backend
│   │   ├── auth.ts             # Authentification
│   │   ├── signalements.ts     # CRUD signalements
│   │   ├── storage.ts          # Upload fichiers
│   │   └── supabase.ts         # Client Supabase
│   │
│   ├── styles/                  # Styles séparés
│   │   ├── shared/             # Tokens de design
│   │   │   ├── colors.ts
│   │   │   ├── typography.ts
│   │   │   ├── spacing.ts
│   │   │   ├── shadows.ts
│   │   │   └── index.ts
│   │   ├── components/         # Styles des composants
│   │   │   ├── CategoryButton.styles.ts
│   │   │   └── SignalementCard.styles.ts
│   │   └── screens/            # Styles des écrans
│   │       ├── login.styles.ts
│   │       └── home.styles.ts
│   │
│   ├── types/                   # Types TypeScript
│   │   └── index.ts
│   │
│   └── utils/                   # Fonctions utilitaires
│       ├── date.ts             # Formatage dates
│       ├── validation.ts       # Validations
│       ├── formatting.ts       # Formatage textes
│       └── index.ts
│
├── components/                   # Composants génériques Expo
│   ├── ui/                      # Composants UI de base
│   ├── themed-text.tsx
│   ├── themed-view.tsx
│   └── TabIcon.tsx
│
├── constants/                    # Constantes globales
│   └── theme.ts
│
├── hooks/                        # Hooks globaux
│   └── use-color-scheme.ts
│
├── assets/                       # Ressources statiques
│   └── images/
│
├── docs/                         # Documentation
│   ├── architecture/
│   └── guides/
│
└── admin-dashboard/              # Dashboard admin séparé
    └── [fichiers React Vite]
```

## Conventions de code

### Séparation des styles

✅ **Bonne pratique** : Styles dans des fichiers `.styles.ts` séparés

```typescript
// CategoryButton.styles.ts
import { StyleSheet } from 'react-native';
import { COLORS, SPACING } from '../shared';

export const categoryButtonStyles = StyleSheet.create({
  button: {
    padding: SPACING.base,
    backgroundColor: COLORS.primary,
  },
});
```

```typescript
// CategoryButton.tsx
import { categoryButtonStyles } from '../styles/components/CategoryButton.styles';

export default function CategoryButton() {
  return <TouchableOpacity style={categoryButtonStyles.button} />;
}
```

### Imports centralisés

✅ **Bonne pratique** : Utiliser les fichiers `index.ts`

```typescript
// Au lieu de
import CategoryButton from '@/src/components/buttons/CategoryButton';
import SignalementCard from '@/src/components/cards/SignalementCard';

// Utiliser
import { CategoryButton, SignalementCard } from '@/src/components';
```

### Hooks personnalisés

✅ **Bonne pratique** : Extraire la logique métier dans des hooks

```typescript
// useSignalements.ts
export const useSignalements = () => {
  const [signalements, setSignalements] = useState([]);
  // ... logique
  return { signalements, loading, refresh };
};

// Dans le composant
const { signalements, loading, refresh } = useSignalements();
```

## Stack technologique

- **Framework** : React Native + Expo SDK 54
- **Navigation** : Expo Router v6 (file-based routing)
- **Backend** : Supabase (PostgreSQL + Auth + Storage)
- **État** : Context API + Hooks personnalisés
- **Styling** : StyleSheet avec tokens de design
- **TypeScript** : Mode strict activé
- **Linting** : ESLint avec config Expo

## Prochaines étapes

1. ✅ Séparation styles/logique complète
2. ✅ Hooks personnalisés créés
3. ✅ Utilitaires ajoutés
4. ✅ Documentation organisée
5. 🔄 Migration des imports vers la nouvelle structure
6. 📝 Tests unitaires à ajouter

---

Dernière mise à jour : 25 novembre 2025
