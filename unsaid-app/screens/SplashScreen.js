import React, { useEffect, useRef } from 'react';
import { View, Image, StyleSheet, Animated } from 'react-native';
import colors from '../theme/colors';

export default function SplashScreen() {
  const scaleAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(scaleAnim, {
          toValue: 1.1,
          duration: 1000,
          useNativeDriver: true,
        }),
        Animated.timing(scaleAnim, {
          toValue: 1,
          duration: 1000,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, []);

  return (
    <View style={styles.container}>
      <Animated.Image
        source={require('../assets/unsaid-logo.png')} // Replace with your image path
        style={[styles.logo, { transform: [{ scale: scaleAnim }] }]}
        resizeMode="contain"
      />
      <Image source={require('../assets/logo-icon.PNG')} style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  logo: {
    width: 180,
    height: 180,
  },
  title: { color: colors.text },
});
