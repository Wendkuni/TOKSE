import { createClient } from '@supabase/supabase-js';
import 'react-native-get-random-values';
import 'react-native-url-polyfill/auto';


const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;

let authOptions: Record<string, any> = {
  autoRefreshToken: true,
  persistSession: true,
  detectSessionInUrl: false,
};

// Only require AsyncStorage on the client/device to avoid "window is not defined" on web/SSR
if (typeof window !== 'undefined') {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const AsyncStorage = require('@react-native-async-storage/async-storage').default;
    authOptions.storage = AsyncStorage;
  } catch (err) {
    console.warn('AsyncStorage not available, continuing without it.', err);
  }
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    auth: authOptions
   
});