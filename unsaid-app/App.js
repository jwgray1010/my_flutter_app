import React from 'react';
import { NavigationContainer, DefaultTheme, useNavigationContainerRef } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import SplashScreen from './screens/SplashScreen';
import OnboardingAccountScreen from './screens/OnboardingAccountScreen';
import OnboardingIntroScreen from './screens/OnboardingScreen';
import PersonalityTestDisclaimerScreen from './screens/PersonalityTestDisclaimerScreen';
import PersonalityTestScreen from './screens/PersonalityTestScreen';
import PersonalityResultsScreen from './screens/PersonalityResultsScreen';
import PremiumScreen from './screens/PremiumScreen';
import KeyboardIntroScreen from './screens/KeyboardIntroScreen';
import HomeTabNavigator from './navigation/HomeTabNavigator';
import RelationshipQuestionnaireScreen from './screens/RelationshipQuestionnaireScreen';
import RelationshipProfileScreen from './screens/RelationshipProfileScreen';
import { MessageSettingsProvider } from './context/MessageSettingsContext';
import PartnerDisclaimerScreen from './screens/PartnerDisclaimerScreen';
import colors from './theme/colors';
import MainTabs from './navigation/MainTabs';
import Providers from './Providers';
import { StatusBar } from 'react-native';
import analytics from '@react-native-firebase/analytics';
import AnalyzeToneScreen from './screens/AnalyzeToneScreen';

const Stack = createStackNavigator();

const MyTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: colors.background,
    primary: colors.primary,
    card: colors.accent,
    text: colors.text,
    border: colors.accent,
    notification: colors.highlight,
  },
};

const linking = {
  prefixes: ['unsaid://', 'https://unsaid.app'],
  config: {
    screens: {
      MainTabs: 'home',
      // ...other screens
    },
  },
};

export default function App() {
  const navigationRef = useNavigationContainerRef();

  React.useEffect(() => {
    const unsubscribe = navigationRef.addListener('state', async () => {
      const route = navigationRef.getCurrentRoute();
      if (route) {
        await analytics().logScreenView({
          screen_name: route.name,
          screen_class: route.name,
        });
      }
    });
    return unsubscribe;
  }, [navigationRef]);

  return (
    <Providers>
      <NavigationContainer ref={navigationRef} theme={MyTheme} linking={linking}>
        <StatusBar barStyle="light-content" backgroundColor={colors.background} />
        <Stack.Navigator initialRouteName="Splash" screenOptions={{ headerShown: false }}>
          <Stack.Screen name="Splash" component={SplashScreen} />
          <Stack.Screen name="OnboardingAccount" component={OnboardingAccountScreen} />
          <Stack.Screen name="OnboardingIntro" component={OnboardingIntroScreen} />
          <Stack.Screen name="PersonalityTestDisclaimer" component={PersonalityTestDisclaimerScreen} />
          <Stack.Screen name="PersonalityTest" component={PersonalityTestScreen} />
          <Stack.Screen name="PersonalityResults" component={PersonalityResultsScreen} />
          <Stack.Screen name="Premium" component={PremiumScreen} />
          <Stack.Screen name="KeyboardIntro" component={KeyboardIntroScreen} />
          <Stack.Screen name="Home" component={HomeTabNavigator} />
          <Stack.Screen name="MainTabs" component={MainTabs} options={{ headerShown: false }} />
          <Stack.Screen name="PartnerDisclaimer" component={PartnerDisclaimerScreen} />
          <Stack.Screen name="RelationshipQuestionnaire" component={RelationshipQuestionnaireScreen} />
          <Stack.Screen name="RelationshipProfile" component={RelationshipProfileScreen} />
          <Stack.Screen name="AnalyzeTone" component={AnalyzeToneScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </Providers>
  );
}