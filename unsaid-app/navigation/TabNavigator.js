import React, { useEffect } from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import SplashScreen from '../screens/SplashScreen';
import OnboardingIntroScreen from '../screens/OnboardingScreen';
import OnboardingAccountScreen from '../screens/OnboardingAccountScreen';
import HomeTabNavigator from '../navigation/HomeTabNavigator';
import MessageLabScreen from '../screens/MessageLabScreen';
import PartnerProfileScreen from '../screens/PartnerProfileScreen';
import RelationshipProfileScreen from '../screens/RelationshipProfileScreen';
import RelationshipQuestionnaireScreen from '../screens/RelationshipQuestionnaireScreen';
import InviteCodeScreen from '../screens/InviteCodeScreen';
import ExplainProfileScreen from '../screens/ExplainThisProfileScreen';
import CodeGeneratedScreen from '../screens/CodeGenerateScreen';
import SendViaEmailScreen from '../screens/SendViaEmailScreen';
import ShareProfileScreen from '../screens/ShareProfileScreen';
import ToneFilterScreen from '../screens/ToneFilterScreen';
import PremiumScreen from '../screens/PremiumScreen';
import KeyboardIntroScreen from '../screens/KeyboardIntroScreen';
import AnalyzeToneScreen from '../screens/AnalyzeToneScreen';
import colors from './theme/colors';

const Stack = createStackNavigator();

const MyTheme = {
  colors: {
    background: colors.background,
    primary: colors.primary,
  }
};

const TabNavigator = () => {
  useEffect(() => {
    // Example: navigate after mount
    // navigation.navigate('ExplainProfile', { inviteCode: 'UNSD-XXXXX' });
  }, []);

  return (
    <Stack.Navigator initialRouteName="Splash" screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Splash" component={SplashScreen} />
      <Stack.Screen name="OnboardingIntro" component={OnboardingIntroScreen} />
      <Stack.Screen name="OnboardingAccount" component={OnboardingAccountScreen} />
      <Stack.Screen name="Home" component={HomeTabNavigator} />
      <Stack.Screen name="MessageLab" component={MessageLabScreen} />
      <Stack.Screen name="PartnerProfile" component={PartnerProfileScreen} />
      <Stack.Screen name="RelationshipProfile" component={RelationshipProfileScreen} />
      <Stack.Screen name="RelationshipQuestionnaire" component={RelationshipQuestionnaireScreen} />
      <Stack.Screen name="InviteCode" component={InviteCodeScreen} />
      <Stack.Screen name="ExplainProfile" component={ExplainProfileScreen} />
      <Stack.Screen name="CodeGenerated" component={CodeGeneratedScreen} />
      <Stack.Screen name="SendViaEmail" component={SendViaEmailScreen} />
      <Stack.Screen name="ShareProfile" component={ShareProfileScreen} />
      <Stack.Screen name="ToneFilter" component={ToneFilterScreen} />
      <Stack.Screen name="Premium" component={PremiumScreen} />
      <Stack.Screen name="KeyboardIntro" component={KeyboardIntroScreen} />
      <Stack.Screen name="AnalyzeTone" component={AnalyzeToneScreen} />
    </Stack.Navigator>
  );
};

export default TabNavigator;
