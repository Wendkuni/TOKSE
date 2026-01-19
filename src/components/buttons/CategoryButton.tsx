import React from 'react';
import { TouchableOpacity, Text } from 'react-native';
import { Category } from '../../types';
import { 
  categoryButtonStyles, 
  CATEGORY_COLORS, 
  CATEGORY_LABELS 
} from '../../styles/components/CategoryButton.styles';

interface Props {
  category: Category;
  icon: string;
  onPress: (category: Category) => void;
}

export default function CategoryButton({ category, icon, onPress }: Props) {
  return (
    <TouchableOpacity
      style={[categoryButtonStyles.button, { backgroundColor: CATEGORY_COLORS[category] }]}
      onPress={() => onPress(category)}
      activeOpacity={0.7}
    >
      <Text style={categoryButtonStyles.icon}>{icon}</Text>
      <Text style={categoryButtonStyles.label}>{CATEGORY_LABELS[category]}</Text>
    </TouchableOpacity>
  );
}