import React, { useState } from "react";
import { View, TextInput, Button, Text, StyleSheet } from "react-native";

export default function AnalyzeToneScreen() {
  const [message, setMessage] = useState("");
  const [tone, setTone] = useState("gentle");
  const [sensitivity, setSensitivity] = useState("high");
  const [result, setResult] = useState("");
  const [loading, setLoading] = useState(false);

  const analyze = async () => {
    setLoading(true);
    setResult("");
    try {
      const response = await fetch(
        "https://us-central1-unsaid-3bc7c.cloudfunctions.net/analyzeTone",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ message, tone, sensitivity }),
        }
      );
      const data = await response.json();
      setResult(data.result || data.error || "No response");
    } catch (err) {
      setResult("Error: " + err.message);
    }
    setLoading(false);
  };

  return (
    <View style={styles.container}>
      <Text>Message:</Text>
      <TextInput
        style={styles.input}
        value={message}
        onChangeText={setMessage}
        placeholder="Type your message"
      />
      <Text>Tone:</Text>
      <TextInput
        style={styles.input}
        value={tone}
        onChangeText={setTone}
        placeholder="gentle"
      />
      <Text>Sensitivity:</Text>
      <TextInput
        style={styles.input}
        value={sensitivity}
        onChangeText={setSensitivity}
        placeholder="high"
      />
      <Button title={loading ? "Analyzing..." : "Analyze Tone"} onPress={analyze} disabled={loading} />
      {result ? <Text style={styles.result}>{result}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20, flex: 1, backgroundColor: "#fff" },
  input: { borderWidth: 1, borderColor: "#ccc", marginBottom: 10, padding: 8, borderRadius: 4 },
  result: { marginTop: 20, fontWeight: "bold" },
});