import React from 'react';
import {
  ActivityIndicator,
  Image,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  CATEGORY_INFO,
  signalementCardStyles
} from '../../styles/components/SignalementCard.styles';

export interface SignalementCardProps {
  id: string;
  categorie: string;
  description: string;
  photo_url: string;
  adresse: string;
  felicitations: number;
  created_at: string;
  onFelicitate?: () => void;
  onPress?: () => void;
  isLiked?: boolean;
  isLoading?: boolean;
}

export default function SignalementCard({
  id,
  categorie,
  description,
  photo_url,
  adresse,
  felicitations,
  created_at,
  onFelicitate,
  onPress,
  isLiked = false,
  isLoading = false,
}: SignalementCardProps) {
  const categoryInfo = CATEGORY_INFO[categorie] || CATEGORY_INFO.autre;
  
  // Format date
  const date = new Date(created_at);
  const formattedDate = date.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });

  const styles = signalementCardStyles;

  return (
    <TouchableOpacity
      style={styles.card}
      onPress={onPress}
      activeOpacity={0.7}
    >
      {/* Image */}
      <Image
        source={{ uri: photo_url }}
        style={styles.image}
      />

      {/* Overlay avec catégorie */}
      <View style={[styles.categoryBadge, { backgroundColor: categoryInfo.color }]}>
        <Text style={styles.categoryIcon}>{categoryInfo.icon}</Text>
        <Text style={styles.categoryLabel}>{categoryInfo.label}</Text>
      </View>

      {/* Contenu */}
      <View style={styles.content}>
        {/* Description */}
        <Text style={styles.description} numberOfLines={2}>
          {description}
        </Text>

        {/* Localisation */}
        <View style={styles.locationRow}>
          <Text style={styles.locationIcon}>📍</Text>
          <Text style={styles.location} numberOfLines={1}>
            {adresse}
          </Text>
        </View>

        {/* Footer avec date et félicitations */}
        <View style={styles.footer}>
          <Text style={styles.date}>{formattedDate}</Text>

          {/* Bouton félicitation */}
          <TouchableOpacity
            style={[
              styles.felicitationButton,
              isLiked && styles.felicitationButtonActive,
            ]}
            onPress={onFelicitate}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator size="small" color={isLiked ? '#e74c3c' : '#95a5a6'} />
            ) : (
              <>
                <Text style={styles.felicitationIcon}>
                  {isLiked ? '❤️' : '🤍'}
                </Text>
                <Text style={[styles.felicitationCount, isLiked && styles.felicitationCountActive]}>
                  {felicitations}
                </Text>
              </>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
  );
}
