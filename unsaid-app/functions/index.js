import functions from "firebase-functions";
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

export const analyzeTone = functions.https.onRequest(async (req, res) => {
  const { message, sensitivity, tone } = req.body;

  const prompt = `
The user wrote: "${message}"

Tone filter: ${tone}
Sensitivity: ${sensitivity}

Based on this message and the above settings:
1. What is the emotional tone? (One word)
2. Suggest a gentler or more emotionally secure rewrite, using the selected tone and sensitivity.
3. Offer a short communication tip (based on relationship dynamics).

Return all three clearly labeled.
`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
    });

    const output = completion.choices[0].message.content;
    res.status(200).send({ result: output });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

