import React from 'react';
import { ScrollView, StatusBar, StyleSheet, Text, View } from 'react-native';
import CategoryButton from '../components/CategoryButton';
import { Category } from '../types';

export default function HomeScreen() {
  const handleCategoryPress = (category: Category) => {
    console.log('Catégorie sélectionnée:', category);
    // TODO: Naviguer vers l'écran de signalement
    alert(`Catégorie sélectionnée: ${category}`);
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* En-tête */}
        <View style={styles.header}>
          <Text style={styles.logo}>TOKSE</Text>
          <Text style={styles.subtitle}>Signaler pour améliorer</Text>
        </View>

        {/* Description */}
        <View style={styles.descriptionBox}>
          <Text style={styles.description}>
            Choisissez une catégorie pour signaler une incivilité
          </Text>
        </View>

        {/* Boutons de catégories */}
        <View style={styles.categoriesContainer}>
          <CategoryButton
            category="dechets"
            icon="🗑️"
            onPress={handleCategoryPress}
          />
          <CategoryButton
            category="route"
            icon="🚧"
            onPress={handleCategoryPress}
          />
          <CategoryButton
            category="pollution"
            icon="🏭"
            onPress={handleCategoryPress}
          />
          <CategoryButton
            category="autre"
            icon="📢"
            onPress={handleCategoryPress}
          />
        </View>

        {/* Statistiques */}
        <View style={styles.statsContainer}>
          <View style={styles.statBox}>
            <Text style={styles.statNumber}>0</Text>
            <Text style={styles.statLabel}>Signalements</Text>
          </View>
          <View style={styles.statBox}>
            <Text style={styles.statNumber}>0</Text>
            <Text style={styles.statLabel}>Résolus</Text>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1a1a2e',
  },
  scrollContent: {
    padding: 20,
    paddingTop: 60,
  },
  header: {
    alignItems: 'center',
    marginBottom: 30,
  },
  logo: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#4285f4',
    letterSpacing: 4,
  },
  subtitle: {
    fontSize: 16,
    color: '#95a5a6',
    marginTop: 8,
  },
  descriptionBox: {
    backgroundColor: 'rgba(66, 133, 244, 0.1)',
    padding: 16,
    borderRadius: 12,
    marginBottom: 24,
    borderLeftWidth: 4,
    borderLeftColor: '#4285f4',
  },
  description: {
    color: '#ecf0f1',
    fontSize: 14,
    lineHeight: 20,
  },
  categoriesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 30,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 20,
  },
  statBox: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#4285f4',
  },
  statLabel: {
    fontSize: 14,
    color: '#95a5a6',
    marginTop: 4,
  },
});