# 🎨 Guide des styles Tokse

## Organisation des styles

Les styles sont maintenant séparés de la logique dans `src/styles/`.

### Structure

```
src/styles/
├── shared/              # Tokens de design globaux
│   ├── colors.ts       # Palette de couleurs
│   ├── typography.ts   # Typographie
│   ├── spacing.ts      # Espacements & border radius
│   ├── shadows.ts      # Ombres
│   └── index.ts        # Export centralisé
│
├── components/         # Styles des composants
│   ├── CategoryButton.styles.ts
│   └── SignalementCard.styles.ts
│
└── screens/           # Styles des écrans
    ├── login.styles.ts
    └── home.styles.ts
```

## Utilisation

### 1. Importer les tokens

```typescript
import { COLORS, SPACING, BORDER_RADIUS, TYPOGRAPHY, SHADOWS } from '@/src/styles/shared';
```

### 2. Créer un fichier de styles

```typescript
// MonComposant.styles.ts
import { StyleSheet } from 'react-native';
import { COLORS, SPACING, BORDER_RADIUS } from '../shared';

export const monComposantStyles = StyleSheet.create({
  container: {
    padding: SPACING.base,
    borderRadius: BORDER_RADIUS.md,
    backgroundColor: COLORS.background.card,
  },
  title: {
    fontSize: TYPOGRAPHY.fontSize.lg,
    color: COLORS.text.primary,
  },
});
```

### 3. Utiliser dans le composant

```typescript
// MonComposant.tsx
import { monComposantStyles } from '../styles/components/MonComposant.styles';

export default function MonComposant() {
  return (
    <View style={monComposantStyles.container}>
      <Text style={monComposantStyles.title}>Titre</Text>
    </View>
  );
}
```

## Tokens disponibles

### Couleurs (COLORS)

```typescript
COLORS.primary
COLORS.secondary
COLORS.accent
COLORS.dechets
COLORS.route
COLORS.pollution
COLORS.autre
COLORS.text.primary
COLORS.text.secondary
COLORS.background.card
COLORS.overlay.light
```

### Espacements (SPACING)

```typescript
SPACING.xs    // 4px
SPACING.sm    // 8px
SPACING.md    // 12px
SPACING.base  // 16px
SPACING.lg    // 20px
SPACING.xl    // 24px
SPACING.xxl   // 32px
```

### Border Radius (BORDER_RADIUS)

```typescript
BORDER_RADIUS.sm    // 4px
BORDER_RADIUS.md    // 8px
BORDER_RADIUS.lg    // 12px
BORDER_RADIUS.xl    // 16px
BORDER_RADIUS.full  // 999px (cercle)
```

### Typographie (TYPOGRAPHY)

```typescript
TYPOGRAPHY.fontSize.xs     // 10
TYPOGRAPHY.fontSize.sm     // 12
TYPOGRAPHY.fontSize.base   // 14
TYPOGRAPHY.fontSize.md     // 16
TYPOGRAPHY.fontSize.lg     // 18
TYPOGRAPHY.fontWeight.bold // '700'
```

### Ombres (SHADOWS)

```typescript
SHADOWS.sm  // Petite ombre
SHADOWS.md  // Ombre moyenne
SHADOWS.lg  // Grande ombre
SHADOWS.xl  // Très grande ombre
```

## Avantages

✅ **Cohérence** : Tous les composants utilisent les mêmes valeurs  
✅ **Maintenabilité** : Modifier une couleur en un seul endroit  
✅ **Lisibilité** : Séparation claire entre logique et présentation  
✅ **Réutilisabilité** : Tokens partagés entre composants  
✅ **Thématisation** : Facile d'ajouter un thème sombre  

## Migration d'un composant existant

**Avant** :
```typescript
const styles = StyleSheet.create({
  button: {
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#3498db',
  },
});
```

**Après** :
```typescript
// MonComposant.styles.ts
import { COLORS, SPACING, BORDER_RADIUS } from '../shared';

export const styles = StyleSheet.create({
  button: {
    padding: SPACING.base,
    borderRadius: BORDER_RADIUS.lg,
    backgroundColor: COLORS.primary,
  },
});

// MonComposant.tsx
import { styles } from '../styles/components/MonComposant.styles';
```

---

Dernière mise à jour : 25 novembre 2025
