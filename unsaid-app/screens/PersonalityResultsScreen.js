import React from 'react';
import { View, Text, StyleSheet, Dimensions, Image } from 'react-native';
import { PieChart } from 'react-native-chart-kit';
import colors from '../theme/colors';

const typeLabels = {
  A: "Anxious Connector",
  B: "Secure Communicator",
  C: "Avoidant Thinker",
  D: "Disorganized (Mixed Signals)",
};

const typeColors = {
  A: "#7B61FF",
  B: "#4CAF50",
  C: "#2196F3",
  D: "#FF9800",
};

export default function PersonalityResultsScreen({ route }) {
  const { answers } = route.params;

  // Count each type
  const counts = { A: 0, B: 0, C: 0, D: 0 };
  answers.forEach(type => { counts[type]++; });

  const data = Object.keys(counts).map(type => ({
    name: typeLabels[type],
    population: counts[type],
    color: typeColors[type],
    legendFontColor: "#333",
    legendFontSize: 14,
  }));

  // Find the dominant type
  const dominantType = Object.keys(counts).reduce((a, b) => counts[a] > counts[b] ? a : b);

  return (
    <View style={styles.container} accessible accessibilityLabel="Personality results screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Your Relationship Communicator Type
      </Text>
      <View
        accessible
        accessibilityLabel="Pie chart showing your relationship communicator type breakdown"
      >
        <PieChart
          data={data}
          width={Dimensions.get('window').width - 40}
          height={220}
          chartConfig={{
            color: () => "#fff",
          }}
          accessor="population"
          backgroundColor="transparent"
          paddingLeft="10"
          absolute
        />
      </View>
      <Text
        style={styles.result}
        accessible
        accessibilityLabel={`You are mostly: ${typeLabels[dominantType]}`}
      >
        You are mostly: <Text style={{ fontWeight: 'bold', color: typeColors[dominantType] }}>{typeLabels[dominantType]}</Text>
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background, flex: 1, justifyContent: 'center', alignItems: 'center' },
  title: { color: colors.text, fontSize: 22, fontWeight: 'bold', marginBottom: 20, textAlign: 'center' },
  result: { fontSize: 18, marginTop: 30, textAlign: 'center', color: colors.text },
});