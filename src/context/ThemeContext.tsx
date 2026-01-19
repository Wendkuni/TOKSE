import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, ReactNode, useEffect, useState } from 'react';

export type ThemeType = 'light' | 'dark';

interface ThemeColors {
  // Primary colors
  background: string;
  backgroundSecondary: string;
  text: string;
  textSecondary: string;
  textTertiary: string;
  
  // UI Elements
  border: string;
  card: string;
  cardSecondary: string;
  
  // Action colors (inspired by Instagram, Telegram, TikTok)
  accent: string;
  accentLight: string;
  accentDark: string;
  
  // Status colors
  success: string;
  warning: string;
  error: string;
  info: string;
  
  // Gradients and effects
  shadow: string;
  gradient: string;
}

interface ThemeContextType {
  theme: ThemeType;
  colors: ThemeColors;
  toggleTheme: () => void;
}

// TOKSE Design System - Dark Theme
const DARK_COLORS: ThemeColors = {
  // Background - Mode sombre (fond gris/bleu foncé)
  background: '#1a1a2e',
  backgroundSecondary: '#16213e',
  text: '#ecf0f1',
  textSecondary: '#bdc3c7',
  textTertiary: '#95a5a6',
  
  // UI Elements
  border: 'rgba(66, 133, 244, 0.2)',
  card: '#0f3460',
  cardSecondary: '#16213e',
  
  // Action colors - Bleu
  accent: '#4285f4', // Bleu principal
  accentLight: '#669df6', // Bleu clair
  accentDark: '#1a73e8', // Bleu foncé
  
  // Status colors - Harmonisés pour dark mode
  success: '#2ecc71', // Vert clair
  warning: '#f39c12', // Orange
  error: '#e74c3c', // Rouge clair
  info: '#4285f4', // Bleu principal
  
  // Effects
  shadow: 'rgba(66, 133, 244, 0.15)',
  gradient: 'linear-gradient(135deg, #4285f4 0%, #1a73e8 100%)',
};

// TOKSE Design System - Light Theme  
const LIGHT_COLORS: ThemeColors = {
  // Background - Mode clair (fond blanc)
  background: '#ffffff',
  backgroundSecondary: '#f5f7fa',
  text: '#1a1a1a',
  textSecondary: '#4a5568',
  textTertiary: '#718096',
  
  // UI Elements
  border: '#e2e8f0',
  card: '#f8fafc',
  cardSecondary: '#f1f5f9',
  
  // Action colors - Bleu
  accent: '#1a73e8', // Bleu primaire
  accentLight: '#4285f4', // Bleu moyen
  accentDark: '#1557b0', // Bleu foncé
  
  // Status colors - Harmonisés pour light mode
  success: '#10b981', // Vert
  warning: '#f59e0b', // Orange
  error: '#ef4444', // Rouge
  info: '#1a73e8', // Bleu primaire
  
  // Effects
  shadow: 'rgba(26, 115, 232, 0.1)',
  gradient: 'linear-gradient(135deg, #1a73e8 0%, #4285f4 100%)',
};

export const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

interface ThemeProviderProps {
  children: ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const [theme, setTheme] = useState<ThemeType>('dark');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadTheme();
  }, []);

  const loadTheme = async () => {
    try {
      const savedTheme = await AsyncStorage.getItem('tokse_theme');
      if (savedTheme === 'light' || savedTheme === 'dark') {
        setTheme(savedTheme);
      }
    } catch (error) {
      console.error('Erreur chargement theme:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleTheme = async () => {
    try {
      const newTheme = theme === 'dark' ? 'light' : 'dark';
      setTheme(newTheme);
      await AsyncStorage.setItem('tokse_theme', newTheme);
    } catch (error) {
      console.error('Erreur sauvegarde theme:', error);
    }
  };

  const colors = theme === 'dark' ? DARK_COLORS : LIGHT_COLORS;

  return (
    <ThemeContext.Provider value={{ theme, colors, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = React.useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme doit être utilisé dans ThemeProvider');
  }
  return context;
};
