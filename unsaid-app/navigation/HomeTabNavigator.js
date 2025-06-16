import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import HomeScreen from '../screens/HomeScreen';
import PartnerProfileScreen from '../screens/PartnerProfileScreen';
import CommonQuestionsScreen from '../screens/CommonQuestionsScreen';
import SettingsScreen from '../screens/SettingsScreen';
import PremiumScreen from '../screens/PremiumScreen';
import GentleIcon from '../assets/gentle.svg';
import BalanceIcon from '../assets/balance.svg';
import DirectIcon from '../assets/direct.svg';
import colors from '../theme/colors';

const Tab = createBottomTabNavigator();

export default function MainTabs() {
  return (
    <Tab.Navigator
      initialRouteName="Home"
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textDark,
        tabBarStyle: { backgroundColor: colors.backgroundLight },
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          tabBarLabel: 'Home',
          tabBarIcon: ({ color, size }) => <GentleIcon width={size} height={size} fill={color} />,
        }}
      />
      <Tab.Screen
        name="PartnerProfile"
        component={PartnerProfileScreen}
        options={{
          tabBarLabel: 'Partner',
          tabBarIcon: ({ color, size }) => <BalanceIcon width={size} height={size} fill={color} />,
        }}
      />
      <Tab.Screen
        name="FAQ"
        component={CommonQuestionsScreen}
        options={{
          tabBarLabel: 'FAQ',
          tabBarIcon: ({ color, size }) => <DirectIcon width={size} height={size} fill={color} />,
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          tabBarLabel: 'Settings',
          tabBarIcon: ({ color, size }) => (
            <DirectIcon width={size} height={size} fill={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Premium"
        component={PremiumScreen}
        options={{
          tabBarLabel: 'Premium',
          tabBarIcon: ({ color, size }) => (
            <BalanceIcon width={size} height={size} fill={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
}